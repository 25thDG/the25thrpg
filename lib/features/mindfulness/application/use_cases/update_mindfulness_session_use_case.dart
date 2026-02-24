import '../../../../core/error/app_exception.dart';
import '../../domain/entities/mindfulness_session.dart';
import '../../domain/repositories/mindfulness_repository.dart';

class UpdateMindfulnessSessionUseCase {
  final MindfulnessRepository _repository;

  const UpdateMindfulnessSessionUseCase(this._repository);

  Future<MindfulnessSession> execute({
    required String sessionId,
    required int minutes,
  }) async {
    if (minutes <= 0) {
      throw const ValidationException('Minutes must be greater than 0.');
    }

    return _repository.updateSession(id: sessionId, minutes: minutes);
  }
}
