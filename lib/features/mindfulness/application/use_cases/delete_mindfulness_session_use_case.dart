import '../../domain/repositories/mindfulness_repository.dart';

class DeleteMindfulnessSessionUseCase {
  final MindfulnessRepository _repository;

  const DeleteMindfulnessSessionUseCase(this._repository);

  Future<void> execute(String sessionId) =>
      _repository.softDeleteSession(sessionId);
}
