import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../player/presentation/widgets/player_card.dart';
import '../../../player/presentation/widgets/rpg_colors.dart';
import '../../application/use_cases/routine_use_cases.dart';
import '../../data/datasources/routine_supabase_datasource.dart';
import '../../data/repositories/routine_repository_impl.dart';
import '../../domain/entities/habit.dart';
import '../../domain/entities/routine.dart';
import '../controllers/routine_controller.dart';
import '../state/routine_state.dart';
import '../widgets/foundation_style.dart';
import '../widgets/routine_edit_sheets.dart';
import '../widgets/routine_group_card.dart';

/// The daily foundations.
///
/// Everything else in the app measures how much you did. This measures whether
/// you showed up at all — and applies the two-day rule, which is the only line
/// that matters: miss once and nothing happens, miss twice and a habit is on
/// its way out.
class RoutinesPage extends StatefulWidget {
  /// Owned by the shell, so the tab badge reads the same board this page draws.
  final RoutineController controller;

  const RoutinesPage({super.key, required this.controller});

  /// Builds the controller the shell holds. Keeps the wiring for this feature
  /// in the feature rather than in main.dart.
  static RoutineController createController() {
    final repository = RoutineRepositoryImpl(
      RoutineSupabaseDatasource(Supabase.instance.client),
    );
    return RoutineController(
      getBoard: GetRoutineBoardUseCase(repository),
      toggleHabit: ToggleHabitUseCase(repository),
      edit: EditRoutinesUseCase(repository),
    );
  }

  @override
  State<RoutinesPage> createState() => _RoutinesPageState();
}

class _RoutinesPageState extends State<RoutinesPage> {
  RoutineController get _controller => widget.controller;

  // ── Actions ────────────────────────────────────────────────────────────────

  Future<void> _toggle(Habit habit) async {
    try {
      await _controller.toggle(habit);
    } catch (_) {
      if (mounted) _complain('Could not save that. Check your connection.');
    }
  }

  Future<void> _addRoutine() async {
    final result = await showRoutineSheet(context);
    if (result == null || !mounted) return;
    await _guard(() => _controller.addRoutine(result.name, result.part));
  }

  Future<void> _editRoutine(Routine routine) async {
    final action = await showModalBottomSheet<_RoutineAction>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _RoutineMenu(routine: routine),
    );
    if (action == null || !mounted) return;

    switch (action) {
      case _RoutineAction.rename:
        final result = await showRoutineSheet(context, existing: routine);
        if (result == null || !mounted) return;
        await _guard(() => _controller.renameRoutine(routine.id, result.name));
      case _RoutineAction.delete:
        final yes = await confirmDelete(
          context,
          what: routine.name,
          detail: routine.habits.isEmpty
              ? 'This routine has no habits in it.'
              : 'Its ${routine.habits.length} habits go with it. '
                  'Nothing already recorded is deleted.',
        );
        if (!yes || !mounted) return;
        await _guard(() => _controller.deleteRoutine(routine.id));
    }
  }

  Future<void> _addHabit(Routine routine) async {
    final name = await showHabitSheet(context, routineName: routine.name);
    if (name == null || !mounted) return;
    await _guard(() => _controller.addHabit(routine, name));
  }

  Future<void> _editHabit(Routine routine, Habit habit) async {
    final action = await showModalBottomSheet<_HabitAction>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _HabitMenu(habit: habit, today: _controller.state.today),
    );
    if (action == null || !mounted) return;

    switch (action) {
      case _HabitAction.rename:
        final name = await showHabitSheet(
          context,
          existing: habit.name,
          routineName: routine.name,
        );
        if (name == null || !mounted) return;
        await _guard(() => _controller.renameHabit(habit.id, name));
      case _HabitAction.delete:
        final yes = await confirmDelete(
          context,
          what: habit.name,
          detail: 'The days already recorded stay in the database.',
        );
        if (!yes || !mounted) return;
        await _guard(() => _controller.deleteHabit(habit.id));
    }
  }

  Future<void> _guard(Future<void> Function() action) async {
    try {
      await action();
    } catch (e) {
      if (mounted) _complain(e.toString());
    }
  }

  void _complain(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, maxLines: 3),
        backgroundColor: FoundationColors.broken,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

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
          'FOUNDATIONS',
          style: TextStyle(
            color: RpgColors.textMuted,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 2.8,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _addRoutine,
            icon: const Icon(Icons.add, size: 20),
            color: RpgColors.textMuted,
            tooltip: 'New routine',
          ),
          ListenableBuilder(
            listenable: _controller,
            builder: (_, _) => _controller.state.isLoading
                ? const Padding(
                    padding: EdgeInsets.only(right: 16),
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.5,
                        color: RpgColors.textMuted,
                      ),
                    ),
                  )
                : IconButton(
                    onPressed: _controller.load,
                    icon: const Icon(Icons.refresh, size: 18),
                    color: RpgColors.textMuted,
                    tooltip: 'Refresh',
                  ),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) => _body(_controller.state),
      ),
    );
  }

  Widget _body(RoutineState state) {
    if (state.status == RoutineLoadStatus.initial ||
        (state.isLoading && state.board.isEmpty)) {
      return const Center(
        child: CircularProgressIndicator(
          color: FoundationColors.solid,
          strokeWidth: 1.5,
        ),
      );
    }

    if (state.status == RoutineLoadStatus.error && state.board.isEmpty) {
      return _ErrorView(state: state, onRetry: _controller.load);
    }

    final board = state.board;
    if (board.isEmpty) return _EmptyView(onAdd: _addRoutine);

    return RefreshIndicator(
      color: FoundationColors.solid,
      backgroundColor: RpgColors.panelBg,
      onRefresh: _controller.load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        children: [
          _TodayHeader(board: board, today: state.today),
          const SizedBox(height: 14),
          for (final routine in board.ordered)
            RoutineGroupCard(
              key: ValueKey(routine.id),
              routine: routine,
              today: state.today,
              onToggle: _toggle,
              onAddHabit: () => _addHabit(routine),
              onEditRoutine: () => _editRoutine(routine),
              onEditHabit: (habit) => _editHabit(routine, habit),
            ),
        ],
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

/// Today in one line, and — the important part — what is about to break.
class _TodayHeader extends StatelessWidget {
  final RoutineBoard board;
  final DateTime today;

  const _TodayHeader({required this.board, required this.today});

  @override
  Widget build(BuildContext context) {
    final done = board.doneToday(today);
    final total = board.totalHabits;
    final atRisk = board.atRisk(today);
    final broken = board.broken(today);

    final color = broken.isNotEmpty
        ? FoundationColors.broken
        : atRisk.isNotEmpty
            ? FoundationColors.cracked
            : FoundationColors.solid;

    return PlayerCard(
      accent: color,
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CardLabel('TODAY'),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$done',
                style: TextStyle(
                  color: color,
                  fontSize: 40,
                  fontWeight: FontWeight.w900,
                  height: 1.0,
                  letterSpacing: -1.6,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 4, left: 4),
                child: Text(
                  'of $total kept',
                  style: const TextStyle(
                    color: RpgColors.textMuted,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: board.progress(today)),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutCubic,
              builder: (_, v, _) => LinearProgressIndicator(
                value: v,
                minHeight: 6,
                backgroundColor: RpgColors.progressTrack,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ),
          if (atRisk.isNotEmpty || broken.isNotEmpty) ...[
            const SizedBox(height: 16),
            if (atRisk.isNotEmpty)
              _Alert(
                color: FoundationColors.cracked,
                icon: Icons.priority_high_rounded,
                text: atRisk.length == 1
                    ? '${atRisk.first.name} breaks tonight unless you do it today.'
                    : '${atRisk.length} habits break tonight unless you do them today.',
              ),
            if (broken.isNotEmpty)
              _Alert(
                color: FoundationColors.broken,
                icon: Icons.link_off_rounded,
                text: broken.length == 1
                    ? '${broken.first.name} is broken. Start it again today.'
                    : '${broken.length} habits are broken. Pick one and start again.',
              ),
          ],
        ],
      ),
    );
  }
}

class _Alert extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String text;

  const _Alert({required this.color, required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(12, 11, 13, 11),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: color,
                fontSize: 11.5,
                height: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Menus ─────────────────────────────────────────────────────────────────────

enum _RoutineAction { rename, delete }

enum _HabitAction { rename, delete }

class _RoutineMenu extends StatelessWidget {
  final Routine routine;

  const _RoutineMenu({required this.routine});

  @override
  Widget build(BuildContext context) {
    return _Menu(
      title: routine.name,
      subtitle: '${routine.partOfDay.displayName} · '
          '${routine.total} habit${routine.total == 1 ? '' : 's'}',
      items: [
        (
          Icons.edit_outlined,
          'Rename or move',
          () => Navigator.of(context).pop(_RoutineAction.rename),
          false,
        ),
        (
          Icons.delete_outline,
          'Remove routine',
          () => Navigator.of(context).pop(_RoutineAction.delete),
          true,
        ),
      ],
    );
  }
}

class _HabitMenu extends StatelessWidget {
  final Habit habit;
  final DateTime today;

  const _HabitMenu({required this.habit, required this.today});

  @override
  Widget build(BuildContext context) {
    final status = habit.statusOn(today);
    final rate = status.keepRate;

    return _Menu(
      title: habit.name,
      subtitle: [
        foundationCaption(status),
        if (status.longestStreak > 0) 'best ${status.longestStreak}d',
        if (rate != null) '${(rate * 100).round()}% kept',
      ].join(' · '),
      items: [
        (
          Icons.edit_outlined,
          'Rename',
          () => Navigator.of(context).pop(_HabitAction.rename),
          false,
        ),
        (
          Icons.delete_outline,
          'Remove habit',
          () => Navigator.of(context).pop(_HabitAction.delete),
          true,
        ),
      ],
    );
  }
}

class _Menu extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<(IconData, String, VoidCallback, bool)> items;

  const _Menu({
    required this.title,
    required this.subtitle,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: RpgColors.panelBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
        border: Border(top: BorderSide(color: RpgColors.border)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        14,
        20,
        16 + MediaQuery.of(context).padding.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 3,
              decoration: BoxDecoration(
                color: RpgColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            title,
            style: const TextStyle(
              color: RpgColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(color: RpgColors.textMuted, fontSize: 11),
          ),
          const SizedBox(height: 14),
          for (final (icon, label, onTap, danger) in items)
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  child: Row(
                    children: [
                      Icon(
                        icon,
                        size: 17,
                        color: danger
                            ? FoundationColors.broken
                            : RpgColors.textSecondary,
                      ),
                      const SizedBox(width: 14),
                      Text(
                        label,
                        style: TextStyle(
                          color: danger
                              ? FoundationColors.broken
                              : RpgColors.textPrimary,
                          fontSize: 13.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Empty and error ───────────────────────────────────────────────────────────

class _EmptyView extends StatelessWidget {
  final VoidCallback onAdd;

  const _EmptyView({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.foundation_outlined,
                size: 34, color: RpgColors.textMuted),
            const SizedBox(height: 18),
            const Text(
              'NO FOUNDATIONS YET',
              style: TextStyle(
                color: RpgColors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 2.2,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Make a routine for a part of your day, then put two or three '
              'small habits in it. Small enough that a bad day is no excuse.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: RpgColors.textMuted,
                fontSize: 12,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton(
              onPressed: onAdd,
              style: OutlinedButton.styleFrom(
                foregroundColor: FoundationColors.solid,
                side: BorderSide(
                  color: FoundationColors.solid.withValues(alpha: 0.4),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
              ),
              child: const Text(
                'NEW ROUTINE',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.6,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final RoutineState state;
  final VoidCallback onRetry;

  const _ErrorView({required this.state, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    // The one failure worth explaining properly: the tables are not there yet.
    final missing = state.isMissingSchema;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              missing ? 'TABLES NOT CREATED' : 'LOAD FAILED',
              style: const TextStyle(
                color: RpgColors.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 2.0,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              missing
                  ? 'Run db/migrations/0001_routines.sql in the Supabase SQL '
                      'editor, then pull to refresh.'
                  : (state.errorMessage ?? 'Unknown error.'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: RpgColors.textSecondary,
                fontSize: 12,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton(
              onPressed: onRetry,
              style: OutlinedButton.styleFrom(
                foregroundColor: FoundationColors.solid,
                side: const BorderSide(color: RpgColors.border),
              ),
              child: const Text('RETRY'),
            ),
          ],
        ),
      ),
    );
  }
}
