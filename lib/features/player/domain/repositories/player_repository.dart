import '../entities/player_stats.dart';

abstract interface class PlayerRepository {
  Future<PlayerStats> getPlayerStats();
}
