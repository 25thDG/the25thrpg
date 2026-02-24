import 'package:flutter/material.dart';

import '../../domain/entities/mindfulness_stats.dart';
import 'section_card.dart';

class MindfulnessRollingSection extends StatelessWidget {
  final MindfulnessStats stats;

  const MindfulnessRollingSection({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SectionCard(
      title: 'Activity Windows',
      child: Column(
        children: [
          _Row(
            label: 'Last 30 days',
            value: stats.last30DaysMinutes,
            color: colorScheme.primary,
            theme: theme,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Divider(
              color: colorScheme.outlineVariant.withValues(alpha: 0.4),
              height: 1,
            ),
          ),
          _Row(
            label: 'Best 30-day period',
            value: stats.best30DayMinutes,
            color: colorScheme.tertiary,
            theme: theme,
            bold: true,
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  final ThemeData theme;
  final bool bold;

  const _Row({
    required this.label,
    required this.value,
    required this.color,
    required this.theme,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
          ),
        ),
        Text(
          _fmt(value),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: color,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ],
    );
  }

  String _fmt(int m) {
    if (m >= 1000) return '${(m / 1000).toStringAsFixed(1)}k min';
    return '$m min';
  }
}
