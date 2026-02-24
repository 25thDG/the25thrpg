import '../../../../core/error/app_exception.dart';
import '../../domain/entities/japanese_session.dart';
import '../../domain/repositories/japanese_repository.dart';

class AddJapaneseSessionUseCase {
  final JapaneseRepository _repository;

  const AddJapaneseSessionUseCase(this._repository);

  Future<JapaneseSession> execute({
    required SessionCategory category,
    required int minutes,
  }) async {
    if (minutes <= 0) {
      throw const ValidationException('Minutes must be greater than 0.');
    }

    return _repository.addSession(
      category: category,
      minutes: minutes,
      sessionAt: DateTime.now(),
    );
  }
}
