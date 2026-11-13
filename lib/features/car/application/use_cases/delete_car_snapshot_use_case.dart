import '../../domain/repositories/car_repository.dart';

class DeleteCarSnapshotUseCase {
  final CarRepository _repository;

  const DeleteCarSnapshotUseCase(this._repository);

  Future<void> execute(String snapshotId) =>
      _repository.softDeleteSnapshot(snapshotId);
}
