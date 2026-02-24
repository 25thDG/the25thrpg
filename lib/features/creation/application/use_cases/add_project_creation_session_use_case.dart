import '../../domain/entities/creation_session.dart';
import '../../domain/repositories/creation_repository.dart';

class AddProjectCreationSessionUseCase {
  final CreationRepository _repository;
  const AddProjectCreationSessionUseCase(this._repository);

  Future<CreationSession> call({
    required String projectId,
    required int minutes,
  }) {
    if (minutes <= 0) throw ArgumentError('Minutes must be positive.');
    if (projectId.isEmpty) throw ArgumentError('Project ID must not be empty.');
    return _repository.addProjectSession(
      projectId: projectId,
      minutes: minutes,
      sessionAt: DateTime.now(),
    );
  }
}
