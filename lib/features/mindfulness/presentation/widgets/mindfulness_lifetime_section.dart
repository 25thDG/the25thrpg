import 'package:flutter/material.dart';

import '../../domain/entities/mindfulness_stats.dart';
import 'section_card.dart';

class MindfulnessLifetimeSection extends StatelessWidget {
  final MindfulnessStats stats;

  const MindfulnessLifetimeSection({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SectionCard(
      title: 'Lifetime',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                _formatHours(stats.lifetimeHours),
                style: theme.textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'hrs',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.55),
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${_formatMinutes(stats.lifetimeMinutes)} minutes total',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  String _formatHours(double h) {
    if (h >= 1000) return '${(h / 1000).toStringAsFixed(2)}k';
    return h.toStringAsFixed(1);
  }

  String _formatMinutes(int m) {
    if (m >= 1000000) return '${(m / 1000000).toStringAsFixed(2)}M';
    if (m >= 1000) return '${(m / 1000).toStringAsFixed(1)}k';
    return m.toString();
  }
}
