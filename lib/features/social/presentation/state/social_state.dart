import '../../domain/entities/social_session.dart';
import '../../domain/entities/social_stats.dart';

enum SocialLoadStatus { initial, loading, loaded, error }

class SocialState {
  final SocialLoadStatus statsStatus;
  final SocialLoadStatus sessionsStatus;
  final SocialStats? stats;
  final List<SocialSession> todaySessions;
  final bool isMutating;
  final String? errorMessage;

  bool get isBusy =>
      statsStatus == SocialLoadStatus.loading || isMutating;

  const SocialState({
    this.statsStatus = SocialLoadStatus.initial,
    this.sessionsStatus = SocialLoadStatus.initial,
    this.stats,
    this.todaySessions = const [],
    this.isMutating = false,
    this.errorMessage,
  });

  SocialState copyWith({
    SocialLoadStatus? statsStatus,
    SocialLoadStatus? sessionsStatus,
    SocialStats? stats,
    List<SocialSession>? todaySessions,
    bool? isMutating,
    String? errorMessage,
  }) {
    return SocialState(
      statsStatus: statsStatus ?? this.statsStatus,
      sessionsStatus: sessionsStatus ?? this.sessionsStatus,
      stats: stats ?? this.stats,
      todaySessions: todaySessions ?? this.todaySessions,
      isMutating: isMutating ?? this.isMutating,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
