import '../../domain/entities/social_session.dart';
import '../../domain/repositories/social_repository.dart';

class GetTodaySocialSessionsUseCase {
  final SocialRepository _repository;
  const GetTodaySocialSessionsUseCase(this._repository);

  Future<List<SocialSession>> call() => _repository.getTodaySessions();
}
