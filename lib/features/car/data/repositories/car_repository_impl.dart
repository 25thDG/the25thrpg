import '../../domain/entities/car_contract.dart';
import '../../domain/entities/car_snapshot.dart';
import '../../domain/repositories/car_repository.dart';
import '../datasources/car_supabase_datasource.dart';

class CarRepositoryImpl implements CarRepository {
  final CarSupabaseDatasource _datasource;

  const CarRepositoryImpl(this._datasource);

  @override
  Future<CarContract> getContract() => _datasource.getContract();

  @override
  Future<List<CarSnapshot>> getAllActiveSnapshots() =>
      _datasource.getAllActiveSnapshots();

  @override
  Future<CarSnapshot> upsertSnapshot({
    required int odometerKm,
    required DateTime snapshotDate,
  }) =>
      _datasource.upsertSnapshot(
        odometerKm: odometerKm,
        snapshotDate: snapshotDate,
      );

  @override
  Future<void> softDeleteSnapshot(String id) =>
      _datasource.softDeleteSnapshot(id);
}
