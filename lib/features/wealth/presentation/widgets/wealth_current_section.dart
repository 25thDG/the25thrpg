import 'package:flutter/material.dart';

import '../../../../core/theme/rpg_colors.dart';
import '../../domain/entities/wealth_stats.dart';
import 'wealth_formatters.dart';

const _colorGold = Color(0xFF10B981);

class WealthCurrentSection extends StatelessWidget {
  final WealthStats stats;

  const WealthCurrentSection({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final current = stats.currentNetWorth;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: RpgColors.panelBg,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: RpgColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Gold accent bar
          Container(
            height: 3,
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
              gradient: LinearGradient(
                colors: [_colorGold, Color(0xFF34D399)],
              ),
            ),
          ),
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: RpgColors.divider)),
            ),
            child: const Text(
              'CURRENT NET WORTH',
              style: TextStyle(
                color: RpgColors.textMuted,
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 2.4,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
            child: current == null
                ? const Text(
                    'No data yet. Log your first snapshot below.',
                    style: TextStyle(
                      color: RpgColors.textMuted,
                      fontSize: 13,
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: current),
                        duration: const Duration(milliseconds: 1200),
                        curve: Curves.easeOutCubic,
                        builder: (_, v, _) => Text(
                          fmtEur(v),
                          style: const TextStyle(
                            color: _colorGold,
                            fontSize: 36,
                            fontWeight: FontWeight.w800,
                            height: 1.0,
                            letterSpacing: -1.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'as of ${fmtMonth(stats.monthlyHistory.last.snapshotMonth)}',
                        style: const TextStyle(
                          color: RpgColors.textMuted,
                          fontSize: 11,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
