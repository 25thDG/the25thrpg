import '../../domain/entities/quest.dart';
import '../../domain/repositories/quest_repository.dart';
import '../datasources/quest_supabase_datasource.dart';

class QuestRepositoryImpl implements QuestRepository {
  final QuestSupabaseDatasource _datasource;
  const QuestRepositoryImpl(this._datasource);

  @override
  Future<List<Quest>> getQuests() => _datasource.getQuests();

  @override
  Future<Quest> addQuest({
    required String title,
    String? description,
    required int xpReward,
    required QuestDifficulty difficulty,
    required List<QuestObjective> objectives,
  }) =>
      _datasource.addQuest(
        title: title,
        description: description,
        xpReward: xpReward,
        difficulty: difficulty,
        objectives: objectives,
      );

  @override
  Future<Quest> updateQuest({
    required String id,
    required String title,
    String? description,
    required int xpReward,
    required QuestDifficulty difficulty,
    required QuestStatus status,
    required List<QuestObjective> objectives,
    DateTime? completedAt,
  }) =>
      _datasource.updateQuest(
        id: id,
        title: title,
        description: description,
        xpReward: xpReward,
        difficulty: difficulty,
        status: status,
        objectives: objectives,
        completedAt: completedAt,
      );

  @override
  Future<void> deleteQuest(String id) => _datasource.deleteQuest(id);
}
