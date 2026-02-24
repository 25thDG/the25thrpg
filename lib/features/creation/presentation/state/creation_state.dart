import '../../domain/entities/creation_session.dart';
import '../../domain/entities/creation_stats.dart';

enum CreationLoadStatus { initial, loading, loaded, error }

class CreationState {
  final CreationLoadStatus statsStatus;
  final CreationLoadStatus sessionsStatus;
  final CreationStats? stats;
  final List<CreationSession> todaySessions;
  final bool isMutating;
  final String? errorMessage;

  bool get isBusy =>
      statsStatus == CreationLoadStatus.loading || isMutating;

  const CreationState({
    this.statsStatus = CreationLoadStatus.initial,
    this.sessionsStatus = CreationLoadStatus.initial,
    this.stats,
    this.todaySessions = const [],
    this.isMutating = false,
    this.errorMessage,
  });

  CreationState copyWith({
    CreationLoadStatus? statsStatus,
    CreationLoadStatus? sessionsStatus,
    CreationStats? stats,
    List<CreationSession>? todaySessions,
    bool? isMutating,
    String? errorMessage,
  }) {
    return CreationState(
      statsStatus: statsStatus ?? this.statsStatus,
      sessionsStatus: sessionsStatus ?? this.sessionsStatus,
      stats: stats ?? this.stats,
      todaySessions: todaySessions ?? this.todaySessions,
      isMutating: isMutating ?? this.isMutating,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
