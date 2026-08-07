import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/error/app_exception.dart';
import '../../domain/entities/quest.dart';
import '../../domain/repositories/quest_repository.dart';
import '../models/quest_model.dart';

const _userId = '1a67d50e-4263-4923-b4bc-1bfa57426aae';

class QuestSupabaseDatasource {
  final SupabaseClient _client;
  const QuestSupabaseDatasource(this._client);

  Future<List<QuestModel>> getQuests() async {
    try {
      final rows = await _client
          .from('quests')
          .select()
          .eq('user_id', _userId)
          .order('created_at', ascending: false);
      return (rows as List).map((r) => QuestModel.fromMap(r)).toList();
    } catch (e) {
      throw NetworkException('Failed to fetch quests: $e');
    }
  }

  Future<QuestModel> addQuest(QuestDraft draft) async {
    try {
      final model = QuestModel(
        id: '',
        title: draft.title,
        description: draft.description,
        xpReward: draft.xpReward,
        difficulty: draft.difficulty,
        status: QuestStatus.active,
        objectives: draft.objectives,
        createdAt: DateTime.now(),
        targetDate: draft.targetDate,
        rewardText: draft.rewardText,
        rewardCostCents: draft.rewardCostCents,
      );
      final row = await _client
          .from('quests')
          .insert(model.toInsertMap(_userId))
          .select()
          .single();
      return QuestModel.fromMap(row);
    } catch (e) {
      throw NetworkException('Failed to add quest: $e');
    }
  }

  Future<QuestModel> updateQuest(Quest quest) async {
    try {
      final model = QuestModel(
        id: quest.id,
        title: quest.title,
        description: quest.description,
        xpReward: quest.xpReward,
        difficulty: quest.difficulty,
        status: quest.status,
        objectives: quest.objectives,
        completedAt: quest.completedAt,
        createdAt: quest.createdAt,
        targetDate: quest.targetDate,
        rewardText: quest.rewardText,
        rewardCostCents: quest.rewardCostCents,
        rewardClaimedAt: quest.rewardClaimedAt,
      );
      final row = await _client
          .from('quests')
          .update(model.toUpdateMap())
          .eq('id', quest.id)
          .select()
          .single();
      return QuestModel.fromMap(row);
    } catch (e) {
      throw NetworkException('Failed to update quest: $e');
    }
  }

  Future<void> deleteQuest(String id) async {
    try {
      await _client.from('quests').delete().eq('id', id);
    } catch (e) {
      throw NetworkException('Failed to delete quest: $e');
    }
  }
}
