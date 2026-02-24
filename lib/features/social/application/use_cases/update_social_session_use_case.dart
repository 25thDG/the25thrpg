import '../../domain/entities/social_session.dart';
import '../../domain/repositories/social_repository.dart';

class UpdateSocialSessionUseCase {
  final SocialRepository _repository;
  const UpdateSocialSessionUseCase(this._repository);

  Future<SocialSession> call({required String id, required int minutes}) {
    if (minutes <= 0) throw ArgumentError('Minutes must be positive.');
    return _repository.updateSession(id: id, minutes: minutes);
  }
}
