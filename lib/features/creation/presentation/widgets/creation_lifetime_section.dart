import 'package:flutter/material.dart';

import '../../domain/entities/creation_stats.dart';
import 'section_card.dart';

class CreationLifetimeSection extends StatelessWidget {
  final CreationStats stats;

  const CreationLifetimeSection({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hours = stats.lifetimeHours;
    final hDisplay = hours.toStringAsFixed(1);

    return SectionCard(
      title: 'Lifetime',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(
            hDisplay,
            style: theme.textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            'hours',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
            ),
          ),
        ],
      ),
    );
  }
}
