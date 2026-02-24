import '../../domain/entities/japanese_session.dart';
import '../../domain/entities/japanese_stats.dart';

enum LoadStatus { initial, loading, loaded, error }

class JapaneseState {
  final LoadStatus statsStatus;
  final LoadStatus sessionsStatus;
  final JapaneseStats? stats;
  final List<JapaneseSession> todaySessions;
  final String? errorMessage;

  const JapaneseState({
    required this.statsStatus,
    required this.sessionsStatus,
    this.stats,
    required this.todaySessions,
    this.errorMessage,
  });

  factory JapaneseState.initial() => const JapaneseState(
        statsStatus: LoadStatus.initial,
        sessionsStatus: LoadStatus.initial,
        todaySessions: [],
      );

  bool get isLoadingStats => statsStatus == LoadStatus.loading;
  bool get isLoadingSessions => sessionsStatus == LoadStatus.loading;
  bool get isFullyLoaded =>
      statsStatus == LoadStatus.loaded && sessionsStatus == LoadStatus.loaded;

  JapaneseState copyWith({
    LoadStatus? statsStatus,
    LoadStatus? sessionsStatus,
    JapaneseStats? stats,
    List<JapaneseSession>? todaySessions,
    String? errorMessage,
  }) {
    return JapaneseState(
      statsStatus: statsStatus ?? this.statsStatus,
      sessionsStatus: sessionsStatus ?? this.sessionsStatus,
      stats: stats ?? this.stats,
      todaySessions: todaySessions ?? this.todaySessions,
      errorMessage: errorMessage,
    );
  }
}
