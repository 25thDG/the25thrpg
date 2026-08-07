import '../../domain/entities/quest.dart';
import '../../domain/repositories/quest_repository.dart';

class UpdateQuestUseCase {
  final QuestRepository _repository;
  const UpdateQuestUseCase(this._repository);

  Future<Quest> call(Quest quest) => _repository.updateQuest(quest);
}
