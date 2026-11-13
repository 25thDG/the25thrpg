import '../../domain/entities/car_stats.dart';
import '../../domain/repositories/car_repository.dart';

class GetCarStatsUseCase {
  final CarRepository _repository;

  const GetCarStatsUseCase(this._repository);

  Future<CarStats> execute() async {
    final (contract, snapshots) = await (
      _repository.getContract(),
      _repository.getAllActiveSnapshots(),
    ).wait;

    return CarStats.compute(contract: contract, snapshots: snapshots);
  }
}
