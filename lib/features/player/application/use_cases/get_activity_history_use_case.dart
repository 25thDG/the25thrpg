import '../../domain/entities/activity_history.dart';
import '../../domain/repositories/player_repository.dart';

class GetActivityHistoryUseCase {
  final PlayerRepository _repository;

  const GetActivityHistoryUseCase(this._repository);

  Future<ActivityHistory> call() => _repository.getActivityHistory();
}
