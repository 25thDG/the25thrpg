import '../../../../core/error/app_exception.dart';
import '../../domain/entities/japanese_session.dart';
import '../../domain/repositories/japanese_repository.dart';

class UpdateJapaneseSessionUseCase {
  final JapaneseRepository _repository;

  const UpdateJapaneseSessionUseCase(this._repository);

  Future<JapaneseSession> execute({
    required String sessionId,
    required int minutes,
  }) async {
    if (minutes <= 0) {
      throw const ValidationException('Minutes must be greater than 0.');
    }

    return _repository.updateSession(id: sessionId, minutes: minutes);
  }
}
