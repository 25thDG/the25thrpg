import '../entities/quest.dart';

abstract class QuestRepository {
  Future<List<Quest>> getQuests();
  Future<Quest> addQuest({
    required String title,
    String? description,
    required int xpReward,
    required QuestDifficulty difficulty,
    required List<QuestObjective> objectives,
  });
  Future<Quest> updateQuest({
    required String id,
    required String title,
    String? description,
    required int xpReward,
    required QuestDifficulty difficulty,
    required QuestStatus status,
    required List<QuestObjective> objectives,
    DateTime? completedAt,
  });
  Future<void> deleteQuest(String id);
}
