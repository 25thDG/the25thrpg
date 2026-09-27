# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

A single-user, personal life-tracking RPG (Flutter + Supabase). Real habits — Japanese study, meditation/sobriety, net worth, quests, daily routines — feed a character sheet whose skill levels are derived, never stored. Read `README.md` in full before non-trivial work: its "Deliberate decisions" section documents things that look like bugs but must not be changed.

## Commands

```bash
flutter pub get
flutter analyze
flutter test                                   # all tests
flutter test test/foundation_rule_test.dart    # one file
flutter test --plain-name "substring"          # one test by name
flutter build apk --debug                      # catches Android-only build breaks
flutter run -d <device-id>
xcrun simctl io <device-id> screenshot shot.png
dart run flutter_launcher_icons                # regenerate icons from assets/icon/app_icon.png
```

`analyze` and `test` passing is not enough for UI work — layout bugs (inverted radar, zero-width chart, colliding labels) have shipped past both. Run on a simulator and screenshot the screen.

Notification changes touch native code (Android desugaring, iOS `AppDelegate.swift` delegate): fully quit and relaunch; hot restart won't pick them up.

## Non-negotiables (from README)

- **No auth, RLS off, on purpose.** `user_id` is a hardcoded `_userId` constant in each datasource. Ignore Supabase's `rls_disabled_in_public` advisor warnings; don't propose auth.
- **Huge rows are real backfill.** Rows over `kBackfillThresholdMinutes` (8 h, in `lib/features/player/domain/entities/activity_history.dart`) count toward lifetime totals/levels but are excluded from every per-day metric (calendar, streaks, best day, averages, weekly review). Never delete them; never cap the minutes input.
- **Routines' day rolls at 04:00.** In `lib/features/routines/`, use `routineToday()` / `routineDayOf` from `domain/entities/foundation.dart` — never `dayOf(DateTime.now())`. Other features still use calendar dates.

## Architecture

Clean architecture per feature in `lib/features/<name>/`: `domain/` (entities, repository interfaces) → `data/` (Supabase datasources, models, repo impls) → `application/use_cases/` → `presentation/` (pages, widgets, `ChangeNotifier` controllers, immutable state classes).

- **No DI framework / no state-management package.** Each page's `State` constructs its own controller, wiring datasource → repository → use cases by hand in `initState`. Follow that pattern for new features.
- **Shell** (`lib/main.dart`): an `IndexedStack` of tab pages (Player, Daily/routines, JP, Mind, Wealth, Budget, Quests) with a custom bottom bar. The routines controller is the exception — it's created in the shell (`RoutinesPage.createController()`) so the Daily tab badge can update without the page open, and it's reloaded on app resume only when the 04:00 routine day has turned over.
- **Player is the aggregator.** `features/player/data/datasources/` queries other features' tables directly (`japanese_sessions`, `skill_sessions`, `quests`, `wealth_snapshots`, `budget_transactions`) rather than going through their repositories. Level maths (square-root scaling toward a level-100 target, mastery points beyond) is in `features/player/domain/entities/skill_summary.dart`.
- **Level-ups** are detected in `lib/core/progression/level_watcher.dart` by comparing derived levels against last-seen values in `SharedPreferences` (first run records a silent baseline).
- **Shared core:** `lib/core/theme` (dark theme, `RpgColors`), `lib/core/notifications` (`ReminderService`, `flutter_local_notifications` v22 named-parameter API), `lib/core/error`.
- `skill_sessions` still contains inert rows for removed skills (Sport, Social, Creation); queries always filter by `skill_id`.

## Database

Supabase project `ujwiflvjioyjneczeoyi`, reachable via the `supabase` MCP server in `.mcp.json` (`list_tables`, `execute_sql`, `apply_migration`). Schema changes are applied through the MCP; `db/migrations/` is empty, so the live database is the source of truth.

## Stale docs

`GAME_SYSTEM.md` describes the original six-skill design (with Creation, Sport, Social). The current app has three skills — Japanese, Wealth, Mindfulness (Resolve was removed; see README). Trust `skill_summary.dart` over that file.
