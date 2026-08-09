import '../entities/routine.dart';

abstract interface class RoutineRepository {
  Future<RoutineBoard> getBoard();

  /// Ticks or clears one habit for one day.
  Future<void> setCompletion({
    required String habitId,
    required DateTime day,
    required bool done,
  });

  Future<void> addRoutine({
    required String name,
    required PartOfDay partOfDay,
    required int sortOrder,
  });

  Future<void> updateRoutine({
    required String id,
    String? name,
    PartOfDay? partOfDay,
  });

  Future<void> deleteRoutine(String id);

  Future<void> addHabit({
    required String routineId,
    required String name,
    required int sortOrder,
  });

  Future<void> updateHabit({required String id, String? name});

  Future<void> deleteHabit(String id);
}
