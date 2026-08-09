import '../../domain/entities/routine.dart';
import '../../domain/repositories/routine_repository.dart';

/// Loads every routine with its habits and recent completions.
class GetRoutineBoardUseCase {
  final RoutineRepository _repository;

  const GetRoutineBoardUseCase(this._repository);

  Future<RoutineBoard> call() => _repository.getBoard();
}

/// Ticks or clears one habit for one day.
class ToggleHabitUseCase {
  final RoutineRepository _repository;

  const ToggleHabitUseCase(this._repository);

  Future<void> call({
    required String habitId,
    required DateTime day,
    required bool done,
  }) =>
      _repository.setCompletion(habitId: habitId, day: day, done: done);
}

/// Create, rename and remove — grouped, because they are one screen's worth of
/// editing rather than four independent behaviours.
class EditRoutinesUseCase {
  final RoutineRepository _repository;

  const EditRoutinesUseCase(this._repository);

  Future<void> addRoutine({
    required String name,
    required PartOfDay partOfDay,
    required int sortOrder,
  }) =>
      _repository.addRoutine(
        name: name,
        partOfDay: partOfDay,
        sortOrder: sortOrder,
      );

  Future<void> renameRoutine(String id, String name) =>
      _repository.updateRoutine(id: id, name: name);

  Future<void> moveRoutine(String id, PartOfDay partOfDay) =>
      _repository.updateRoutine(id: id, partOfDay: partOfDay);

  Future<void> deleteRoutine(String id) => _repository.deleteRoutine(id);

  Future<void> addHabit({
    required String routineId,
    required String name,
    required int sortOrder,
  }) =>
      _repository.addHabit(
        routineId: routineId,
        name: name,
        sortOrder: sortOrder,
      );

  Future<void> renameHabit(String id, String name) =>
      _repository.updateHabit(id: id, name: name);

  Future<void> deleteHabit(String id) => _repository.deleteHabit(id);
}
