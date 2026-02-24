import '../../domain/entities/sport_session.dart';
import '../../domain/repositories/sport_repository.dart';

class GetTodaySportSessionsUseCase {
  final SportRepository _repository;

  const GetTodaySportSessionsUseCase(this._repository);

  Future<List<SportSession>> call() => _repository.getTodaySessions();
}
