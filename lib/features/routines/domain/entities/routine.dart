import 'foundation.dart';
import 'habit.dart';

/// When a routine belongs in the day.
enum PartOfDay { morning, day, night }

extension PartOfDayX on PartOfDay {
  String get dbValue => name;

  String get displayName => switch (this) {
        PartOfDay.morning => 'MORNING',
        PartOfDay.day => 'DAY',
        PartOfDay.night => 'NIGHT',
      };

  static PartOfDay parse(String? value) => switch (value) {
        'morning' => PartOfDay.morning,
        'night' => PartOfDay.night,
        _ => PartOfDay.day,
      };
}

/// A named group of habits — "Morning", "Wind down", "Gym days".
class Routine {
  final String id;
  final String name;
  final PartOfDay partOfDay;
  final int sortOrder;
  final List<Habit> habits;

  const Routine({
    required this.id,
    required this.name,
    required this.partOfDay,
    this.sortOrder = 0,
    this.habits = const [],
  });

  int get total => habits.length;

  int doneCount(DateTime today) =>
      habits.where((h) => h.isDoneOn(today)).length;

  /// 0–1 for today. An empty routine reads as 0, not as complete.
  double progress(DateTime today) =>
      habits.isEmpty ? 0 : doneCount(today) / habits.length;

  bool isComplete(DateTime today) =>
      habits.isNotEmpty && doneCount(today) == habits.length;

  /// The routine takes the state of its worst habit — one broken habit is the
  /// thing worth seeing, not the average.
  FoundationState stateOn(DateTime today) {
    if (habits.isEmpty) return FoundationState.open;
    return habits
        .map((h) => h.statusOn(today).state)
        .reduce((a, b) => a.severity >= b.severity ? a : b);
  }

  /// Habits that will break unless they are done today.
  List<Habit> atRisk(DateTime today) => [
        for (final h in habits)
          if (h.statusOn(today).state == FoundationState.cracked) h,
      ];

  /// Habits already broken.
  List<Habit> broken(DateTime today) => [
        for (final h in habits)
          if (h.statusOn(today).state == FoundationState.broken) h,
      ];

  Routine copyWith({
    String? name,
    PartOfDay? partOfDay,
    int? sortOrder,
    List<Habit>? habits,
  }) {
    return Routine(
      id: id,
      name: name ?? this.name,
      partOfDay: partOfDay ?? this.partOfDay,
      sortOrder: sortOrder ?? this.sortOrder,
      habits: habits ?? this.habits,
    );
  }
}

/// Everything on the screen, plus the numbers the header needs.
class RoutineBoard {
  final List<Routine> routines;

  const RoutineBoard({this.routines = const []});

  List<Habit> get allHabits => [for (final r in routines) ...r.habits];

  int get totalHabits => allHabits.length;

  int doneToday(DateTime today) =>
      allHabits.where((h) => h.isDoneOn(today)).length;

  double progress(DateTime today) =>
      totalHabits == 0 ? 0 : doneToday(today) / totalHabits;

  List<Habit> atRisk(DateTime today) => [
        for (final r in routines) ...r.atRisk(today),
      ];

  List<Habit> broken(DateTime today) => [
        for (final r in routines) ...r.broken(today),
      ];

  /// The worst state across every habit, or null when there is nothing to
  /// track at all. Drives the badge on the tab, so what the nav says and what
  /// the screen says come from the same place.
  FoundationState? stateOn(DateTime today) {
    final habits = allHabits;
    if (habits.isEmpty) return null;
    return habits
        .map((h) => h.statusOn(today).state)
        .reduce((a, b) => a.severity >= b.severity ? a : b);
  }

  /// Habits still open today — the count the badge is really about.
  int openToday(DateTime today) => totalHabits - doneToday(today);

  /// Routines in the order they should appear: by part of day, then by their
  /// own ordering.
  List<Routine> get ordered {
    final sorted = [...routines];
    sorted.sort((a, b) {
      final byPart = a.partOfDay.index.compareTo(b.partOfDay.index);
      return byPart != 0 ? byPart : a.sortOrder.compareTo(b.sortOrder);
    });
    return sorted;
  }

  bool get isEmpty => routines.isEmpty;
}
