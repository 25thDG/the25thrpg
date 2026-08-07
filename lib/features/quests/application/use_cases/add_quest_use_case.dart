import '../../domain/entities/quest.dart';
import '../../domain/repositories/quest_repository.dart';

class AddQuestUseCase {
  final QuestRepository _repository;
  const AddQuestUseCase(this._repository);

  Future<Quest> call({
    required String title,
    String? description,
    required int xpReward,
    required QuestDifficulty difficulty,
    required List<QuestObjective> objectives,
  }) =>
      _repository.addQuest(
        title: title,
        description: description,
        xpReward: xpReward,
        difficulty: difficulty,
        objectives: objectives,
      );
}
