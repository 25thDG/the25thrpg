import 'package:flutter/material.dart';

import '../../domain/entities/wealth_stats.dart';
import 'section_card.dart';
import 'wealth_formatters.dart';

class WealthCurrentSection extends StatelessWidget {
  final WealthStats stats;

  const WealthCurrentSection({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SectionCard(
      title: 'Current Net Worth',
      child: stats.currentNetWorth == null
          ? Text(
              'No data yet. Log your first snapshot below.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fmtEur(stats.currentNetWorth!),
                  style: theme.textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'as of ${fmtMonth(stats.monthlyHistory.last.snapshotMonth)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
    );
  }
}
