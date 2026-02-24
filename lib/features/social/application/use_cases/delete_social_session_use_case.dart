import '../../domain/repositories/social_repository.dart';

class DeleteSocialSessionUseCase {
  final SocialRepository _repository;
  const DeleteSocialSessionUseCase(this._repository);

  Future<void> call(String id) => _repository.softDeleteSession(id);
}
