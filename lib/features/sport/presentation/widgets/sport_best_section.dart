import 'package:flutter/material.dart';

import '../../domain/entities/sport_stats.dart';
import 'section_card.dart';

class SportBestSection extends StatelessWidget {
  final SportStats stats;

  const SportBestSection({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final min = stats.best30DayMinutes;

    return SectionCard(
      title: 'Best 30-Day Period',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(
            min > 0 ? '$min' : '-',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: min > 0
                  ? theme.colorScheme.onSurface
                  : theme.colorScheme.onSurface.withValues(alpha: 0.3),
            ),
          ),
          if (min > 0) ...[
            const SizedBox(width: 6),
            Text(
              'min',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
