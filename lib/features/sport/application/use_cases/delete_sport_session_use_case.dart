import '../../domain/repositories/sport_repository.dart';

class DeleteSportSessionUseCase {
  final SportRepository _repository;

  const DeleteSportSessionUseCase(this._repository);

  Future<void> call(String id) {
    if (id.isEmpty) {
      throw ArgumentError('Session ID must not be empty.');
    }

    return _repository.softDeleteSession(id);
  }
}
