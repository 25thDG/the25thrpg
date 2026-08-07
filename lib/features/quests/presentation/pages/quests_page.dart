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
import '../widgets/quest_hero_section.dart';

const _colorQuest = Color(0xFFF59E0B);

const _difficultyColors = {
  QuestDifficulty.side: Color(0xFF607D8B),
  QuestDifficulty.normal: Color(0xFFF59E0B),
  QuestDifficulty.epic: Color(0xFFAB47BC),
  QuestDifficulty.legendary: Color(0xFFEF5350),
};

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
        xpReward: result.xpReward,
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
        xpReward: result.xpReward,
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
      backgroundColor: RpgColors.pageBg,
      appBar: AppBar(
        backgroundColor: RpgColors.pageBg,
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

    return RefreshIndicator(
      color: _colorQuest,
      backgroundColor: RpgColors.panelBg,
      onRefresh: _controller.load,
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.only(top: 8, bottom: 32),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                QuestHeroSection(
                  activeQuests: state.activeQuests,
                  completedQuests: state.completedQuests,
                ),
                const SizedBox(height: 14),
                _ActiveQuestsPanel(
                  quests: state.activeQuests,
                  onAdd: _handleAdd,
                  onEdit: _handleEdit,
                  onComplete: _handleComplete,
                  onDelete: _handleDelete,
                  onClaimReward: _handleClaimReward,
                  onToggleObjective: _handleToggleObjective,
                ),
                if (state.completedQuests.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  _CompletedQuestsPanel(
                    quests: state.completedQuests,
                    onReopen: _handleReopen,
                    onDelete: _handleDelete,
                  ),
                ],
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Active quests panel ───────────────────────────────────────────────────────

class _ActiveQuestsPanel extends StatelessWidget {
  final List<Quest> quests;
  final VoidCallback onAdd;
  final Future<void> Function(Quest) onEdit;
  final Future<void> Function(Quest) onComplete;
  final Future<void> Function(Quest) onDelete;
  final Future<void> Function(Quest) onClaimReward;
  final Future<void> Function(Quest, String) onToggleObjective;

  const _ActiveQuestsPanel({
    required this.quests,
    required this.onAdd,
    required this.onEdit,
    required this.onComplete,
    required this.onDelete,
    required this.onClaimReward,
    required this.onToggleObjective,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: RpgColors.panelBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: RpgColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(
              border:
                  Border(bottom: BorderSide(color: RpgColors.divider)),
            ),
            child: Row(
              children: [
                const Text(
                  'ACTIVE QUESTS',
                  style: TextStyle(
                    color: RpgColors.textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 2.4,
                  ),
                ),
                const Spacer(),
                if (quests.isNotEmpty)
                  Text(
                    '${quests.length}',
                    style: const TextStyle(
                      color: _colorQuest,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...quests.map((q) => _ActiveQuestCard(
                      quest: q,
                      onTap: () => onEdit(q),
                      onComplete: () => onComplete(q),
                      onDelete: () => onDelete(q),
                      onClaimReward: () => onClaimReward(q),
                      onToggleObjective: (id) => onToggleObjective(q, id),
                    )),
                GestureDetector(
                  onTap: onAdd,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    decoration: BoxDecoration(
                      color: _colorQuest.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                          color: _colorQuest.withValues(alpha: 0.35)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add, color: _colorQuest, size: 15),
                        SizedBox(width: 6),
                        Text(
                          'NEW QUEST',
                          style: TextStyle(
                            color: _colorQuest,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActiveQuestCard extends StatefulWidget {
  final Quest quest;
  final VoidCallback onTap;
  final VoidCallback onComplete;
  final VoidCallback onDelete;
  final VoidCallback onClaimReward;
  final Future<void> Function(String objectiveId) onToggleObjective;

  const _ActiveQuestCard({
    required this.quest,
    required this.onTap,
    required this.onComplete,
    required this.onDelete,
    required this.onClaimReward,
    required this.onToggleObjective,
  });

  @override
  State<_ActiveQuestCard> createState() => _ActiveQuestCardState();
}

class _ActiveQuestCardState extends State<_ActiveQuestCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final q = widget.quest;
    final color = _difficultyColors[q.difficulty]!;
    final hasObjectives = q.objectives.isNotEmpty;
    final done = q.completedObjectives;
    final total = q.objectives.length;
    final progress = total > 0 ? done / total : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: RpgColors.panelBgAlt,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
            child: Padding(
              padding:
                  const EdgeInsets.fromLTRB(12, 10, 8, 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 3,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 5, vertical: 2),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: Text(
                                q.difficulty.displayName.toUpperCase(),
                                style: TextStyle(
                                  color: color,
                                  fontSize: 8,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 5, vertical: 2),
                              decoration: BoxDecoration(
                                color: _colorQuest.withValues(alpha: 0.10),
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: Text(
                                '${q.xpReward} XP',
                                style: const TextStyle(
                                  color: _colorQuest,
                                  fontSize: 8,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.6,
                                ),
                              ),
                            ),
                            if (q.daysLeft != null) ...[
                              const SizedBox(width: 6),
                              _DeadlineChip(quest: q),
                            ],
                          ],
                        ),
                        const SizedBox(height: 5),
                        Text(
                          q.title,
                          style: const TextStyle(
                            color: RpgColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (q.description != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            q.description!,
                            maxLines: _expanded ? null : 1,
                            overflow: _expanded
                                ? null
                                : TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: RpgColors.textMuted,
                              fontSize: 11,
                              height: 1.4,
                            ),
                          ),
                        ],
                        if (hasObjectives) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(2),
                                  child: LinearProgressIndicator(
                                    value: progress,
                                    backgroundColor: RpgColors.progressTrack,
                                    valueColor:
                                        AlwaysStoppedAnimation(color),
                                    minHeight: 3,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '$done / $total',
                                style: const TextStyle(
                                  color: RpgColors.textMuted,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ],
                        if (q.pace != QuestPace.unknown) ...[
                          const SizedBox(height: 6),
                          _PaceLine(quest: q),
                        ],
                        if (q.hasReward) ...[
                          const SizedBox(height: 8),
                          _RewardStrip(quest: q, onClaim: widget.onClaimReward),
                        ],
                      ],
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(
                            Icons.check_circle_outline,
                            size: 18),
                        color: _colorQuest,
                        onPressed: widget.onComplete,
                        visualDensity: VisualDensity.compact,
                        tooltip: 'Complete',
                      ),
                      IconButton(
                        icon:
                            const Icon(Icons.edit_outlined, size: 16),
                        color: RpgColors.textMuted,
                        onPressed: widget.onTap,
                        visualDensity: VisualDensity.compact,
                        tooltip: 'Edit',
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 16),
                        color: const Color(0xFFEF5350),
                        onPressed: widget.onDelete,
                        visualDensity: VisualDensity.compact,
                        tooltip: 'Delete',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (_expanded && hasObjectives) ...[
            Container(height: 1, color: RpgColors.divider),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
              child: Column(
                children: q.objectives.map((obj) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: GestureDetector(
                      onTap: () => widget.onToggleObjective(obj.id),
                      child: Row(
                        children: [
                          Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: obj.completed
                                  ? color.withValues(alpha: 0.2)
                                  : Colors.transparent,
                              border: Border.all(
                                color: obj.completed
                                    ? color
                                    : RpgColors.border,
                                width: obj.completed ? 1.5 : 1,
                              ),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: obj.completed
                                ? Icon(Icons.check,
                                    size: 10, color: color)
                                : null,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              obj.text,
                              style: TextStyle(
                                color: obj.completed
                                    ? RpgColors.textMuted
                                    : RpgColors.textSecondary,
                                fontSize: 12,
                                decoration: obj.completed
                                    ? TextDecoration.lineThrough
                                    : null,
                                decorationColor: RpgColors.textMuted,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Completed quests panel ────────────────────────────────────────────────────

class _CompletedQuestsPanel extends StatefulWidget {
  final List<Quest> quests;
  final Future<void> Function(Quest) onReopen;
  final Future<void> Function(Quest) onDelete;

  const _CompletedQuestsPanel({
    required this.quests,
    required this.onReopen,
    required this.onDelete,
  });

  @override
  State<_CompletedQuestsPanel> createState() => _CompletedQuestsPanelState();
}

class _CompletedQuestsPanelState extends State<_CompletedQuestsPanel> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: RpgColors.panelBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: RpgColors.border),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  const Text(
                    'COMPLETED',
                    style: TextStyle(
                      color: RpgColors.textMuted,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 2.4,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: RpgColors.panelBgAlt,
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Text(
                      '${widget.quests.length}',
                      style: const TextStyle(
                        color: RpgColors.textMuted,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: RpgColors.textMuted,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
          if (_expanded) ...[
            Container(height: 1, color: RpgColors.divider),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: widget.quests.map((q) {
                  final color = _difficultyColors[q.difficulty]!;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: RpgColors.panelBgAlt,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: RpgColors.border),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 3,
                          height: 30,
                          decoration: BoxDecoration(
                            color: RpgColors.border,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                q.title,
                                style: const TextStyle(
                                  color: RpgColors.textMuted,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  decoration:
                                      TextDecoration.lineThrough,
                                  decorationColor:
                                      RpgColors.textMuted,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '+${q.xpReward} XP  ·  ${q.difficulty.displayName}',
                                style: TextStyle(
                                  color: color.withValues(alpha: 0.6),
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.replay, size: 16),
                          color: RpgColors.textMuted,
                          onPressed: () => widget.onReopen(q),
                          visualDensity: VisualDensity.compact,
                          tooltip: 'Reopen',
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline,
                              size: 16),
                          color: const Color(0xFFEF5350),
                          onPressed: () => widget.onDelete(q),
                          visualDensity: VisualDensity.compact,
                          tooltip: 'Delete',
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Days remaining until the quest's target date, or how far past it we are.
class _DeadlineChip extends StatelessWidget {
  final Quest quest;

  const _DeadlineChip({required this.quest});

  @override
  Widget build(BuildContext context) {
    final left = quest.daysLeft!;
    final overdue = left < 0;
    final urgent = !overdue && left <= 14;
    final color = overdue
        ? const Color(0xFFEF5350)
        : (urgent ? _colorQuest : RpgColors.textMuted);

    final label = switch (left) {
      < 0 => '${-left}d OVER',
      0 => 'DUE TODAY',
      _ => '${_fmtDays(left)} LEFT',
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 8,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
        ),
      ),
    );
  }

  static String _fmtDays(int days) {
    if (days < 60) return '${days}d';
    if (days < 365) return '${(days / 30).round()}mo';
    return '${(days / 365).toStringAsFixed(1)}y';
  }
}

/// Milestone progress measured against time spent, so a quest that is quietly
/// falling behind says so instead of just showing a part-filled bar.
class _PaceLine extends StatelessWidget {
  final Quest quest;

  const _PaceLine({required this.quest});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (quest.pace) {
      QuestPace.onTrack => ('ON PACE', const Color(0xFF66BB6A)),
      QuestPace.behind => ('BEHIND PACE', _colorQuest),
      QuestPace.overdue => ('OVERDUE', const Color(0xFFEF5350)),
      QuestPace.unknown => ('', RpgColors.textMuted),
    };
    if (label.isEmpty) return const SizedBox.shrink();

    final elapsed = quest.timeElapsedFraction;
    final done = quest.objectiveFraction;

    return Row(
      children: [
        Icon(
          quest.pace == QuestPace.onTrack
              ? Icons.trending_up
              : Icons.trending_down,
          size: 11,
          color: color,
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
        ),
        if (elapsed != null && done != null) ...[
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              '${(done * 100).round()}% done · ${(elapsed * 100).round()}% of time used',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: RpgColors.textMuted,
                fontSize: 9,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// The real-world prize: locked while the quest is open, claimable once it is
/// done, and stamped once collected.
class _RewardStrip extends StatelessWidget {
  final Quest quest;
  final VoidCallback onClaim;

  const _RewardStrip({required this.quest, required this.onClaim});

  @override
  Widget build(BuildContext context) {
    final claimable = quest.isRewardClaimable;
    final claimed = quest.isRewardClaimed;
    final color = claimed
        ? RpgColors.textMuted
        : (claimable ? const Color(0xFF66BB6A) : _colorQuest);

    final cost = quest.rewardCostCents;
    final costLabel = cost == null ? null : '€${(cost / 100).round()}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: claimable ? 0.14 : 0.07),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(
            claimed
                ? Icons.check_circle
                : (claimable ? Icons.card_giftcard : Icons.lock_outline),
            size: 13,
            color: color,
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  quest.rewardText!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: claimed ? RpgColors.textMuted : RpgColors.textPrimary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    decoration: claimed ? TextDecoration.lineThrough : null,
                    decorationColor: RpgColors.textMuted,
                  ),
                ),
                Text(
                  claimed
                      ? 'CLAIMED'
                      : (claimable
                          ? 'READY TO CLAIM'
                          : 'LOCKED${costLabel == null ? '' : ' · $costLabel to plan for'}'),
                  style: TextStyle(
                    color: color,
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
          if (costLabel != null && !claimed) ...[
            const SizedBox(width: 6),
            Text(
              costLabel,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          if (claimable) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onClaim,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(color: color.withValues(alpha: 0.5)),
                ),
                child: Text(
                  'CLAIM',
                  style: TextStyle(
                    color: color,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
