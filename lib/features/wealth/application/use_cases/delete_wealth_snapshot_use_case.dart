import '../../domain/repositories/wealth_repository.dart';

class DeleteWealthSnapshotUseCase {
  final WealthRepository _repository;

  const DeleteWealthSnapshotUseCase(this._repository);

  Future<void> execute(String snapshotId) =>
      _repository.softDeleteSnapshot(snapshotId);
}
