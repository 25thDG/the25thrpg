import '../../domain/entities/wealth_snapshot.dart';
import '../../domain/repositories/wealth_repository.dart';
import '../datasources/wealth_supabase_datasource.dart';

class WealthRepositoryImpl implements WealthRepository {
  final WealthSupabaseDatasource _datasource;

  const WealthRepositoryImpl(this._datasource);

  @override
  Future<List<WealthSnapshot>> getAllActiveSnapshots() =>
      _datasource.getAllActiveSnapshots();

  @override
  Future<WealthSnapshot> upsertSnapshot({
    required double netWorthEur,
    required DateTime snapshotMonth,
  }) =>
      _datasource.upsertSnapshot(
        netWorthEur: netWorthEur,
        snapshotMonth: snapshotMonth,
      );

  @override
  Future<void> softDeleteSnapshot(String id) =>
      _datasource.softDeleteSnapshot(id);
}
