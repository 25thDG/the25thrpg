import 'package:flutter/material.dart';

import '../../domain/entities/creation_stats.dart';
import 'section_card.dart';

class CreationRollingSection extends StatelessWidget {
  final CreationStats stats;

  const CreationRollingSection({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget buildStat(String label, String value) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      );
    }

    return SectionCard(
      title: 'Rolling Window',
      child: Row(
        children: [
          Expanded(
            child: buildStat(
              'Last 30 days',
              '${stats.last30DaysMinutes} min',
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: buildStat(
              'Best 30-day window',
              '${stats.best30DayMinutes} min',
            ),
          ),
        ],
      ),
    );
  }
}
