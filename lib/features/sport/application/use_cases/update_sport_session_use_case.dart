import '../../domain/entities/sport_session.dart';
import '../../domain/repositories/sport_repository.dart';

class UpdateSportSessionUseCase {
  final SportRepository _repository;

  const UpdateSportSessionUseCase(this._repository);

  Future<SportSession> call({required String id, required int minutes}) {
    if (id.isEmpty) {
      throw ArgumentError('Session ID must not be empty.');
    }

    if (minutes <= 0) {
      throw ArgumentError('Minutes must be positive.');
    }

    return _repository.updateSession(id: id, minutes: minutes);
  }
}
