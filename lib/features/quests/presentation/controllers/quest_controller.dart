import 'package:flutter/foundation.dart';

import '../../application/use_cases/add_quest_use_case.dart';
import '../../application/use_cases/delete_quest_use_case.dart';
import '../../application/use_cases/get_quests_use_case.dart';
import '../../application/use_cases/update_quest_use_case.dart';
import '../../domain/entities/quest.dart';
import '../state/quest_state.dart';

class QuestController extends ChangeNotifier {
  final GetQuestsUseCase _getQuests;
  final AddQuestUseCase _addQuest;
  final UpdateQuestUseCase _updateQuest;
  final DeleteQuestUseCase _deleteQuest;

  QuestState _state = const QuestState();
  QuestState get state => _state;

  QuestController({
    required GetQuestsUseCase getQuests,
    required AddQuestUseCase addQuest,
    required UpdateQuestUseCase updateQuest,
    required DeleteQuestUseCase deleteQuest,
  })  : _getQuests = getQuests,
        _addQuest = addQuest,
        _updateQuest = updateQuest,
        _deleteQuest = deleteQuest;

  void _emit(QuestState s) {
    _state = s;
    notifyListeners();
  }

  Future<void> load() async {
    _emit(_state.copyWith(status: QuestLoadStatus.loading));
    try {
      final quests = await _getQuests();
      _emit(_state.copyWith(status: QuestLoadStatus.loaded, quests: quests));
    } catch (e) {
      _emit(_state.copyWith(
          status: QuestLoadStatus.error, errorMessage: e.toString()));
    }
  }

  Future<String?> addQuest({
    required String title,
    String? description,
    required int xpReward,
    required QuestDifficulty difficulty,
    required List<QuestObjective> objectives,
  }) async {
    _emit(_state.copyWith(isMutating: true));
    try {
      await _addQuest(
        title: title,
        description: description,
        xpReward: xpReward,
        difficulty: difficulty,
        objectives: objectives,
      );
      await load();
      return null;
    } catch (e) {
      _emit(_state.copyWith(isMutating: false));
      return e.toString();
    }
  }

  Future<String?> updateQuest(Quest quest) async {
    _emit(_state.copyWith(isMutating: true));
    try {
      await _updateQuest(
        id: quest.id,
        title: quest.title,
        description: quest.description,
        xpReward: quest.xpReward,
        difficulty: quest.difficulty,
        status: quest.status,
        objectives: quest.objectives,
        completedAt: quest.completedAt,
      );
      await load();
      return null;
    } catch (e) {
      _emit(_state.copyWith(isMutating: false));
      return e.toString();
    }
  }

  Future<String?> completeQuest(Quest quest) async {
    return updateQuest(quest.copyWith(
      status: QuestStatus.completed,
      completedAt: DateTime.now(),
    ));
  }

  Future<String?> reopenQuest(Quest quest) async {
    return updateQuest(quest.copyWith(
      status: QuestStatus.active,
      completedAt: null,
    ));
  }

  Future<String?> toggleObjective(Quest quest, String objectiveId) async {
    final updated = quest.objectives.map((o) {
      if (o.id == objectiveId) return o.copyWith(completed: !o.completed);
      return o;
    }).toList();
    return updateQuest(quest.copyWith(objectives: updated));
  }

  Future<String?> deleteQuest(String id) async {
    _emit(_state.copyWith(isMutating: true));
    try {
      await _deleteQuest(id);
      await load();
      return null;
    } catch (e) {
      _emit(_state.copyWith(isMutating: false));
      return e.toString();
    }
  }
}
