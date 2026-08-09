import 'package:flutter/foundation.dart';

import '../../application/use_cases/routine_use_cases.dart';
import '../../domain/entities/foundation.dart';
import '../../domain/entities/habit.dart';
import '../../domain/entities/routine.dart';
import '../state/routine_state.dart';

class RoutineController extends ChangeNotifier {
  final GetRoutineBoardUseCase _getBoard;
  final ToggleHabitUseCase _toggleHabit;
  final EditRoutinesUseCase _edit;

  RoutineState _state = RoutineState(today: dayOf(DateTime.now()));
  RoutineState get state => _state;

  RoutineController({
    required GetRoutineBoardUseCase getBoard,
    required ToggleHabitUseCase toggleHabit,
    required EditRoutinesUseCase edit,
  })  : _getBoard = getBoard,
        _toggleHabit = toggleHabit,
        _edit = edit;

  void _emit(RoutineState s) {
    _state = s;
    notifyListeners();
  }

  Future<void> load() async {
    _emit(_state.copyWith(
      status: RoutineLoadStatus.loading,
      today: dayOf(DateTime.now()),
    ));
    try {
      final board = await _getBoard();
      _emit(_state.copyWith(
        status: RoutineLoadStatus.loaded,
        board: board,
        errorMessage: '',
      ));
    } catch (e) {
      _emit(_state.copyWith(
        status: RoutineLoadStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  /// Ticks a habit for today.
  ///
  /// The board is updated before the write goes out — a habit tick has to feel
  /// instant, and the worst case is one tile that snaps back on the reload.
  Future<void> toggle(Habit habit) async {
    final day = _state.today;
    final done = !habit.isDoneOn(day);

    _emit(_state.copyWith(board: _replace(habit.id, (h) => h.withCompletion(day, done))));

    try {
      await _toggleHabit(habitId: habit.id, day: day, done: done);
    } catch (_) {
      // Put it back the way it was; the row never changed.
      _emit(_state.copyWith(
        board: _replace(habit.id, (h) => h.withCompletion(day, !done)),
      ));
      rethrow;
    }
  }

  /// Swaps one habit for an edited copy, leaving everything else alone.
  RoutineBoard _replace(String habitId, Habit Function(Habit) edit) {
    return RoutineBoard(
      routines: [
        for (final r in _state.board.routines)
          r.copyWith(
            habits: [
              for (final h in r.habits) h.id == habitId ? edit(h) : h,
            ],
          ),
      ],
    );
  }

  // ── Editing ────────────────────────────────────────────────────────────────

  Future<void> addRoutine(String name, PartOfDay partOfDay) async {
    await _edit.addRoutine(
      name: name,
      partOfDay: partOfDay,
      sortOrder: _state.board.routines.length,
    );
    await load();
  }

  Future<void> renameRoutine(String id, String name) async {
    await _edit.renameRoutine(id, name);
    await load();
  }

  Future<void> deleteRoutine(String id) async {
    await _edit.deleteRoutine(id);
    await load();
  }

  Future<void> addHabit(Routine routine, String name) async {
    await _edit.addHabit(
      routineId: routine.id,
      name: name,
      sortOrder: routine.habits.length,
    );
    await load();
  }

  Future<void> renameHabit(String id, String name) async {
    await _edit.renameHabit(id, name);
    await load();
  }

  Future<void> deleteHabit(String id) async {
    await _edit.deleteHabit(id);
    await load();
  }
}
