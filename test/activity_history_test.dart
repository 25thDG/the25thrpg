import 'package:flutter_test/flutter_test.dart';
import 'package:the25thrpg/features/player/domain/entities/activity_history.dart';
import 'package:the25thrpg/features/player/domain/entities/weekly_review.dart';

/// Builds a contiguous run of days ending today, oldest first.
/// [minutes] and [clean] are indexed the same way — oldest first.
HistorySeries series(
  HistoryTrack track, {
  List<int>? minutes,
  List<bool?>? clean,
  DateTime? endingOn,
  int backfillMinutes = 0,
  int backfillEntries = 0,
  String? category,
}) {
  final length = minutes?.length ?? clean?.length ?? 0;
  final today = endingOn ?? DateTime.now();
  final midnight = DateTime(today.year, today.month, today.day);

  return HistorySeries(
    track: track,
    backfillMinutes: backfillMinutes,
    backfillEntries: backfillEntries,
    days: List.generate(length, (i) {
      final m = minutes?[i] ?? 0;
      return DayCell(
        day: midnight.subtract(Duration(days: length - 1 - i)),
        minutes: m,
        sessions: m > 0 ? 1 : 0,
        categories: (category != null && m > 0) ? {category: m} : const {},
        clean: clean?[i],
      );
    }),
  );
}

ActivityHistory historyOf(Map<HistoryTrack, HistorySeries> map) {
  final today = DateTime.now();
  final midnight = DateTime(today.year, today.month, today.day);
  final any = map.values.first;
  return ActivityHistory(
    series: {
      for (final t in HistoryTrack.values)
        t: map[t] ?? HistorySeries(track: t, days: const []),
    },
    from: midnight.subtract(Duration(days: any.days.length - 1)),
    to: midnight,
  );
}

void main() {
  group('history series', () {
    test('counts only days with something on them', () {
      final s = series(HistoryTrack.japanese, minutes: [0, 20, 0, 5, 0]);
      expect(s.winDays, 2);
      expect(s.totalMinutes, 25);
    });

    test('backfill is reported alongside, never inside, the day figures', () {
      // A pre-app block is real practice with an arbitrary date, so it is kept
      // out of the per-day view and surfaced separately.
      final s = series(
        HistoryTrack.japanese,
        minutes: [10, 0, 20],
        backfillMinutes: 5200,
        backfillEntries: 2,
      );
      expect(s.bestDayMinutes, 20);
      expect(s.totalMinutes, 30);
      expect(s.winDays, 2);
      expect(s.backfillMinutes, 5200);
      expect(s.backfillEntries, 2);
    });

    test('longest streak finds the best run anywhere in the range', () {
      final s = series(HistoryTrack.japanese, minutes: [5, 5, 0, 9, 9, 9, 0]);
      expect(s.longestStreak, 3);
    });

    test('current streak runs back from today', () {
      final s = series(HistoryTrack.japanese, minutes: [0, 5, 5, 5]);
      expect(s.currentStreak, 3);
    });

    test('an unlogged today pauses the streak rather than breaking it', () {
      // Yesterday and before were worked; today is simply not logged yet.
      final s = series(HistoryTrack.japanese, minutes: [5, 5, 5, 0]);
      expect(s.currentStreak, 3);
    });

    test('a relapse today breaks the streak immediately', () {
      final s = series(
        HistoryTrack.sobriety,
        clean: [true, true, true, false],
      );
      expect(s.currentStreak, 0);
    });

    test('sobriety separates never-logged from slipped', () {
      final s = series(
        HistoryTrack.sobriety,
        clean: [true, null, false, true],
      );
      expect(s.loggedDays, 3);
      expect(s.winDays, 2);
    });

    test('last and previous windows do not overlap', () {
      final s = series(
        HistoryTrack.japanese,
        minutes: [1, 1, 1, 1, 1, 1, 1, 9, 9, 9, 9, 9, 9, 9],
      );
      expect(s.minutesInLast(7), 63);
      expect(s.minutesInPrevious(7), 7);
    });

    test('windows clamp when the range is shorter than asked for', () {
      final s = series(HistoryTrack.japanese, minutes: [4, 4]);
      expect(s.minutesInLast(7), 8);
      expect(s.minutesInPrevious(7), 0);
    });
  });

  group('analysis', () {
    test('consistency is over every day, not just the worked ones', () {
      final s = series(HistoryTrack.japanese, minutes: [10, 0, 0, 30]);
      expect(s.consistency, 0.5);
      expect(s.avgPerDay, 10);
      expect(s.avgPerActiveDay, 20);
    });

    test('the longest gap ignores blanks before the first entry', () {
      // Three leading blanks are "not started yet", not a lapse.
      final s = series(HistoryTrack.japanese, minutes: [0, 0, 0, 5, 0, 0, 5]);
      expect(s.longestGap, 2);
    });

    test('a trailing blank today does not count as a gap yet', () {
      final s = series(HistoryTrack.japanese, minutes: [5, 5, 0]);
      expect(s.longestGap, 1);
      expect(s.currentStreak, 2);
    });

    test('best week finds the heaviest seven consecutive days', () {
      final s = series(
        HistoryTrack.japanese,
        minutes: [1, 1, 1, 1, 1, 1, 1, 50, 50, 0, 0, 0, 0, 0],
      );
      expect(s.bestWeek?.minutes, 105);
    });

    test('sessions are counted separately from minutes', () {
      final s = series(HistoryTrack.japanese, minutes: [10, 0, 30, 20]);
      expect(s.sessionCount, 3);
      expect(s.avgSessionMinutes, 20);
    });

    test('months bucket by calendar month', () {
      final s = series(
        HistoryTrack.japanese,
        minutes: List.filled(40, 10),
        endingOn: DateTime(2026, 3, 10),
      );
      final months = s.byMonth();
      expect(months.length, 3); // 30 Jan → 10 Mar touches Jan, Feb and Mar
      expect(months.first.month.month, 1);
      expect(months.last.month.month, 3);
      expect(months.fold(0, (a, m) => a + m.minutes), 400);
    });

    test('weekday buckets cover all seven days and total the range', () {
      final s = series(HistoryTrack.japanese, minutes: List.filled(21, 5));
      final week = s.byWeekday();
      expect(week.length, 7);
      expect(week.every((b) => b.totalDays == 3), isTrue);
      expect(week.every((b) => b.rate == 1.0), isTrue);
    });

    test('the weekday you never work is the weakest', () {
      // Ends on a Sunday, so index 6 of every seven-day block is Sunday.
      final minutes = List.generate(28, (i) => (i % 7 == 6) ? 0 : 20);
      final s = series(
        HistoryTrack.japanese,
        minutes: minutes,
        endingOn: DateTime(2026, 8, 9), // a Sunday
      );
      expect(s.weekdayExtremes?.worst.name, 'SUN');
      expect(s.weekdayExtremes?.worst.rate, 0);
    });

    test('a range narrows the days but keeps the lifetime backfill', () {
      final s = series(
        HistoryTrack.japanese,
        minutes: List.filled(200, 10),
        backfillMinutes: 5200,
        backfillEntries: 2,
      );
      final narrowed = s.lastRange(30);
      expect(narrowed.days.length, 30);
      expect(narrowed.totalMinutes, 300);
      expect(narrowed.backfillMinutes, 5200);
    });

    test('the category split sums to the total for the range shown', () {
      final s = series(
        HistoryTrack.japanese,
        minutes: List.filled(40, 10),
        category: 'vocab',
        backfillMinutes: 5200,
      );
      expect(s.categoryMinutes['vocab'], 400);
      expect(s.categoryMinutes.values.fold(0, (a, b) => a + b), s.totalMinutes);

      // Narrowing the range narrows the split with it.
      final narrowed = s.lastRange(10);
      expect(narrowed.categoryMinutes['vocab'], 100);
      expect(narrowed.categoryMinutes.values.fold(0, (a, b) => a + b),
          narrowed.totalMinutes);
    });

    test('a null range means everything', () {
      final s = series(HistoryTrack.japanese, minutes: List.filled(50, 1));
      expect(s.lastRange(null).days.length, 50);
    });

    test('trimming drops the blank run before the first entry', () {
      final s = series(HistoryTrack.japanese, minutes: [0, 0, 0, 7, 0, 9]);
      expect(s.trimmedToFirstEntry().days.length, 3);
      expect(s.trimmedToFirstEntry().totalMinutes, 16);
    });
  });

  group('weekly review', () {
    WeeklyReview build({
      required List<int> japanese,
      List<int>? mindfulness,
      List<bool?>? sobriety,
      int streak = 0,
    }) {
      return WeeklyReview.from(
        history: historyOf({
          HistoryTrack.japanese: series(HistoryTrack.japanese, minutes: japanese),
          HistoryTrack.mindfulness: series(
            HistoryTrack.mindfulness,
            minutes: mindfulness ?? List.filled(japanese.length, 0),
          ),
          HistoryTrack.sobriety: series(
            HistoryTrack.sobriety,
            clean: sobriety ?? List.filled(japanese.length, null),
          ),
        }),
        streakDays: streak,
      );
    }

    test('a better week than the last reads as a gain', () {
      final r = build(japanese: [
        ...List.filled(7, 5), // previous week: 35
        ...List.filled(7, 20), // this week: 140
      ]);
      final jp = r.byTrack(HistoryTrack.japanese);
      expect(jp.thisWeek, 140);
      expect(jp.lastWeek, 35);
      expect(jp.verdict, TrendVerdict.up);
      expect(r.bestMove?.track, HistoryTrack.japanese);
    });

    test('a quieter week reads as a drop and becomes the focus', () {
      final r = build(japanese: [
        ...List.filled(7, 30),
        ...List.filled(7, 2),
      ]);
      final jp = r.byTrack(HistoryTrack.japanese);
      expect(jp.verdict, TrendVerdict.down);
      expect(r.focus?.track, HistoryTrack.japanese);
    });

    test('a small wobble is flat, not a trend', () {
      final r = build(japanese: [
        ...List.filled(7, 10), // 70
        ...List.filled(7, 10), // 70
      ]);
      expect(r.byTrack(HistoryTrack.japanese).verdict, TrendVerdict.flat);
    });

    test('a track never touched is idle, not a drop', () {
      final r = build(japanese: List.filled(14, 0));
      expect(r.byTrack(HistoryTrack.japanese).verdict, TrendVerdict.idle);
      expect(r.byTrack(HistoryTrack.japanese).hasStalled, isFalse);
    });

    test('going quiet after a worked week counts as stalled', () {
      final r = build(japanese: [
        ...List.filled(7, 30),
        ...List.filled(7, 0),
      ]);
      expect(r.byTrack(HistoryTrack.japanese).hasStalled, isTrue);
      expect(r.stalled.length, 1);
      expect(r.focus?.track, HistoryTrack.japanese);
    });

    test('sobriety is counted in days, not minutes', () {
      final r = build(
        japanese: List.filled(14, 0),
        sobriety: [
          ...List.filled(7, true),
          true, true, false, true, true, true, true,
        ],
      );
      final sob = r.byTrack(HistoryTrack.sobriety);
      expect(sob.isVerdictTrack, isTrue);
      expect(sob.thisWeek, 6);
      expect(sob.lastWeek, 7);
    });

    test('a day worked on two tracks still counts once', () {
      final r = build(
        japanese: List.filled(14, 0)..[13] = 20,
        mindfulness: List.filled(14, 0)..[13] = 5,
      );
      expect(r.daysWorked, 1);
    });

    test('a blank week is reported as blank', () {
      final r = build(japanese: List.filled(14, 0));
      expect(r.isBlank, isTrue);
      expect(r.daysWorked, 0);
    });
  });
}
