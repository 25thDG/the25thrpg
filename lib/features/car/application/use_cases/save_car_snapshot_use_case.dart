import '../../../../core/error/app_exception.dart';
import '../../domain/entities/car_snapshot.dart';
import '../../domain/entities/car_stats.dart';
import '../../domain/repositories/car_repository.dart';

class SaveCarSnapshotUseCase {
  final CarRepository _repository;

  const SaveCarSnapshotUseCase(this._repository);

  Future<CarSnapshot> execute({required int odometerKm}) async {
    final now = DateTime.now();

    // Always today's calendar date — not the 04:00 routine day.
    // This enforces: no future entries, no past entries, one per day.
    final today = DateTime(now.year, now.month, now.day);

    final (contract, snapshots) = await (
      _repository.getContract(),
      _repository.getAllActiveSnapshots(),
    ).wait;
    final floor = CarStats.compute(contract: contract, snapshots: snapshots)
        .odometerFloorOn(today);

    if (odometerKm < floor) {
      throw ValidationException(
        'The odometer cannot be lower than the previous reading ($floor km).',
      );
    }

    return _repository.upsertSnapshot(
      odometerKm: odometerKm,
      snapshotDate: today,
    );
  }
}
