import '../../domain/entities/creation_project.dart';
import '../../domain/repositories/creation_repository.dart';

class CreateProjectUseCase {
  final CreationRepository _repository;
  const CreateProjectUseCase(this._repository);

  Future<CreationProject> call({required String name}) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) throw ArgumentError('Project name must not be empty.');
    return _repository.createProject(name: trimmed);
  }
}
