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

    // 1. Lifetime totals — regular sessions only (addiction excluded)
    final lifetimeMinutes =
        regularSessions.fold(0, (sum, s) => sum + s.minutes);
    final lifetimeHours = lifetimeMinutes / 60.0;

    // 2. Category breakdown — regular sessions only, percentages from their total
    final regularTotal = lifetimeMinutes;
    final categoryBreakdown =
        _computeCategoryBreakdown(regularSessions, regularTotal);

    // 3. Last 30 days — regular sessions only
    final cutoff = DateTime.now().subtract(const Duration(days: 30));
    final last30DaysMinutes = regularSessions
        .where((s) => s.sessionAt.isAfter(cutoff))
        .fold(0, (sum, s) => sum + s.minutes);

    // 4. Best rolling 30-day window (regular sessions only)
    final best30DayMinutes = _computeBest30DayWindow(regularSessions);

    // 5. Addiction streak + history
    final dayMap = _buildDayMap(addictionSessions);
    final addictionStreak = _computeAddictionStreakFromMap(dayMap);
    final longestAddictionStreak = _computeLongestStreak(dayMap);
    final isCleanToday = dayMap[_dateKey(DateTime.now())] == true;
    final isRelapsedToday = dayMap[_dateKey(DateTime.now())] == false;

    return MindfulnessStats(
      lifetimeMinutes: lifetimeMinutes,
      lifetimeHours: lifetimeHours,
      categoryBreakdown: categoryBreakdown,
      last30DaysMinutes: last30DaysMinutes,
      best30DayMinutes: best30DayMinutes,
      addictionStreak: addictionStreak,
      longestAddictionStreak: longestAddictionStreak,
      isCleanToday: isCleanToday,
      isRelapsedToday: isRelapsedToday,
      addictionDayHistory: dayMap,
      addictionSessions: addictionSessions,
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

  // ── Addiction helpers ─────────────────────────────────────────────────────

  /// Maps local date → true (clean) or false (relapsed).
  /// A relapse entry always wins over a clean entry for the same day.
  Map<String, bool> _buildDayMap(List<MindfulnessSession> addictionSessions) {
    final map = <String, bool>{};
    for (final s in addictionSessions) {
      final key = _dateKey(s.sessionAt.toLocal());
      if (s.category == MindfulnessCategory.addictionRelapse) {
        map[key] = false;
      } else {
        map[key] ??= true;
      }
    }
    return map;
  }

  /// Current streak: consecutive clean days ending today (or yesterday if
  /// today is not yet logged). Any unlogged or relapsed day breaks the chain.
  int _computeAddictionStreakFromMap(Map<String, bool> dayMap) {
    if (dayMap.isEmpty) return 0;
    final today = DateTime.now();
    if (dayMap[_dateKey(today)] == false) return 0; // relapsed today

    int streak = 0;
    final startOffset = dayMap[_dateKey(today)] == true ? 0 : 1;
    for (int i = startOffset; ; i++) {
      final key = _dateKey(today.subtract(Duration(days: i)));
      if (dayMap[key] != true) break;
      streak++;
    }
    return streak;
  }

  /// Longest ever clean streak across all logged history.
  int _computeLongestStreak(Map<String, bool> dayMap) {
    if (dayMap.isEmpty) return 0;

    // Sort date keys chronologically
    final sorted = dayMap.keys.toList()
      ..sort((a, b) => _parseKey(a).compareTo(_parseKey(b)));

    int longest = 0;
    int current = 0;
    DateTime? prev;

    for (final key in sorted) {
      final date = _parseKey(key);
      // Any gap in logged days resets the counter
      if (prev != null && date.difference(prev).inDays > 1) current = 0;

      if (dayMap[key] == true) {
        current++;
        if (current > longest) longest = current;
      } else {
        current = 0; // relapse resets
      }
      prev = date;
    }
    return longest;
  }

  static DateTime _parseKey(String key) {
    final p = key.split('-');
    return DateTime(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
  }

  static String _dateKey(DateTime d) => '${d.year}-${d.month}-${d.day}';
}
