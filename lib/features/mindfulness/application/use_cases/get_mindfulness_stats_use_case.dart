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
    final addictionSessions =
        sessions.where((s) => s.category.isAddiction).toList();
    final regularSessions =
        sessions.where((s) => !s.category.isAddiction).toList();

    // 1. Lifetime totals (all sessions — clean addiction days count as 10 min)
    final lifetimeMinutes = sessions.fold(0, (sum, s) => sum + s.minutes);
    final lifetimeHours = lifetimeMinutes / 60.0;

    // 2. Category breakdown — regular sessions only, percentages from their total
    final regularTotal = regularSessions.fold(0, (sum, s) => sum + s.minutes);
    final categoryBreakdown =
        _computeCategoryBreakdown(regularSessions, regularTotal);

    // 3. Last 30 days (raw, no weights — all sessions)
    final cutoff = DateTime.now().subtract(const Duration(days: 30));
    final last30DaysMinutes = sessions
        .where((s) => s.sessionAt.isAfter(cutoff))
        .fold(0, (sum, s) => sum + s.minutes);

    // 4. Best rolling 30-day window (regular sessions only)
    final best30DayMinutes = _computeBest30DayWindow(regularSessions);

    // 5. Addiction streak
    final addictionStreak = _computeAddictionStreak(addictionSessions);
    final isCleanToday = _isCleanToday(addictionSessions);
    final isRelapsedToday = _isRelapsedToday(addictionSessions);

    return MindfulnessStats(
      lifetimeMinutes: lifetimeMinutes,
      lifetimeHours: lifetimeHours,
      categoryBreakdown: categoryBreakdown,
      last30DaysMinutes: last30DaysMinutes,
      best30DayMinutes: best30DayMinutes,
      addictionStreak: addictionStreak,
      isCleanToday: isCleanToday,
      isRelapsedToday: isRelapsedToday,
    );
  }

  Map<MindfulnessCategory, MindfulnessCategoryStats> _computeCategoryBreakdown(
    List<MindfulnessSession> sessions,
    int total,
  ) {
    final regularCategories =
        MindfulnessCategory.values.where((c) => !c.isAddiction).toList();

    final totals = {for (final c in regularCategories) c: 0};
    for (final s in sessions) {
      totals[s.category] = (totals[s.category] ?? 0) + s.minutes;
    }

    return {
      for (final c in regularCategories)
        c: MindfulnessCategoryStats(
          category: c,
          totalMinutes: totals[c] ?? 0,
          percentage:
              total > 0 ? (totals[c] ?? 0) / total * 100 : 0.0,
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

  // ── Addiction streak helpers ──────────────────────────────────────────────

  /// Consecutive clean days working backwards from today.
  ///
  /// - If today is relapsed → 0.
  /// - If today is not yet logged → count from yesterday.
  /// - Any unlogged day in the chain → stops the streak.
  int _computeAddictionStreak(List<MindfulnessSession> addictionSessions) {
    if (addictionSessions.isEmpty) return 0;

    final dayMap = _buildDayMap(addictionSessions);
    final today = DateTime.now();
    final todayKey = _dateKey(today);

    if (dayMap[todayKey] == false) return 0; // relapsed today

    int streak = 0;
    final startOffset = dayMap[todayKey] == true ? 0 : 1;

    for (int i = startOffset; ; i++) {
      final key = _dateKey(today.subtract(Duration(days: i)));
      final isClean = dayMap[key];
      if (isClean == null || !isClean) break;
      streak++;
    }

    return streak;
  }

  bool _isCleanToday(List<MindfulnessSession> addictionSessions) {
    return _buildDayMap(addictionSessions)[_dateKey(DateTime.now())] == true;
  }

  bool _isRelapsedToday(List<MindfulnessSession> addictionSessions) {
    return _buildDayMap(addictionSessions)[_dateKey(DateTime.now())] == false;
  }

  /// Maps local date → true (clean) or false (relapsed).
  /// A relapse entry always wins over a clean entry for the same day.
  Map<String, bool> _buildDayMap(List<MindfulnessSession> addictionSessions) {
    final map = <String, bool>{};
    for (final s in addictionSessions) {
      final key = _dateKey(s.sessionAt);
      if (s.category == MindfulnessCategory.addictionRelapse) {
        map[key] = false;
      } else {
        map[key] ??= true;
      }
    }
    return map;
  }

  static String _dateKey(DateTime d) => '${d.year}-${d.month}-${d.day}';
}
