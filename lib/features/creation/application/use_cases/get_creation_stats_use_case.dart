import '../../domain/entities/creation_project.dart';
import '../../domain/entities/creation_session.dart';
import '../../domain/entities/creation_stats.dart';
import '../../domain/repositories/creation_repository.dart';

class GetCreationStatsUseCase {
  final CreationRepository _repository;
  const GetCreationStatsUseCase(this._repository);

  Future<CreationStats> call() async {
    final (sessions, projects) = await (
      _repository.getAllActiveSessions(),
      _repository.getAllActiveProjects(),
    ).wait;

    final lifetimeMinutes =
        sessions.fold<int>(0, (sum, s) => sum + s.minutes);
    final lifetimeHours = lifetimeMinutes / 60.0;

    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));
    final last30DaysMinutes = sessions
        .where((s) => s.sessionAt.isAfter(thirtyDaysAgo))
        .fold<int>(0, (sum, s) => sum + s.minutes);

    final best30DayMinutes = _computeBest30DayWindow(sessions);

    // Compute per-project session totals.
    final projectMinutes = <String, int>{};
    for (final s in sessions) {
      if (s.projectId != null) {
        projectMinutes[s.projectId!] =
            (projectMinutes[s.projectId!] ?? 0) + s.minutes;
      }
    }

    final enriched = projects
        .map((p) => p.copyWith(totalMinutes: projectMinutes[p.id] ?? 0))
        .toList();

    return CreationStats(
      lifetimeMinutes: lifetimeMinutes,
      lifetimeHours: lifetimeHours,
      last30DaysMinutes: last30DaysMinutes,
      best30DayMinutes: best30DayMinutes,
      activeProjects:
          enriched.where((p) => p.status == ProjectStatus.active).toList(),
      completedProjects:
          enriched.where((p) => p.status == ProjectStatus.completed).toList(),
    );
  }

  int _computeBest30DayWindow(List<CreationSession> sessions) {
    if (sessions.isEmpty) return 0;
    final sorted = [...sessions]
      ..sort((a, b) => a.sessionAt.compareTo(b.sessionAt));
    int best = 0, windowSum = 0, left = 0;
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
