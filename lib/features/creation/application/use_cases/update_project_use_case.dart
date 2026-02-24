import '../../domain/entities/creation_project.dart';
import '../../domain/repositories/creation_repository.dart';

class UpdateProjectUseCase {
  final CreationRepository _repository;
  const UpdateProjectUseCase(this._repository);

  Future<CreationProject> call({required String id, required String name}) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) throw ArgumentError('Project name must not be empty.');
    return _repository.updateProject(id: id, name: trimmed);
  }
}
