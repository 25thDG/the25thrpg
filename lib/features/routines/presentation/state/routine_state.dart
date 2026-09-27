import '../../domain/entities/routine.dart';

enum RoutineLoadStatus { initial, loading, loaded, error }

class RoutineState {
  final RoutineLoadStatus status;
  final RoutineBoard board;
  final String? errorMessage;

  /// The routine day the board is being shown for — which is not the calendar
  /// date between midnight and 04:00. Held as state so the whole screen agrees
  /// on one "today" while it is open.
  final DateTime today;

  const RoutineState({
    this.status = RoutineLoadStatus.initial,
    this.board = const RoutineBoard(),
    this.errorMessage,
    required this.today,
  });

  bool get isLoading => status == RoutineLoadStatus.loading;

  /// True when the tables have not been created yet — the one error worth
  /// explaining rather than dumping raw.
  bool get isMissingSchema =>
      (errorMessage ?? '').contains('routines') &&
      ((errorMessage ?? '').contains('does not exist') ||
          (errorMessage ?? '').contains('schema cache'));

  RoutineState copyWith({
    RoutineLoadStatus? status,
    RoutineBoard? board,
    String? errorMessage,
    DateTime? today,
  }) {
    return RoutineState(
      status: status ?? this.status,
      board: board ?? this.board,
      errorMessage: errorMessage ?? this.errorMessage,
      today: today ?? this.today,
    );
  }
}
