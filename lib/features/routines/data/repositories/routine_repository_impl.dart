import '../../domain/entities/routine.dart';
import '../../domain/repositories/routine_repository.dart';
import '../datasources/routine_supabase_datasource.dart';

class RoutineRepositoryImpl implements RoutineRepository {
  final RoutineSupabaseDatasource _datasource;

  const RoutineRepositoryImpl(this._datasource);

  @override
  Future<RoutineBoard> getBoard() => _datasource.getBoard();

  @override
  Future<void> setCompletion({
    required String habitId,
    required DateTime day,
    required bool done,
  }) =>
      _datasource.setCompletion(habitId: habitId, day: day, done: done);

  @override
  Future<void> addRoutine({
    required String name,
    required PartOfDay partOfDay,
    required int sortOrder,
  }) =>
      _datasource.addRoutine(
        name: name,
        partOfDay: partOfDay,
        sortOrder: sortOrder,
      );

  @override
  Future<void> updateRoutine({
    required String id,
    String? name,
    PartOfDay? partOfDay,
  }) =>
      _datasource.updateRoutine(id: id, name: name, partOfDay: partOfDay);

  @override
  Future<void> deleteRoutine(String id) => _datasource.deleteRoutine(id);

  @override
  Future<void> addHabit({
    required String routineId,
    required String name,
    required int sortOrder,
  }) =>
      _datasource.addHabit(
        routineId: routineId,
        name: name,
        sortOrder: sortOrder,
      );

  @override
  Future<void> updateHabit({required String id, String? name}) =>
      _datasource.updateHabit(id: id, name: name);

  @override
  Future<void> deleteHabit(String id) => _datasource.deleteHabit(id);
}
