import '../../domain/entities/sport_session.dart';
import '../../domain/repositories/sport_repository.dart';

class AddSportSessionUseCase {
  final SportRepository _repository;

  const AddSportSessionUseCase(this._repository);

  static const _allowedCategories = {
    'strength',
    'cardio',
    'mobility',
    'sport_specific',
  };

  Future<SportSession> call({
    required SportCategory category,
    required int minutes,
  }) {
    if (minutes <= 0) {
      throw ArgumentError('Minutes must be positive.');
    }

    if (!_allowedCategories.contains(category.dbValue)) {
      throw ArgumentError('Invalid sport category: ${category.dbValue}');
    }

    return _repository.addSession(
      category: category,
      minutes: minutes,
      sessionAt: DateTime.now(),
    );
  }
}
