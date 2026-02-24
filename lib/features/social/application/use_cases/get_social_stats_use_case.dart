import '../../domain/entities/social_session.dart';
import '../../domain/entities/social_stats.dart';
import '../../domain/repositories/social_repository.dart';

class GetSocialStatsUseCase {
  final SocialRepository _repository;
  const GetSocialStatsUseCase(this._repository);

  Future<SocialStats> call() async {
    final sessions = await _repository.getAllActiveSessions();

    // Lifetime
    final lifetimeMinutes =
        sessions.fold<int>(0, (sum, s) => sum + s.minutes);
    final lifetimeSelfMinutes = sessions
        .where((s) => s.initiationType == InitiationType.self)
        .fold<int>(0, (sum, s) => sum + s.minutes);
    final lifetimeOtherMinutes = lifetimeMinutes - lifetimeSelfMinutes;
    final lifetimeSelfPct = lifetimeMinutes > 0
        ? lifetimeSelfMinutes / lifetimeMinutes * 100.0
        : 0.0;

    // Last 30 days
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));
    final recent =
        sessions.where((s) => s.sessionAt.isAfter(thirtyDaysAgo)).toList();
    final last30Minutes = recent.fold<int>(0, (sum, s) => sum + s.minutes);
    final last30SelfMinutes = recent
        .where((s) => s.initiationType == InitiationType.self)
        .fold<int>(0, (sum, s) => sum + s.minutes);
    final last30SelfPct = last30Minutes > 0
        ? last30SelfMinutes / last30Minutes * 100.0
        : 0.0;

    return SocialStats(
      lifetimeMinutes: lifetimeMinutes,
      lifetimeHours: lifetimeMinutes / 60.0,
      lifetimeSelfInitiatedMinutes: lifetimeSelfMinutes,
      lifetimeOtherInitiatedMinutes: lifetimeOtherMinutes,
      lifetimeSelfInitiatedPercentage: lifetimeSelfPct,
      last30DaysMinutes: last30Minutes,
      last30DaysSelfInitiatedMinutes: last30SelfMinutes,
      last30DaysSelfInitiatedPercentage: last30SelfPct,
      best30DayMinutes: _computeBest30DayWindow(sessions),
    );
  }

  int _computeBest30DayWindow(List<SocialSession> sessions) {
    if (sessions.isEmpty) return 0;
    final sorted = [...sessions]
      ..sort((a, b) => a.sessionAt.compareTo(b.sessionAt));
    int best = 0, windowSum = 0, left = 0;
    for (int right = 0; right < sorted.length; right++) {
      windowSum += sorted[right].minutes;
      while (sorted[right].sessionAt.difference(sorted[left].sessionAt) >
          const Duration(days: 30)) {
        windowSum -= sorted[left].minutes;
        left++;
      }
      if (windowSum > best) best = windowSum;
    }
    return best;
  }
}
