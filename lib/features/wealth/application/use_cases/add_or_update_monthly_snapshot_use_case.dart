import '../../../../core/error/app_exception.dart';
import '../../domain/entities/wealth_snapshot.dart';
import '../../domain/repositories/wealth_repository.dart';

class AddOrUpdateMonthlySnapshotUseCase {
  final WealthRepository _repository;

  const AddOrUpdateMonthlySnapshotUseCase(this._repository);

  Future<WealthSnapshot> execute({required double netWorthEur}) async {
    if (netWorthEur.isNaN || netWorthEur.isInfinite) {
      throw const ValidationException('Net worth must be a valid number.');
    }

    final now = DateTime.now();

    // Always normalise to the first of the current month.
    // This enforces: no future entries, no past entries, one per month.
    final snapshotMonth = DateTime(now.year, now.month, 1);

    return _repository.upsertSnapshot(
      netWorthEur: netWorthEur,
      snapshotMonth: snapshotMonth,
    );
  }
}
