import '../../domain/entities/quest.dart';
import '../../domain/repositories/quest_repository.dart';

class UpdateQuestUseCase {
  final QuestRepository _repository;
  const UpdateQuestUseCase(this._repository);

  Future<Quest> call({
    required String id,
    required String title,
    String? description,
    required int xpReward,
    required QuestDifficulty difficulty,
    required QuestStatus status,
    required List<QuestObjective> objectives,
    DateTime? completedAt,
  }) =>
      _repository.updateQuest(
        id: id,
        title: title,
        description: description,
        xpReward: xpReward,
        difficulty: difficulty,
        status: status,
        objectives: objectives,
        completedAt: completedAt,
      );
}
