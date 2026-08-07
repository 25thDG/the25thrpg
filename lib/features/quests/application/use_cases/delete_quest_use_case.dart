import '../../domain/repositories/quest_repository.dart';

class DeleteQuestUseCase {
  final QuestRepository _repository;
  const DeleteQuestUseCase(this._repository);
  Future<void> call(String id) => _repository.deleteQuest(id);
}
