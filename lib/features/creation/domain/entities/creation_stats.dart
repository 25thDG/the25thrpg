import 'creation_project.dart';

class CreationStats {
  final int lifetimeMinutes;
  final double lifetimeHours;
  final int last30DaysMinutes;
  final int best30DayMinutes;
  final List<CreationProject> activeProjects;
  final List<CreationProject> completedProjects;

  const CreationStats({
    required this.lifetimeMinutes,
    required this.lifetimeHours,
    required this.last30DaysMinutes,
    required this.best30DayMinutes,
    required this.activeProjects,
    required this.completedProjects,
  });
}
