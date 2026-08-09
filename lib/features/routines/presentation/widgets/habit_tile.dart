import 'package:flutter/material.dart';

import '../../../player/presentation/widgets/rpg_colors.dart';
import '../../domain/entities/foundation.dart';
import '../../domain/entities/habit.dart';
import 'foundation_style.dart';

/// One habit: a tick, its name, what the rule says about it, and its last week.
///
/// The whole row is the tap target — hunting for a small checkbox first thing in
/// the morning is exactly the friction that kills a routine.
class HabitTile extends StatelessWidget {
  final Habit habit;
  final DateTime today;
  final VoidCallback onToggle;
  final VoidCallback? onLongPress;

  const HabitTile({
    super.key,
    required this.habit,
    required this.today,
    required this.onToggle,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final status = habit.statusOn(today);
    final color = foundationColor(status.state);
    final done = status.state == FoundationState.solid;
    final alarming = status.state.isWarning || status.state.isBroken;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onToggle,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 4),
          child: Row(
            children: [
              _Tick(state: status.state),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      habit.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: done
                            ? RpgColors.textSecondary
                            : RpgColors.textPrimary,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.1,
                        decoration: done ? TextDecoration.lineThrough : null,
                        decorationColor:
                            RpgColors.textMuted.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      foundationCaption(status),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: alarming ? color : RpgColors.textMuted,
                        fontSize: 9.5,
                        fontWeight:
                            alarming ? FontWeight.w700 : FontWeight.w500,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              HabitStrip(habit: habit, today: today),
            ],
          ),
        ),
      ),
    );
  }
}

/// The state, as one 26px mark. Filled when kept, ringed otherwise, and the
/// ring carries the warning colour so a cracked habit reads without any text.
class _Tick extends StatelessWidget {
  final FoundationState state;

  const _Tick({required this.state});

  @override
  Widget build(BuildContext context) {
    final color = foundationColor(state);
    final filled = state == FoundationState.solid;
    final loud = state.isWarning || state.isBroken;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      // Not an overshooting curve. AnimatedContainer lerps the whole
      // decoration, and a t above 1 scales the outgoing BoxShadow by a negative
      // factor — which trips a "blur radius should be non-negative" assert the
      // moment a tick is cleared.
      curve: Curves.easeOutCubic,
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: filled ? color : color.withValues(alpha: loud ? 0.12 : 0.0),
        border: Border.all(
          color: filled ? color : color.withValues(alpha: loud ? 0.7 : 0.45),
          width: loud || filled ? 1.6 : 1.2,
        ),
        boxShadow: filled || loud
            ? [
                BoxShadow(
                  color: color.withValues(alpha: filled ? 0.5 : 0.25),
                  blurRadius: 10,
                ),
              ]
            : null,
      ),
      child: state == FoundationState.open
          ? null
          : Icon(
              foundationIcon(state),
              size: 15,
              color: filled ? RpgColors.pageBg : color,
            ),
    );
  }
}
