import '../../domain/entities/mindfulness_session.dart';
import '../../domain/entities/mindfulness_stats.dart';
import '../../domain/repositories/mindfulness_repository.dart';

class GetMindfulnessStatsUseCase {
  final MindfulnessRepository _repository;

  const GetMindfulnessStatsUseCase(this._repository);

  Future<MindfulnessStats> execute() async {
    final sessions = await _repository.getAllActiveSessions();
    return _compute(sessions);
  }

  MindfulnessStats _compute(List<MindfulnessSession> sessions) {
    // 1. Lifetime totals
    final lifetimeMinutes = sessions.fold(0, (sum, s) => sum + s.minutes);
    final lifetimeHours = lifetimeMinutes / 60.0;

    // 2. Category breakdown
    final categoryBreakdown =
        _computeCategoryBreakdown(sessions, lifetimeMinutes);

    // 3. Last 30 days (raw, no weights)
    final cutoff = DateTime.now().subtract(const Duration(days: 30));
    final last30DaysMinutes = sessions
        .where((s) => s.sessionAt.isAfter(cutoff))
        .fold(0, (sum, s) => sum + s.minutes);

    // 4. Best rolling 30-day window
    final best30DayMinutes = _computeBest30DayWindow(sessions);

    return MindfulnessStats(
      lifetimeMinutes: lifetimeMinutes,
      lifetimeHours: lifetimeHours,
      categoryBreakdown: categoryBreakdown,
      last30DaysMinutes: last30DaysMinutes,
      best30DayMinutes: best30DayMinutes,
    );
  }

  Map<MindfulnessCategory, MindfulnessCategoryStats> _computeCategoryBreakdown(
    List<MindfulnessSession> sessions,
    int lifetimeMinutes,
  ) {
    final totals = {for (final c in MindfulnessCategory.values) c: 0};
    for (final s in sessions) {
      totals[s.category] = (totals[s.category] ?? 0) + s.minutes;
    }

    return {
      for (final c in MindfulnessCategory.values)
        c: MindfulnessCategoryStats(
          category: c,
          totalMinutes: totals[c] ?? 0,
          percentage: lifetimeMinutes > 0
              ? (totals[c] ?? 0) / lifetimeMinutes * 100
              : 0.0,
        ),
    };
  }

  /// Sliding-window O(n log n) — sorts once, two-pointer scan, no weights.
  int _computeBest30DayWindow(List<MindfulnessSession> sessions) {
    if (sessions.isEmpty) return 0;

    final sorted = [...sessions]
      ..sort((a, b) => a.sessionAt.compareTo(b.sessionAt));

    int best = 0;
    int windowSum = 0;
    int left = 0;

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
