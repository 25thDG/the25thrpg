import '../../domain/entities/creation_session.dart';
import '../../domain/repositories/creation_repository.dart';

class UpdateCreationSessionUseCase {
  final CreationRepository _repository;
  const UpdateCreationSessionUseCase(this._repository);

  Future<CreationSession> call({
    required String id,
    required int minutes,
    required CreationSessionType type,
  }) {
    if (minutes <= 0) throw ArgumentError('Minutes must be positive.');
    return _repository.updateSession(id: id, minutes: minutes, type: type);
  }
}
