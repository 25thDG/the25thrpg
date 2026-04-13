import '../../../../core/error/app_exception.dart';
import '../../domain/entities/mindfulness_session.dart';
import '../../domain/repositories/mindfulness_repository.dart';

class AddMindfulnessSessionUseCase {
  final MindfulnessRepository _repository;

  const AddMindfulnessSessionUseCase(this._repository);

  Future<MindfulnessSession> execute({
    required MindfulnessCategory category,
    required int minutes,
  }) async {
    // Relapse is a valid 0-minute log; all other categories require > 0.
    if (category != MindfulnessCategory.addictionRelapse && minutes <= 0) {
      throw const ValidationException('Minutes must be greater than 0.');
    }

    // Validate category is a known Mindfulness category.
    // (MindfulnessCategory enum enforces this at compile time, but kept
    // explicit here for documentation and future-proofing.)
    if (!MindfulnessCategory.values.contains(category)) {
      throw ValidationException('Invalid category: ${category.name}');
    }

    return _repository.addSession(
      category: category,
      minutes: minutes,
      sessionAt: DateTime.now(),
    );
  }
}
