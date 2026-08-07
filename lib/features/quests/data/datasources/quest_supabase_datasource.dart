import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/error/app_exception.dart';
import '../../domain/entities/quest.dart';
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

  Future<QuestModel> addQuest({
    required String title,
    String? description,
    required int xpReward,
    required QuestDifficulty difficulty,
    required List<QuestObjective> objectives,
  }) async {
    try {
      final model = QuestModel(
        id: '',
        title: title,
        description: description,
        xpReward: xpReward,
        difficulty: difficulty,
        status: QuestStatus.active,
        objectives: objectives,
        createdAt: DateTime.now(),
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

  Future<QuestModel> updateQuest({
    required String id,
    required String title,
    String? description,
    required int xpReward,
    required QuestDifficulty difficulty,
    required QuestStatus status,
    required List<QuestObjective> objectives,
    DateTime? completedAt,
  }) async {
    try {
      final model = QuestModel(
        id: id,
        title: title,
        description: description,
        xpReward: xpReward,
        difficulty: difficulty,
        status: status,
        objectives: objectives,
        completedAt: completedAt,
        createdAt: DateTime.now(),
      );
      final row = await _client
          .from('quests')
          .update(model.toUpdateMap())
          .eq('id', id)
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
