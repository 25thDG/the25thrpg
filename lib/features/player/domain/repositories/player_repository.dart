import '../entities/activity_history.dart';
import '../entities/player_stats.dart';

abstract interface class PlayerRepository {
  Future<PlayerStats> getPlayerStats();

  /// Day-by-day activity behind the calendar and the weekly review.
  Future<ActivityHistory> getActivityHistory();
}
