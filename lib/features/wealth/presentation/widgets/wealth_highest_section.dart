import 'package:flutter/material.dart';

import '../../../../core/theme/rpg_colors.dart';
import '../../domain/entities/wealth_stats.dart';
import 'wealth_formatters.dart';

class WealthHighestSection extends StatelessWidget {
  final WealthStats stats;

  const WealthHighestSection({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final high = stats.highestNetWorthEver;
    final current = stats.currentNetWorth;
    final isBelow =
        high != null && current != null && current < high;

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
          Container(
            width: double.infinity,
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(
              border:
                  Border(bottom: BorderSide(color: RpgColors.divider)),
            ),
            child: const Text(
              'ALL-TIME HIGH',
              style: TextStyle(
                color: RpgColors.textMuted,
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 2.4,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: high == null
                ? const Text(
                    '—',
                    style: TextStyle(
                      color: RpgColors.textMuted,
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                    ),
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        fmtEur(high),
                        style: const TextStyle(
                          color: RpgColors.textPrimary,
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -1.0,
                        ),
                      ),
                      if (isBelow) ...[
                        const SizedBox(width: 10),
                        Text(
                          '▼ ${fmtEur(high - current)} below peak',
                          style: const TextStyle(
                            color: Color(0xFFEF5350),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
