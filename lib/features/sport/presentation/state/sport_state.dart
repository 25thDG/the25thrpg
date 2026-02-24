import '../../domain/entities/sport_session.dart';
import '../../domain/entities/sport_stats.dart';

enum SportLoadStatus { initial, loading, loaded, error }

class SportState {
  final SportLoadStatus statsStatus;
  final SportLoadStatus sessionsStatus;
  final SportStats? stats;
  final List<SportSession> todaySessions;
  final bool isMutating;
  final String? errorMessage;

  bool get isBusy => statsStatus == SportLoadStatus.loading || isMutating;

  const SportState({
    this.statsStatus = SportLoadStatus.initial,
    this.sessionsStatus = SportLoadStatus.initial,
    this.stats,
    this.todaySessions = const [],
    this.isMutating = false,
    this.errorMessage,
  });

  SportState copyWith({
    SportLoadStatus? statsStatus,
    SportLoadStatus? sessionsStatus,
    SportStats? stats,
    List<SportSession>? todaySessions,
    bool? isMutating,
    String? errorMessage,
  }) {
    return SportState(
      statsStatus: statsStatus ?? this.statsStatus,
      sessionsStatus: sessionsStatus ?? this.sessionsStatus,
      stats: stats ?? this.stats,
      todaySessions: todaySessions ?? this.todaySessions,
      isMutating: isMutating ?? this.isMutating,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
