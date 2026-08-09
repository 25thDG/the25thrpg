import 'package:flutter/material.dart';

import '../../../player/presentation/widgets/rpg_colors.dart';
import '../../domain/entities/foundation.dart';
import '../../domain/entities/habit.dart';

/// One colour per state of the two-day rule, so the same verdict looks the same
/// everywhere on the screen.
abstract final class FoundationColors {
  /// Kept today.
  static const solid = Color(0xFF66BB6A);

  /// Untouched, but the day is still young.
  static const open = Color(0xFF55555E);

  /// One day missed. Amber, because this is a warning and not yet a failure.
  static const cracked = Color(0xFFF59E0B);

  /// Two or more in a row.
  static const broken = Color(0xFFEF5350);
}

Color foundationColor(FoundationState state) => switch (state) {
      FoundationState.solid => FoundationColors.solid,
      FoundationState.open => FoundationColors.open,
      FoundationState.cracked => FoundationColors.cracked,
      FoundationState.broken => FoundationColors.broken,
    };

IconData foundationIcon(FoundationState state) => switch (state) {
      FoundationState.solid => Icons.check_rounded,
      FoundationState.open => Icons.circle_outlined,
      FoundationState.cracked => Icons.priority_high_rounded,
      FoundationState.broken => Icons.close_rounded,
    };

/// The line under a habit's name — what the rule has to say about it.
String foundationCaption(FoundationStatus s) => switch (s.state) {
      FoundationState.solid => s.streak > 1
          ? '${s.streak} days running'
          : 'kept today',
      FoundationState.open =>
        s.streak > 0 ? '${s.streak} days running · not yet today' : 'not yet today',
      FoundationState.cracked => 'missed yesterday · last chance today',
      FoundationState.broken => 'broken · ${s.missedInARow} days missed',
    };

/// The same verdict, phrased for a whole routine.
String routineCaption(FoundationState state, int done, int total) =>
    switch (state) {
      FoundationState.broken => 'something has come apart here',
      FoundationState.cracked => 'breaks tonight unless you act',
      _ when total > 0 && done == total => 'all kept',
      _ => '$done of $total kept today',
    };

/// A habit's last few days as pips — today last.
class HabitStrip extends StatelessWidget {
  final Habit habit;
  final DateTime today;
  final int days;

  const HabitStrip({
    super.key,
    required this.habit,
    required this.today,
    this.days = 7,
  });

  @override
  Widget build(BuildContext context) {
    final strip = habit.recentDays(days, today);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final (i, kept) in strip.indexed) ...[
          if (i > 0) const SizedBox(width: 3),
          Container(
            width: 5,
            height: i == strip.length - 1 ? 14 : 10,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(3),
              color: switch (kept) {
                // Before the habit existed — not a miss, just not applicable.
                null => RpgColors.progressTrack.withValues(alpha: 0.4),
                true => FoundationColors.solid,
                false => FoundationColors.broken.withValues(alpha: 0.55),
              },
            ),
          ),
        ],
      ],
    );
  }
}
