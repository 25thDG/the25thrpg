import 'mindfulness_session.dart';

class MindfulnessCategoryStats {
  final MindfulnessCategory category;
  final int totalMinutes;
  final double percentage;

  const MindfulnessCategoryStats({
    required this.category,
    required this.totalMinutes,
    required this.percentage,
  });
}

class MindfulnessStats {
  final int lifetimeMinutes;
  final double lifetimeHours;
  final Map<MindfulnessCategory, MindfulnessCategoryStats> categoryBreakdown;
  final int last30DaysMinutes;
  final int best30DayMinutes;

  /// Consecutive clean (addiction-free) days ending today.
  final int addictionStreak;

  /// Whether today has been logged as a clean day (and no relapse recorded).
  final bool isCleanToday;

  /// Whether today has been logged as a relapse.
  final bool isRelapsedToday;

  const MindfulnessStats({
    required this.lifetimeMinutes,
    required this.lifetimeHours,
    required this.categoryBreakdown,
    required this.last30DaysMinutes,
    required this.best30DayMinutes,
    required this.addictionStreak,
    required this.isCleanToday,
    required this.isRelapsedToday,
  });
}
