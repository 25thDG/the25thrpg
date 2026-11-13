import '../entities/car_contract.dart';
import '../entities/car_snapshot.dart';

abstract class CarRepository {
  /// The contract for the app's single user: handover, term and yearly limits.
  Future<CarContract> getContract();

  /// All non-deleted snapshots, ordered ascending by snapshot_date.
  Future<List<CarSnapshot>> getAllActiveSnapshots();

  /// Insert or update the snapshot for [snapshotDate].
  /// Uses the DB unique constraint on (user_id, snapshot_date) to upsert.
  Future<CarSnapshot> upsertSnapshot({
    required int odometerKm,
    required DateTime snapshotDate,
  });

  Future<void> softDeleteSnapshot(String id);
}
