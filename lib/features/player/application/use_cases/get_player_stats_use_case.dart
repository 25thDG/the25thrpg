import '../../domain/entities/player_stats.dart';
import '../../domain/repositories/player_repository.dart';

class GetPlayerStatsUseCase {
  final PlayerRepository _repository;

  const GetPlayerStatsUseCase(this._repository);

  Future<PlayerStats> call() => _repository.getPlayerStats();
}
