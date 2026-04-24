import '../../../../core/error/app_exception.dart';
import '../../domain/entities/mindfulness_session.dart';
import '../../domain/repositories/mindfulness_repository.dart';

class AddMindfulnessSessionUseCase {
  final MindfulnessRepository _repository;

  const AddMindfulnessSessionUseCase(this._repository);

  Future<MindfulnessSession> execute({
    required MindfulnessCategory category,
    required int minutes,
    DateTime? sessionAt,
  }) async {
    if (minutes <= 0) {
      throw const ValidationException('Minutes must be greater than 0.');
    }

    if (!MindfulnessCategory.values.contains(category)) {
      throw ValidationException('Invalid category: ${category.name}');
    }

    return _repository.addSession(
      category: category,
      minutes: minutes,
      sessionAt: sessionAt ?? DateTime.now(),
    );
  }
}
