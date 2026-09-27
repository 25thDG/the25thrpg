/// The two-day rule.
///
/// Missing a habit once is human. Missing it twice in a row is the start of
/// stopping. Everything in this file exists to draw that line precisely, and to
/// draw it in one place so the UI, the copy and any future notification all
/// agree.
///
/// Two rules decide every edge case:
///
/// 1. **Today is not a miss yet.** A day is only judged once it is over, so an
///    untouched habit at nine in the morning is "still open", never a failure.
///    Misses are therefore counted backwards from *yesterday*.
/// 2. **Nothing before the habit existed is a miss.** Counting stops at the
///    habit's start date, so adding a habit today does not make it instantly
///    broken.
library;

/// How solid a habit is right now.
enum FoundationState {
  /// Done today. Nothing to worry about.
  solid,

  /// Not done today, but nothing was missed either — the day is still open.
  open,

  /// Yesterday was missed. One more and the foundation goes.
  cracked,

  /// Two or more days in a row missed. This is a habit coming apart.
  broken,
}

extension FoundationStateX on FoundationState {
  bool get isWarning => this == FoundationState.cracked;
  bool get isBroken => this == FoundationState.broken;
  bool get isDone => this == FoundationState.solid;

  /// Ordering by severity, so a routine can report its worst habit.
  int get severity => switch (this) {
        FoundationState.solid => 0,
        FoundationState.open => 1,
        FoundationState.cracked => 2,
        FoundationState.broken => 3,
      };

  String get label => switch (this) {
        FoundationState.solid => 'DONE',
        FoundationState.open => 'TODAY',
        FoundationState.cracked => 'AT RISK',
        FoundationState.broken => 'BROKEN',
      };
}

/// The full verdict on one habit at one moment.
class FoundationStatus {
  final FoundationState state;

  /// Consecutive days missed immediately before today. Today is never counted.
  final int missedInARow;

  /// Consecutive completed days ending today, or ending yesterday while today
  /// is still open.
  final int streak;

  /// The best run this habit has ever had.
  final int longestStreak;

  /// Days completed since the habit started.
  final int completedDays;

  /// Days that have been judged: the habit's start through yesterday. Today is
  /// only included once it has been ticked.
  final int settledDays;

  const FoundationStatus({
    required this.state,
    required this.missedInARow,
    required this.streak,
    required this.longestStreak,
    required this.completedDays,
    required this.settledDays,
  });

  /// Share of judged days that were kept, 0–1. Null on a habit that has not had
  /// a single settled day yet.
  double? get keepRate =>
      settledDays == 0 ? null : completedDays / settledDays;

  /// How many more missed days before this breaks. 0 once it already has.
  int get gracedaysLeft => switch (state) {
        FoundationState.broken => 0,
        FoundationState.cracked => 1,
        _ => 2,
      };

  /// True when doing it today is the difference between keeping and losing it.
  bool get isLastChance => state == FoundationState.cracked;
}

/// The hour a routine day rolls over to the next one.
///
/// Not midnight. A habit ticked at two in the morning belongs to the day that
/// is ending, not the one that has technically started — going to bed late must
/// not cost a streak, and a night routine done at 01:30 is that night's.
const kDayRollHour = 4;

/// Strips a timestamp down to a local calendar day.
DateTime dayOf(DateTime t) => DateTime(t.year, t.month, t.day);

/// The routine day [t] falls in. Anything before [kDayRollHour] still belongs
/// to the previous day.
DateTime routineDayOf(DateTime t) =>
    dayOf(t.subtract(const Duration(hours: kDayRollHour)));

/// The routine day right now. Use this, never `dayOf(DateTime.now())` — the
/// two differ for four hours out of every twenty-four.
DateTime routineToday() => routineDayOf(DateTime.now());

/// When the routine day after [day] begins, as a local wall-clock time.
///
/// Built with the DateTime constructor rather than by adding a Duration, so
/// month ends and daylight saving are handled by the calendar rather than by
/// arithmetic on elapsed hours.
DateTime nextRolloverAfter(DateTime day) =>
    DateTime(day.year, day.month, day.day + 1, kDayRollHour);

/// Applies the two-day rule.
///
/// [completions] holds one entry per day the habit was kept, each already
/// normalised to a local midnight. [startsOn] is the first day that counts.
FoundationStatus evaluateFoundation({
  required Set<DateTime> completions,
  required DateTime startsOn,
  required DateTime today,
}) {
  final t = dayOf(today);
  final start = dayOf(startsOn);
  final doneToday = completions.contains(t);

  // ── Misses run backwards from yesterday, never from today ────────────────
  int missed = 0;
  var cursor = t.subtract(const Duration(days: 1));
  while (!cursor.isBefore(start) && !completions.contains(cursor)) {
    missed++;
    cursor = cursor.subtract(const Duration(days: 1));
  }

  // ── Streak ends today if today is done, otherwise yesterday ──────────────
  int streak = 0;
  var run = doneToday ? t : t.subtract(const Duration(days: 1));
  while (!run.isBefore(start) && completions.contains(run)) {
    streak++;
    run = run.subtract(const Duration(days: 1));
  }

  // ── Longest run, and totals, over the habit's whole life ─────────────────
  int longest = 0;
  int current = 0;
  int completed = 0;
  for (var d = start; !d.isAfter(t); d = d.add(const Duration(days: 1))) {
    if (completions.contains(d)) {
      completed++;
      current++;
      if (current > longest) longest = current;
    } else {
      current = 0;
    }
  }

  // Yesterday is the last judged day; today joins it only once it is ticked.
  // Clamped because a habit can start after the current routine day — a clock
  // change, or a row written under the old midnight rule — and a negative
  // count would turn the keep rate into nonsense.
  final elapsed = t.difference(start).inDays;
  final settled = (doneToday ? elapsed + 1 : elapsed).clamp(0, 1 << 31);

  final state = doneToday
      ? FoundationState.solid
      : switch (missed) {
          0 => FoundationState.open,
          1 => FoundationState.cracked,
          _ => FoundationState.broken,
        };

  return FoundationStatus(
    state: state,
    missedInARow: missed,
    streak: streak,
    longestStreak: longest,
    completedDays: completed,
    settledDays: settled,
  );
}
