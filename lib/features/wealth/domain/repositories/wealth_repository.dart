import '../entities/wealth_snapshot.dart';

abstract class WealthRepository {
  /// All non-deleted snapshots for the app's single user,
  /// ordered ascending by snapshot_month.
  Future<List<WealthSnapshot>> getAllActiveSnapshots();

  /// Insert or update the snapshot for [snapshotMonth].
  /// Uses the DB unique constraint on (user_id, snapshot_month) to upsert.
  Future<WealthSnapshot> upsertSnapshot({
    required double netWorthEur,
    required DateTime snapshotMonth,
  });

  Future<void> softDeleteSnapshot(String id);
}
