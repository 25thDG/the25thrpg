import 'japanese_session.dart';

class CategoryStats {
  final SessionCategory category;
  final int totalMinutes;
  final double percentage;

  const CategoryStats({
    required this.category,
    required this.totalMinutes,
    required this.percentage,
  });
}

class JapaneseStats {
  final int lifetimeMinutes;
  final double lifetimeHours;
  final int currentHorizonHours;
  final Map<SessionCategory, CategoryStats> categoryBreakdown;
  final double last30DaysWeightedMinutes;
  final int last30DaysRawMinutes;
  final double best30DayWeightedMinutes;

  const JapaneseStats({
    required this.lifetimeMinutes,
    required this.lifetimeHours,
    required this.currentHorizonHours,
    required this.categoryBreakdown,
    required this.last30DaysWeightedMinutes,
    required this.last30DaysRawMinutes,
    required this.best30DayWeightedMinutes,
  });

  /// Progress toward the current horizon, capped at 1.0 for display.
  double get progressToHorizon =>
      (lifetimeHours / currentHorizonHours).clamp(0.0, 1.0);

  double get progressPercent => lifetimeHours / currentHorizonHours * 100;
}
