import 'sport_session.dart';

class SportCategoryStats {
  final SportCategory category;
  final int minutes;
  final double percentage;

  const SportCategoryStats({
    required this.category,
    required this.minutes,
    required this.percentage,
  });
}

class SportStats {
  final int lifetimeMinutes;
  final double lifetimeHours;
  final Map<SportCategory, SportCategoryStats> categoryBreakdown;
  final int last30DaysMinutes;
  final int best30DayMinutes;

  const SportStats({
    required this.lifetimeMinutes,
    required this.lifetimeHours,
    required this.categoryBreakdown,
    required this.last30DaysMinutes,
    required this.best30DayMinutes,
  });
}
