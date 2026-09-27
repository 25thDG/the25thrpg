import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/theme/rpg_colors.dart';
import '../../application/use_cases/add_quest_use_case.dart';
import '../../application/use_cases/delete_quest_use_case.dart';
import '../../application/use_cases/get_quests_use_case.dart';
import '../../application/use_cases/update_quest_use_case.dart';
import '../../data/datasources/quest_supabase_datasource.dart';
import '../../data/repositories/quest_repository_impl.dart';
import '../../domain/entities/quest.dart';
import '../../domain/repositories/quest_repository.dart';
import '../controllers/quest_controller.dart';
import '../state/quest_state.dart';
import '../widgets/quest_add_sheet.dart';
import '../widgets/quest_board.dart';

const _colorQuest = Color(0xFFF59E0B);

class QuestsPage extends StatefulWidget {
  const QuestsPage({super.key});

  @override
  State<QuestsPage> createState() => _QuestsPageState();
}

class _QuestsPageState extends State<QuestsPage> {
  late final QuestController _controller;

  @override
  void initState() {
    super.initState();
    final datasource = QuestSupabaseDatasource(Supabase.instance.client);
    final repository = QuestRepositoryImpl(datasource);
    _controller = QuestController(
      getQuests: GetQuestsUseCase(repository),
      addQuest: AddQuestUseCase(repository),
      updateQuest: UpdateQuestUseCase(repository),
      deleteQuest: DeleteQuestUseCase(repository),
    );
    _controller.load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleAdd() async {
    final result = await QuestAddSheet.show(context);
    if (result == null || !context.mounted) return;
    final error = await _controller.addQuest(
      QuestDraft(
        title: result.title,
        description: result.description,
        difficulty: result.difficulty,
        objectives: result.objectives,
        targetDate: result.targetDate,
        rewardText: result.rewardText,
        rewardCostCents: result.rewardCostCents,
      ),
    );
    if (error != null && context.mounted) _showError(error);
  }

  Future<void> _handleEdit(Quest quest) async {
    final result = await QuestAddSheet.show(context, existing: quest);
    if (result == null || !context.mounted) return;
    final error = await _controller.updateQuest(
      quest.copyWith(
        title: result.title,
        description: result.description,
        difficulty: result.difficulty,
        objectives: result.objectives,
        targetDate: result.targetDate,
        rewardText: result.rewardText,
        rewardCostCents: result.rewardCostCents,
      ),
    );
    if (error != null && context.mounted) _showError(error);
  }

  Future<void> _handleClaimReward(Quest quest) async {
    final error = await _controller.claimReward(quest);
    if (error != null && context.mounted) _showError(error);
  }

  Future<void> _handleComplete(Quest quest) async {
    final error = await _controller.completeQuest(quest);
    if (error != null && context.mounted) _showError(error);
  }

  Future<void> _handleReopen(Quest quest) async {
    final error = await _controller.reopenQuest(quest);
    if (error != null && context.mounted) _showError(error);
  }

  Future<void> _handleDelete(Quest quest) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: RpgColors.panelBg,
        title: const Text('Abandon quest?',
            style: TextStyle(color: RpgColors.textPrimary)),
        content: Text(
          '"${quest.title}" will be permanently removed.',
          style: const TextStyle(color: RpgColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel',
                style: TextStyle(color: RpgColors.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Abandon',
                style: TextStyle(color: Color(0xFFEF5350))),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final error = await _controller.deleteQuest(quest.id);
    if (error != null && context.mounted) _showError(error);
  }

  Future<void> _handleToggleObjective(Quest quest, String objectiveId) async {
    final error = await _controller.toggleObjective(quest, objectiveId);
    if (error != null && context.mounted) _showError(error);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(message),
          backgroundColor: const Color(0xFFEF5350)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: RpgColors.textSecondary,
        scrolledUnderElevation: 0,
        elevation: 0,
        title: const Text(
          'QUESTS',
          style: TextStyle(
            color: RpgColors.textMuted,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 2.8,
          ),
        ),
        centerTitle: false,
        actions: [
          ListenableBuilder(
            listenable: _controller,
            builder: (_, _) {
              if (_controller.state.isMutating ||
                  _controller.state.status == QuestLoadStatus.loading) {
                return const Padding(
                  padding: EdgeInsets.only(right: 16),
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      color: RpgColors.textMuted,
                    ),
                  ),
                );
              }
              return IconButton(
                icon: const Icon(Icons.refresh, size: 18),
                color: RpgColors.textMuted,
                onPressed: _controller.load,
                tooltip: 'Refresh',
              );
            },
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) => _buildBody(_controller.state),
      ),
    );
  }

  Widget _buildBody(QuestState state) {
    if (state.status == QuestLoadStatus.initial ||
        state.status == QuestLoadStatus.loading && state.quests.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(
          color: _colorQuest,
          strokeWidth: 1.5,
        ),
      );
    }

    if (state.status == QuestLoadStatus.error && state.quests.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'LOAD FAILED',
                style: TextStyle(
                  color: RpgColors.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 2.0,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                state.errorMessage ?? 'Unknown error.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: RpgColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 24),
              OutlinedButton(
                onPressed: _controller.load,
                style: OutlinedButton.styleFrom(
                  foregroundColor: _colorQuest,
                  side: const BorderSide(color: RpgColors.border),
                ),
                child: const Text('RETRY'),
              ),
            ],
          ),
        ),
      );
    }

    final active = state.activeQuests;
    final completed = state.completedQuests;

    return RefreshIndicator(
      color: _colorQuest,
      backgroundColor: RpgColors.panelBg,
      onRefresh: _controller.load,
      child: ListView(
        padding: const EdgeInsets.only(top: 8, bottom: 32),
        children: [
          QuestBoard(
            openCount: active.length,
            fulfilledCount: completed.length,
            children: [
              if (active.isEmpty) const EmptyBoardNote(),
              for (final q in active)
                QuestNotice(
                  quest: q,
                  onEdit: () => _handleEdit(q),
                  onComplete: () => _handleComplete(q),
                  onDelete: () => _handleDelete(q),
                  onToggleObjective: (id) => _handleToggleObjective(q, id),
                ),
              PostQuestSlip(onTap: _handleAdd),
              if (completed.isNotEmpty)
                FulfilledShelf(
                  quests: completed,
                  onReopen: _handleReopen,
                  onDelete: _handleDelete,
                  onClaimReward: _handleClaimReward,
                ),
            ],
          ),
        ],
      ),
    );
  }
}
