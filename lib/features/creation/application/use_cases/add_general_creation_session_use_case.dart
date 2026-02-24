import '../../domain/entities/creation_session.dart';
import '../../domain/repositories/creation_repository.dart';

class AddGeneralCreationSessionUseCase {
  final CreationRepository _repository;
  const AddGeneralCreationSessionUseCase(this._repository);

  Future<CreationSession> call({required int minutes}) {
    if (minutes <= 0) throw ArgumentError('Minutes must be positive.');
    return _repository.addGeneralSession(
      minutes: minutes,
      sessionAt: DateTime.now(),
    );
  }
}
