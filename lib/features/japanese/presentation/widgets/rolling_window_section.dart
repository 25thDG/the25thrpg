import 'package:flutter/material.dart';

import '../../domain/entities/japanese_stats.dart';
import 'section_card.dart';

class RollingWindowSection extends StatelessWidget {
  final JapaneseStats stats;

  const RollingWindowSection({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SectionCard(
      title: 'Activity Windows',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _WindowRow(
            label: 'Last 30 days — weighted',
            value: stats.last30DaysWeightedMinutes.round(),
            color: colorScheme.primary,
            theme: theme,
          ),
          const SizedBox(height: 6),
          _WindowRow(
            label: 'Last 30 days — raw',
            value: stats.last30DaysRawMinutes,
            color: colorScheme.secondary,
            theme: theme,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Divider(
              color: colorScheme.outlineVariant.withValues(alpha: 0.4),
              height: 1,
            ),
          ),
          _WindowRow(
            label: 'Best 30-day period — weighted',
            value: stats.best30DayWeightedMinutes.round(),
            color: colorScheme.tertiary,
            theme: theme,
            bold: true,
          ),
        ],
      ),
    );
  }
}

class _WindowRow extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  final ThemeData theme;
  final bool bold;

  const _WindowRow({
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
