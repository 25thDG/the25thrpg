import '../../domain/repositories/creation_repository.dart';

class DeleteProjectUseCase {
  final CreationRepository _repository;
  const DeleteProjectUseCase(this._repository);

  Future<void> call(String id) => _repository.softDeleteProject(id);
}
