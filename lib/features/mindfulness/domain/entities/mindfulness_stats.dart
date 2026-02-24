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

  const MindfulnessStats({
    required this.lifetimeMinutes,
    required this.lifetimeHours,
    required this.categoryBreakdown,
    required this.last30DaysMinutes,
    required this.best30DayMinutes,
  });
}
