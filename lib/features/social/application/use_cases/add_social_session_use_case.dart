import '../../domain/entities/social_session.dart';
import '../../domain/repositories/social_repository.dart';

class AddSocialSessionUseCase {
  final SocialRepository _repository;
  const AddSocialSessionUseCase(this._repository);

  Future<SocialSession> call({
    required InitiationType initiationType,
    required int minutes,
  }) {
    if (minutes <= 0) throw ArgumentError('Minutes must be positive.');
    return _repository.addSession(
      initiationType: initiationType,
      minutes: minutes,
      sessionAt: DateTime.now(),
    );
  }
}
