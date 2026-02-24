import '../../domain/entities/creation_session.dart';
import '../../domain/repositories/creation_repository.dart';

class DeleteCreationSessionUseCase {
  final CreationRepository _repository;
  const DeleteCreationSessionUseCase(this._repository);

  Future<void> call({required String id, required CreationSessionType type}) =>
      _repository.softDeleteSession(id: id, type: type);
}
