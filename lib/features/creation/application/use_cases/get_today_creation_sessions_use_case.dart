import '../../domain/entities/creation_session.dart';
import '../../domain/repositories/creation_repository.dart';

class GetTodayCreationSessionsUseCase {
  final CreationRepository _repository;
  const GetTodayCreationSessionsUseCase(this._repository);

  Future<List<CreationSession>> call() => _repository.getTodaySessions();
}
