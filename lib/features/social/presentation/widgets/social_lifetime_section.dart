import 'package:flutter/material.dart';

import '../../domain/entities/social_stats.dart';
import 'section_card.dart';
import 'social_initiation_bar.dart';

class SocialLifetimeSection extends StatelessWidget {
  final SocialStats stats;

  const SocialLifetimeSection({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hours = stats.lifetimeHours.toStringAsFixed(1);

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
                hours,
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
          const SizedBox(height: 16),
          SocialInitiationBar(
            selfPct: stats.lifetimeSelfInitiatedPercentage,
            selfMinutes: stats.lifetimeSelfInitiatedMinutes,
            otherMinutes: stats.lifetimeOtherInitiatedMinutes,
          ),
        ],
      ),
    );
  }
}
