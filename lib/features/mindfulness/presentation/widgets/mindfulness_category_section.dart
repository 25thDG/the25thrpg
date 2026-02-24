import 'package:flutter/material.dart';

import '../../domain/entities/mindfulness_session.dart';
import '../../domain/entities/mindfulness_stats.dart';
import 'section_card.dart';

const _categoryColors = {
  MindfulnessCategory.meditation: Color(0xFF26A69A), // teal
  MindfulnessCategory.journaling: Color(0xFFFFA726),  // amber
  MindfulnessCategory.walking: Color(0xFF66BB6A),     // green
  MindfulnessCategory.nonfiction: Color(0xFF5C6BC0),  // indigo
};

class MindfulnessCategorySection extends StatelessWidget {
  final MindfulnessStats stats;

  const MindfulnessCategorySection({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Category Breakdown',
      child: Column(
        children: MindfulnessCategory.values.map((category) {
          final data = stats.categoryBreakdown[category];
          if (data == null) return const SizedBox.shrink();
          return _CategoryRow(stats: data);
        }).toList(),
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  final MindfulnessCategoryStats stats;

  const _CategoryRow({required this.stats});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color =
        _categoryColors[stats.category] ?? theme.colorScheme.primary;
    final pct = (stats.percentage / 100).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    stats.category.displayName,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              Row(
                children: [
                  Text(
                    '${stats.percentage.toStringAsFixed(1)}%',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _fmtMin(stats.totalMinutes),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 5),
          Container(
            height: 6,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(3),
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: pct,
                child: Container(
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _fmtMin(int m) {
    if (m >= 1000) return '${(m / 1000).toStringAsFixed(1)}k min';
    return '$m min';
  }
}
