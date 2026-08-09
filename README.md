# the25thrpg

A personal life-tracking RPG. Real habits feed a character sheet: four skills
(Japanese, Wealth, Mindfulness, Resolve) level up from logged practice, money,
sobriety and completed quests.

Flutter + Supabase. Single user — the owner is the only person who installs or
uses it.

## Deliberate decisions

These look like bugs from the outside. They are not. Please do not "fix" them,
and do not raise them again in a review.

### 1. No auth, and RLS is off on purpose

There is no login. The `user_id` is a constant in each datasource. Row Level
Security is disabled on the public tables.

This is intentional: the app is installed on one person's phone and holds one
person's data. Adding Supabase Auth would buy nothing and cost a login screen.

Supabase's advisors will keep reporting `rls_disabled_in_public` at ERROR level
and the MCP tools will keep flagging it as critical. That report is expected and
accepted. Do not enable RLS, and do not propose an auth flow, unless the owner
asks for one.

### 2. Very large entries are backfill, and they are real

Some rows are enormous — 4,000 minutes on 2026-03-24 and 1,200 minutes on
2026-03-07 in `japanese_sessions`.

These are **not typos**. They are blocks of practice done before the app
existed, entered after the fact on whatever day they happened to be typed in.
The hours are real; the *date* on them is not meaningful.

So they are treated two ways, and both matter:

- **They count toward lifetime totals and levels.** That practice happened, and
  the level is right to reflect it. Never delete or "correct" these rows.
- **They are excluded from anything measured per day** — the calendar, best day,
  active days, streaks, daily averages, the weekly review. Left in, one row
  would claim a 67-hour day and flatten every real day next to it.

The split is `kBackfillThresholdMinutes` in
`lib/features/player/domain/entities/activity_history.dart`: a single row over
8 hours is backfill. The largest genuine session in the data is 6 hours, so the
line is comfortable.

Also: do not add an upper bound to the minutes input — it would block this
workflow entirely.

## Structure

Clean architecture per feature, under `lib/features/<name>/`:

```
application/   use cases
data/          datasources, models, repository implementations
domain/        entities, repository interfaces
presentation/  pages, widgets, controllers, state
```

Shipping features: `player`, `japanese`, `mindfulness`, `wealth`, `budget`,
`quests`. They map one-to-one to the tabs in `lib/main.dart`.

The level maths lives in `lib/features/player/domain/entities/skill_summary.dart`
— every skill is square-root scaled toward a level-100 target, with mastery
points beyond it.

### Removed features

`sport`, `social` and `creation` were built and then abandoned; the code was
deleted and the `creation_*` tables dropped. Their historical rows are still in
`skill_sessions` (Sport, Social, Creation entries, last used April 2026). Nothing
reads them — every query filters by `skill_id` — so they are inert history.

## Verifying a change

```bash
flutter analyze
flutter test
flutter build apk --debug          # catches Android-only build breaks
```

Static analysis does not catch layout defects. Run it on a simulator and look at
the screen:

```bash
flutter run -d <device-id>
xcrun simctl io <device-id> screenshot shot.png
```

Several real bugs here — an inverted radar, a chart with zero width, colliding
labels — passed `analyze` and `test` cleanly and were only visible in a
screenshot.

## Notifications

Daily reminders use `flutter_local_notifications` (v22 — named parameters).
Android needs core library desugaring; iOS needs the
`UNUserNotificationCenter` delegate set in `AppDelegate.swift`. A hot restart
does not install native code — fully quit and relaunch after touching either.
