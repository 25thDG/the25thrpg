import '../../domain/entities/creation_project.dart';
import '../../domain/repositories/creation_repository.dart';

class CompleteProjectUseCase {
  final CreationRepository _repository;
  const CompleteProjectUseCase(this._repository);

  Future<CreationProject> call(String id) => _repository.completeProject(id);
}
