import 'package:flutter/material.dart';

import '../../domain/entities/social_stats.dart';
import 'section_card.dart';
import 'social_initiation_bar.dart';

class SocialLast30Section extends StatelessWidget {
  final SocialStats stats;

  const SocialLast30Section({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final min = stats.last30DaysMinutes;

    return SectionCard(
      title: 'Last 30 Days',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '$min',
                style: theme.textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'min',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SocialInitiationBar(
            selfPct: stats.last30DaysSelfInitiatedPercentage,
            selfMinutes: stats.last30DaysSelfInitiatedMinutes,
            otherMinutes:
                stats.last30DaysMinutes - stats.last30DaysSelfInitiatedMinutes,
          ),
        ],
      ),
    );
  }
}
