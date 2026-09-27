import 'package:flutter_test/flutter_test.dart';
import 'package:the25thrpg/features/routines/domain/entities/foundation.dart';
import 'package:the25thrpg/features/routines/domain/entities/habit.dart';
import 'package:the25thrpg/features/routines/domain/entities/routine.dart';

final today = DateTime(2026, 8, 9);

DateTime ago(int days) => today.subtract(Duration(days: days));

/// [pattern] is indexed by days ago: index 0 is today, 1 is yesterday, and so
/// on. true means the habit was kept that day.
Set<DateTime> keptOn(List<bool> pattern) => {
      for (final (i, done) in pattern.indexed)
        if (done) ago(i),
    };

FoundationStatus evaluate(List<bool> pattern, {int? startedDaysAgo}) {
  return evaluateFoundation(
    completions: keptOn(pattern),
    startsOn: ago(startedDaysAgo ?? pattern.length - 1),
    today: today,
  );
}

Habit habit({
  required List<bool> pattern,
  String name = 'Meditate',
  int? startedDaysAgo,
}) {
  return Habit(
    id: name,
    routineId: 'r1',
    name: name,
    startsOn: ago(startedDaysAgo ?? pattern.length - 1),
    completions: keptOn(pattern),
  );
}

void main() {
  group('4am rollover', () {
    test('just before 04:00 still belongs to the day that is ending', () {
      // 03:59 on the 10th is still the 9th's routine day.
      expect(routineDayOf(DateTime(2026, 8, 10, 3, 59)), DateTime(2026, 8, 9));
    });

    test('04:00 exactly starts the new day', () {
      expect(routineDayOf(DateTime(2026, 8, 10, 4)), DateTime(2026, 8, 10));
    });

    test('a late-night tick counts for the night that is ending', () {
      // 01:30 after a long evening — the night routine is still last night's.
      expect(routineDayOf(DateTime(2026, 8, 10, 1, 30)), DateTime(2026, 8, 9));
    });

    test('midnight itself belongs to the previous day', () {
      expect(routineDayOf(DateTime(2026, 8, 10)), DateTime(2026, 8, 9));
    });

    test('the rest of the day is unaffected', () {
      expect(routineDayOf(DateTime(2026, 8, 10, 9)), DateTime(2026, 8, 10));
      expect(routineDayOf(DateTime(2026, 8, 10, 23, 59)), DateTime(2026, 8, 10));
    });

    test('the next rollover is 04:00 on the following calendar day', () {
      expect(
        nextRolloverAfter(DateTime(2026, 8, 9)),
        DateTime(2026, 8, 10, 4),
      );
    });

    test('rollover crosses a month end without arithmetic on hours', () {
      expect(
        nextRolloverAfter(DateTime(2026, 8, 31)),
        DateTime(2026, 9, 1, 4),
      );
    });

    test('a habit ticked at 01:00 keeps the streak it would have broken', () {
      // Kept the 8th and the 9th; it is now 01:00 on the 10th and the habit is
      // ticked. Under a midnight rollover that tick would land on the 10th and
      // the 9th would read as missed. It must land on the 9th instead.
      final now = DateTime(2026, 8, 10, 1);
      final day = routineDayOf(now);
      expect(day, DateTime(2026, 8, 9));

      final s = evaluateFoundation(
        completions: {DateTime(2026, 8, 8), day},
        startsOn: DateTime(2026, 8, 1),
        today: day,
      );
      expect(s.state, FoundationState.solid);
      expect(s.streak, 2);
    });
  });

  group('two-day rule', () {
    test('done today is solid whatever came before', () {
      final s = evaluate([true, false, false, false]);
      expect(s.state, FoundationState.solid);
    });

    test('an untouched today is open, not a miss', () {
      // Kept yesterday, nothing yet today. Nine in the morning is not failure.
      final s = evaluate([false, true, true]);
      expect(s.state, FoundationState.open);
      expect(s.missedInARow, 0);
    });

    test('one missed day cracks it', () {
      final s = evaluate([false, false, true, true]);
      expect(s.state, FoundationState.cracked);
      expect(s.missedInARow, 1);
      expect(s.isLastChance, isTrue);
      expect(s.gracedaysLeft, 1);
    });

    test('two missed days in a row breaks it', () {
      final s = evaluate([false, false, false, true]);
      expect(s.state, FoundationState.broken);
      expect(s.missedInARow, 2);
      expect(s.gracedaysLeft, 0);
    });

    test('a long lapse stays broken and counts every day', () {
      final s = evaluate([false, false, false, false, false, false, true]);
      expect(s.state, FoundationState.broken);
      expect(s.missedInARow, 5);
    });

    test('doing it today rescues a cracked habit', () {
      final cracked = evaluate([false, false, true]);
      expect(cracked.state, FoundationState.cracked);

      final rescued = evaluate([true, false, true]);
      expect(rescued.state, FoundationState.solid);
    });

    test('every other day never breaks, which is the point of the rule', () {
      // Alternating misses are always a single day, so this holds at cracked
      // and never falls through to broken.
      final s = evaluate([false, true, false, true, false, true, false, true]);
      expect(s.state, FoundationState.open);
      expect(s.missedInARow, 0);
    });
  });

  group('habit start date', () {
    test('a habit added today is open, not broken', () {
      final s = evaluate([false], startedDaysAgo: 0);
      expect(s.state, FoundationState.open);
      expect(s.missedInARow, 0);
    });

    test('misses stop at the start date instead of running to infinity', () {
      // Started three days ago, never done. Only those days count.
      final s = evaluate([false, false, false, false], startedDaysAgo: 3);
      expect(s.missedInARow, 3);
    });

    test('days before the habit existed are not misses', () {
      final s = evaluate([false, false, true], startedDaysAgo: 2);
      expect(s.missedInARow, 1);
      expect(s.state, FoundationState.cracked);
    });
  });

  group('streak', () {
    test('counts back from today when today is done', () {
      final s = evaluate([true, true, true, false]);
      expect(s.streak, 3);
    });

    test('an open today keeps yesterdays streak alive', () {
      final s = evaluate([false, true, true, true]);
      expect(s.streak, 3);
    });

    test('a cracked habit has no streak left', () {
      final s = evaluate([false, false, true, true]);
      expect(s.streak, 0);
    });

    test('longest streak survives a later collapse', () {
      final s = evaluate([false, false, false, true, true, true, true, true]);
      expect(s.longestStreak, 5);
      expect(s.streak, 0);
    });
  });

  group('keep rate', () {
    test('is measured over settled days, so an open today does not dent it', () {
      // Started 4 days ago, kept all four settled days, today still open.
      final s = evaluate([false, true, true, true, true]);
      expect(s.settledDays, 4);
      expect(s.completedDays, 4);
      expect(s.keepRate, 1.0);
    });

    test('today joins the settled days once it is ticked', () {
      final s = evaluate([true, true, true, true, true]);
      expect(s.settledDays, 5);
      expect(s.keepRate, 1.0);
    });

    test('a habit starting after today never reports negative settled days', () {
      // Possible from a row written under the old midnight rule, or a clock
      // change. It must read as brand new rather than as nonsense.
      final s = evaluateFoundation(
        completions: const {},
        startsOn: DateTime(2026, 8, 11),
        today: DateTime(2026, 8, 9),
      );
      expect(s.settledDays, 0);
      expect(s.keepRate, isNull);
      expect(s.state, FoundationState.open);
    });

    test('is null on a habit with no settled day yet', () {
      final s = evaluate([false], startedDaysAgo: 0);
      expect(s.keepRate, isNull);
    });

    test('halves when half the days were missed', () {
      final s = evaluate([false, true, false, true, false, true]);
      expect(s.settledDays, 5);
      expect(s.completedDays, 3);
      expect(s.keepRate, closeTo(0.6, 0.001));
    });
  });

  group('routine aggregate', () {
    Routine routineOf(List<Habit> habits) => Routine(
          id: 'r1',
          name: 'Morning',
          partOfDay: PartOfDay.morning,
          habits: habits,
        );

    test('takes the state of its worst habit, not the average', () {
      final r = routineOf([
        habit(pattern: [true, true, true], name: 'a'),
        habit(pattern: [true, true, true], name: 'b'),
        habit(pattern: [false, false, false], name: 'c'),
      ]);
      expect(r.stateOn(today), FoundationState.broken);
    });

    test('reports how much of today is done', () {
      final r = routineOf([
        habit(pattern: [true], name: 'a'),
        habit(pattern: [false], name: 'b'),
        habit(pattern: [true], name: 'c'),
      ]);
      expect(r.doneCount(today), 2);
      expect(r.progress(today), closeTo(2 / 3, 0.001));
      expect(r.isComplete(today), isFalse);
    });

    test('an empty routine is never complete', () {
      final r = routineOf([]);
      expect(r.isComplete(today), isFalse);
      expect(r.progress(today), 0);
    });

    test('separates what is at risk from what is already gone', () {
      final r = routineOf([
        habit(pattern: [false, false, true], name: 'cracked'),
        habit(pattern: [false, false, false, true], name: 'broken'),
        habit(pattern: [true, true], name: 'fine'),
      ]);
      expect(r.atRisk(today).map((h) => h.name), ['cracked']);
      expect(r.broken(today).map((h) => h.name), ['broken']);
    });
  });

  group('board', () {
    test('orders routines by part of day, then by their own order', () {
      const board = RoutineBoard(routines: [
        Routine(id: '3', name: 'Night', partOfDay: PartOfDay.night),
        Routine(id: '2', name: 'Second', partOfDay: PartOfDay.morning, sortOrder: 1),
        Routine(id: '1', name: 'First', partOfDay: PartOfDay.morning),
      ]);
      expect(board.ordered.map((r) => r.name), ['First', 'Second', 'Night']);
    });

    test('counts todays progress across every routine', () {
      final board = RoutineBoard(routines: [
        Routine(
          id: 'm',
          name: 'Morning',
          partOfDay: PartOfDay.morning,
          habits: [habit(pattern: [true], name: 'a')],
        ),
        Routine(
          id: 'n',
          name: 'Night',
          partOfDay: PartOfDay.night,
          habits: [
            habit(pattern: [false], name: 'b'),
            habit(pattern: [true], name: 'c'),
          ],
        ),
      ]);
      expect(board.totalHabits, 3);
      expect(board.doneToday(today), 2);
    });
  });

  group('toggling', () {
    test('ticking a day is idempotent', () {
      final h = habit(pattern: [false, true]);
      final once = h.withCompletion(today, true);
      final twice = once.withCompletion(today, true);
      expect(once.completions.length, twice.completions.length);
      expect(twice.isDoneOn(today), isTrue);
    });

    test('unticking removes only that day', () {
      final h = habit(pattern: [true, true]);
      final off = h.withCompletion(today, false);
      expect(off.isDoneOn(today), isFalse);
      expect(off.isDoneOn(ago(1)), isTrue);
    });

    test('the recent strip marks days before the start as not applicable', () {
      final h = habit(pattern: [true, true], startedDaysAgo: 1);
      final strip = h.recentDays(4, today);
      expect(strip, [null, null, true, true]);
    });
  });
}
