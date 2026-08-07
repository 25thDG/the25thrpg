import '../../domain/entities/quest.dart';
import '../../domain/repositories/quest_repository.dart';

class AddQuestUseCase {
  final QuestRepository _repository;
  const AddQuestUseCase(this._repository);

  Future<Quest> call(QuestDraft draft) => _repository.addQuest(draft);
}
