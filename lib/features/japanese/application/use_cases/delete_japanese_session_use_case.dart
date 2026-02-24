import '../../domain/repositories/japanese_repository.dart';

class DeleteJapaneseSessionUseCase {
  final JapaneseRepository _repository;

  const DeleteJapaneseSessionUseCase(this._repository);

  Future<void> execute(String sessionId) =>
      _repository.softDeleteSession(sessionId);
}
