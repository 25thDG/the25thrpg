import '../../domain/entities/quest.dart';
import '../../domain/repositories/quest_repository.dart';
import '../datasources/quest_supabase_datasource.dart';

class QuestRepositoryImpl implements QuestRepository {
  final QuestSupabaseDatasource _datasource;
  const QuestRepositoryImpl(this._datasource);

  @override
  Future<List<Quest>> getQuests() => _datasource.getQuests();

  @override
  Future<Quest> addQuest(QuestDraft draft) => _datasource.addQuest(draft);

  @override
  Future<Quest> updateQuest(Quest quest) => _datasource.updateQuest(quest);

  @override
  Future<void> deleteQuest(String id) => _datasource.deleteQuest(id);
}
