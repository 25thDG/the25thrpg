import '../../domain/entities/mindfulness_session.dart';
import '../../domain/entities/mindfulness_stats.dart';

enum MindfulnessLoadStatus { initial, loading, loaded, error }

class MindfulnessState {
  final MindfulnessLoadStatus statsStatus;
  final MindfulnessLoadStatus sessionsStatus;
  final MindfulnessStats? stats;
  final List<MindfulnessSession> todaySessions;
  final String? errorMessage;

  const MindfulnessState({
    required this.statsStatus,
    required this.sessionsStatus,
    this.stats,
    required this.todaySessions,
    this.errorMessage,
  });

  factory MindfulnessState.initial() => const MindfulnessState(
        statsStatus: MindfulnessLoadStatus.initial,
        sessionsStatus: MindfulnessLoadStatus.initial,
        todaySessions: [],
      );

  bool get isLoadingStats =>
      statsStatus == MindfulnessLoadStatus.loading;
  bool get isLoadingSessions =>
      sessionsStatus == MindfulnessLoadStatus.loading;

  MindfulnessState copyWith({
    MindfulnessLoadStatus? statsStatus,
    MindfulnessLoadStatus? sessionsStatus,
    MindfulnessStats? stats,
    List<MindfulnessSession>? todaySessions,
    String? errorMessage,
  }) {
    return MindfulnessState(
      statsStatus: statsStatus ?? this.statsStatus,
      sessionsStatus: sessionsStatus ?? this.sessionsStatus,
      stats: stats ?? this.stats,
      todaySessions: todaySessions ?? this.todaySessions,
      errorMessage: errorMessage,
    );
  }
}
