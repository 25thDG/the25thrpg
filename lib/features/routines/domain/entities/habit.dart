import 'foundation.dart';

/// One habit inside a routine, with the days it was kept.
///
/// [completions] is loaded for a bounded window (see the datasource), which is
/// plenty for the two-day rule and the strip on the tile. Lifetime figures are
/// therefore "within the loaded window" — deliberately, so opening the screen
/// never costs a full history read.
class Habit {
  final String id;
  final String routineId;
  final String name;

  /// The first day this habit counts. Nothing before it can be a miss.
  final DateTime startsOn;

  final int sortOrder;

  /// Local midnights on which the habit was completed.
  final Set<DateTime> completions;

  const Habit({
    required this.id,
    required this.routineId,
    required this.name,
    required this.startsOn,
    this.sortOrder = 0,
    this.completions = const {},
  });

  /// The two-day rule verdict, as of [today].
  FoundationStatus statusOn(DateTime today) => evaluateFoundation(
        completions: completions,
        startsOn: startsOn,
        today: today,
      );

  bool isDoneOn(DateTime day) => completions.contains(dayOf(day));

  /// The last [count] days, oldest first, as kept / not kept. Days before the
  /// habit started come back as null so the strip can show them as "not yet".
  List<bool?> recentDays(int count, DateTime today) {
    final t = dayOf(today);
    final start = dayOf(startsOn);
    return List.generate(count, (i) {
      final day = t.subtract(Duration(days: count - 1 - i));
      if (day.isBefore(start)) return null;
      return completions.contains(day);
    });
  }

  Habit copyWith({
    String? name,
    int? sortOrder,
    Set<DateTime>? completions,
  }) {
    return Habit(
      id: id,
      routineId: routineId,
      name: name ?? this.name,
      startsOn: startsOn,
      sortOrder: sortOrder ?? this.sortOrder,
      completions: completions ?? this.completions,
    );
  }

  /// Returns a copy with [day] ticked or cleared — used for the optimistic
  /// update so the tile responds before the write lands.
  Habit withCompletion(DateTime day, bool done) {
    final next = Set<DateTime>.from(completions);
    done ? next.add(dayOf(day)) : next.remove(dayOf(day));
    return copyWith(completions: next);
  }
}
