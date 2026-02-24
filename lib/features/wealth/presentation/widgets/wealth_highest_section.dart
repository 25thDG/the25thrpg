import 'package:flutter/material.dart';

import '../../domain/entities/wealth_stats.dart';
import 'section_card.dart';
import 'wealth_formatters.dart';

class WealthHighestSection extends StatelessWidget {
  final WealthStats stats;

  const WealthHighestSection({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SectionCard(
      title: 'All-Time High',
      child: stats.highestNetWorthEver == null
          ? Text(
              '—',
              style: theme.textTheme.headlineMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
              ),
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  fmtEur(stats.highestNetWorthEver!),
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                // Indicator when current < all-time high (net worth has dropped).
                if (stats.currentNetWorth != null &&
                    stats.currentNetWorth! < stats.highestNetWorthEver!) ...[
                  const SizedBox(width: 8),
                  Text(
                    '▼ ${fmtEur(stats.highestNetWorthEver! - stats.currentNetWorth!)} below',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                ],
              ],
            ),
    );
  }
}
