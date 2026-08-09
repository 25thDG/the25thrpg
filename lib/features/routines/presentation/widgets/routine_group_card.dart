import 'package:flutter/material.dart';

import '../../../player/presentation/widgets/player_card.dart';
import '../../../player/presentation/widgets/rpg_colors.dart';
import '../../domain/entities/foundation.dart';
import '../../domain/entities/habit.dart';
import '../../domain/entities/routine.dart';
import 'foundation_style.dart';
import 'habit_tile.dart';

/// One routine — Morning, Day, Night — and everything inside it.
///
/// The card takes the colour of its worst habit, so a group with one broken
/// habit is visible from the top of the screen without opening anything.
class RoutineGroupCard extends StatelessWidget {
  final Routine routine;
  final DateTime today;
  final void Function(Habit) onToggle;
  final void Function(Habit) onEditHabit;
  final VoidCallback onAddHabit;
  final VoidCallback onEditRoutine;

  const RoutineGroupCard({
    super.key,
    required this.routine,
    required this.today,
    required this.onToggle,
    required this.onEditHabit,
    required this.onAddHabit,
    required this.onEditRoutine,
  });

  @override
  Widget build(BuildContext context) {
    final state = routine.stateOn(today);
    final color = foundationColor(state);
    final done = routine.doneCount(today);
    final total = routine.total;

    return PlayerCard(
      accent: color,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _PartChip(part: routine.partOfDay, color: color),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  routine.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: RpgColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
              Text(
                '$done/$total',
                style: TextStyle(
                  color: color,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(width: 2),
              IconButton(
                onPressed: onEditRoutine,
                icon: const Icon(Icons.more_horiz, size: 17),
                color: RpgColors.textMuted,
                visualDensity: VisualDensity.compact,
                tooltip: 'Edit routine',
              ),
            ],
          ),
          const SizedBox(height: 8),
          _Progress(value: routine.progress(today), color: color),
          const SizedBox(height: 6),
          Text(
            routineCaption(state, done, total),
            style: TextStyle(
              color: state.isWarning || state.isBroken
                  ? color
                  : RpgColors.textMuted,
              fontSize: 9.5,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 6),
          if (routine.habits.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Text(
                'No habits in here yet.',
                style: TextStyle(color: RpgColors.textMuted, fontSize: 12),
              ),
            )
          else
            for (final habit in routine.habits)
              HabitTile(
                key: ValueKey(habit.id),
                habit: habit,
                today: today,
                onToggle: () => onToggle(habit),
                onLongPress: () => onEditHabit(habit),
              ),
          const SizedBox(height: 2),
          _AddHabitButton(onTap: onAddHabit, color: color),
        ],
      ),
    );
  }
}

class _PartChip extends StatelessWidget {
  final PartOfDay part;
  final Color color;

  const _PartChip({required this.part, required this.color});

  IconData get _icon => switch (part) {
        PartOfDay.morning => Icons.wb_twilight,
        PartOfDay.day => Icons.wb_sunny_outlined,
        PartOfDay.night => Icons.nightlight_outlined,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.12),
        border: Border.all(color: color.withValues(alpha: 0.32)),
      ),
      child: Icon(_icon, size: 14, color: color),
    );
  }
}

class _Progress extends StatelessWidget {
  final double value;
  final Color color;

  const _Progress({required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(3),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: value.clamp(0.0, 1.0)),
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutCubic,
        builder: (_, v, _) => LinearProgressIndicator(
          value: v,
          minHeight: 4,
          backgroundColor: RpgColors.progressTrack,
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      ),
    );
  }
}

class _AddHabitButton extends StatelessWidget {
  final VoidCallback onTap;
  final Color color;

  const _AddHabitButton({required this.onTap, required this.color});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 4),
          child: Row(
            children: [
              Icon(Icons.add, size: 15, color: color.withValues(alpha: 0.75)),
              const SizedBox(width: 10),
              Text(
                'Add a habit',
                style: TextStyle(
                  color: color.withValues(alpha: 0.75),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
