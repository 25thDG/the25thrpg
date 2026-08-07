import '../entities/quest.dart';

/// A quest as the user drafted it, before the database assigns an id.
class QuestDraft {
  final String title;
  final String? description;
  final int xpReward;
  final QuestDifficulty difficulty;
  final List<QuestObjective> objectives;
  final DateTime? targetDate;
  final String? rewardText;
  final int? rewardCostCents;

  const QuestDraft({
    required this.title,
    this.description,
    required this.xpReward,
    required this.difficulty,
    required this.objectives,
    this.targetDate,
    this.rewardText,
    this.rewardCostCents,
  });
}

abstract class QuestRepository {
  Future<List<Quest>> getQuests();
  Future<Quest> addQuest(QuestDraft draft);

  /// Persists [quest] wholesale — every mutable field is written, so callers
  /// build the new state with `copyWith` rather than passing a field list.
  Future<Quest> updateQuest(Quest quest);
  Future<void> deleteQuest(String id);
}
