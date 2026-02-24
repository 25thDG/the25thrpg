import '../../domain/entities/japanese_session.dart';
import '../../domain/entities/japanese_stats.dart';
import '../../domain/repositories/japanese_repository.dart';

const Map<SessionCategory, double> categoryWeights = {
  SessionCategory.vocab: 1.0,
  SessionCategory.reading: 1.2,
  SessionCategory.active: 1.5,
  SessionCategory.passive: 0.7,
  SessionCategory.accent: 1.3,
};

class GetJapaneseStatsUseCase {
  final JapaneseRepository _repository;

  const GetJapaneseStatsUseCase(this._repository);

  Future<JapaneseStats> execute() async {
    final sessions = await _repository.getAllActiveSessions();
    return _compute(sessions);
  }

  JapaneseStats _compute(List<JapaneseSession> sessions) {
    // 1. Lifetime totals
    final lifetimeMinutes = sessions.fold(0, (sum, s) => sum + s.minutes);
    final lifetimeHours = lifetimeMinutes / 60.0;

    // 2. Moving horizon
    final currentHorizonHours = _computeHorizon(lifetimeHours);

    // 3. Category breakdown
    final categoryBreakdown =
        _computeCategoryBreakdown(sessions, lifetimeMinutes);

    // 4. Last 30 days
    final cutoff = DateTime.now().subtract(const Duration(days: 30));
    final recent = sessions.where((s) => s.sessionAt.isAfter(cutoff)).toList();
    final last30DaysRawMinutes = recent.fold(0, (sum, s) => sum + s.minutes);
    final last30DaysWeightedMinutes = recent.fold(
      0.0,
      (sum, s) => sum + s.minutes * (categoryWeights[s.category] ?? 1.0),
    );

    // 5. Best rolling 30-day window over all history
    final best30DayWeightedMinutes = _computeBest30DayWindow(sessions);

    return JapaneseStats(
      lifetimeMinutes: lifetimeMinutes,
      lifetimeHours: lifetimeHours,
      currentHorizonHours: currentHorizonHours,
      categoryBreakdown: categoryBreakdown,
      last30DaysWeightedMinutes: last30DaysWeightedMinutes,
      last30DaysRawMinutes: last30DaysRawMinutes,
      best30DayWeightedMinutes: best30DayWeightedMinutes,
    );
  }

  int _computeHorizon(double lifetimeHours) {
    if (lifetimeHours < 2200) return 2200;
    final extra = lifetimeHours - 2200;
    final blocks = (extra / 100).floor() + 1;
    return 2200 + (blocks * 100);
  }

  Map<SessionCategory, CategoryStats> _computeCategoryBreakdown(
    List<JapaneseSession> sessions,
    int lifetimeMinutes,
  ) {
    final totals = {for (final c in SessionCategory.values) c: 0};
    for (final s in sessions) {
      totals[s.category] = (totals[s.category] ?? 0) + s.minutes;
    }

    return {
      for (final c in SessionCategory.values)
        c: CategoryStats(
          category: c,
          totalMinutes: totals[c] ?? 0,
          percentage: lifetimeMinutes > 0
              ? (totals[c] ?? 0) / lifetimeMinutes * 100
              : 0.0,
        ),
    };
  }

  /// Sliding-window O(n log n) approach — sorts once, then two-pointer scan.
  double _computeBest30DayWindow(List<JapaneseSession> sessions) {
    if (sessions.isEmpty) return 0.0;

    final sorted = [...sessions]
      ..sort((a, b) => a.sessionAt.compareTo(b.sessionAt));

    double best = 0.0;
    double windowSum = 0.0;
    int left = 0;

    for (int right = 0; right < sorted.length; right++) {
      windowSum +=
          sorted[right].minutes * (categoryWeights[sorted[right].category] ?? 1.0);

      while (sorted[right].sessionAt.difference(sorted[left].sessionAt) >
          const Duration(days: 30)) {
        windowSum -=
            sorted[left].minutes * (categoryWeights[sorted[left].category] ?? 1.0);
        left++;
      }

      if (windowSum > best) best = windowSum;
    }

    return best;
  }
}
