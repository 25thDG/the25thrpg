import 'package:flutter/material.dart';

import '../../domain/entities/japanese_stats.dart';
import 'section_card.dart';

class LifetimeStatsSection extends StatelessWidget {
  final JapaneseStats stats;

  const LifetimeStatsSection({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final horizonHours = stats.currentHorizonHours;
    final lifeHours = stats.lifetimeHours;
    final progress = stats.progressToHorizon;
    final percent = stats.progressPercent;

    return SectionCard(
      title: 'Lifetime Progress',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                _formatHours(lifeHours),
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '/ ${_formatHoursInt(horizonHours)} hrs horizon',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.55),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _ProgressBar(value: progress, color: colorScheme.primary),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_formatMinutes(stats.lifetimeMinutes)} total minutes',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.55),
                ),
              ),
              Text(
                '${percent.toStringAsFixed(1)}%',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatHours(double h) {
    if (h >= 1000) return '${(h / 1000).toStringAsFixed(2)}k';
    return h.toStringAsFixed(1);
  }

  String _formatHoursInt(int h) {
    if (h >= 1000) return '${(h / 1000).toStringAsFixed(1)}k';
    return h.toString();
  }

  String _formatMinutes(int m) {
    if (m >= 1000000) return '${(m / 1000000).toStringAsFixed(2)}M';
    if (m >= 1000) return '${(m / 1000).toStringAsFixed(1)}k';
    return m.toString();
  }
}

class _ProgressBar extends StatelessWidget {
  final double value;
  final Color color;

  const _ProgressBar({required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 10,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: value.clamp(0.0, 1.0),
          child: Container(
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(5),
            ),
          ),
        ),
      ),
    );
  }
}
