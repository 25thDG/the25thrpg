import '../../domain/entities/sport_session.dart';
import '../../domain/entities/sport_stats.dart';
import '../../domain/repositories/sport_repository.dart';

class GetSportStatsUseCase {
  final SportRepository _repository;

  const GetSportStatsUseCase(this._repository);

  Future<SportStats> call() async {
    final sessions = await _repository.getAllActiveSessions();

    final lifetimeMinutes = sessions.fold<int>(0, (sum, s) => sum + s.minutes);
    final categoryBreakdown = _computeCategoryBreakdown(
      sessions,
      lifetimeMinutes,
    );

    final cutoff = DateTime.now().subtract(const Duration(days: 30));
    final last30DaysMinutes = sessions
        .where(
          (s) =>
              s.sessionAt.isAtSameMomentAs(cutoff) ||
              s.sessionAt.isAfter(cutoff),
        )
        .fold<int>(0, (sum, s) => sum + s.minutes);

    return SportStats(
      lifetimeMinutes: lifetimeMinutes,
      lifetimeHours: lifetimeMinutes / 60.0,
      categoryBreakdown: categoryBreakdown,
      last30DaysMinutes: last30DaysMinutes,
      best30DayMinutes: _computeBest30DayWindow(sessions),
    );
  }

  Map<SportCategory, SportCategoryStats> _computeCategoryBreakdown(
    List<SportSession> sessions,
    int lifetimeMinutes,
  ) {
    final totals = {for (final c in SportCategory.values) c: 0};

    for (final s in sessions) {
      totals[s.category] = (totals[s.category] ?? 0) + s.minutes;
    }

    return {
      for (final c in SportCategory.values)
        c: SportCategoryStats(
          category: c,
          minutes: totals[c] ?? 0,
          percentage: lifetimeMinutes > 0
              ? (totals[c] ?? 0) / lifetimeMinutes * 100.0
              : 0.0,
        ),
    };
  }

  int _computeBest30DayWindow(List<SportSession> sessions) {
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

      if (windowSum > best) {
        best = windowSum;
      }
    }

    return best;
  }
}
