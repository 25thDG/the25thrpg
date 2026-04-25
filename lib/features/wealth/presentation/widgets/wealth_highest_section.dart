import 'package:flutter/material.dart';

import '../../../../core/theme/rpg_colors.dart';
import '../../domain/entities/wealth_stats.dart';
import 'wealth_formatters.dart';

const _emerald = Color(0xFF10B981);
const _decline = Color(0xFFEF5350);

class WealthHighestSection extends StatelessWidget {
  final WealthStats stats;

  const WealthHighestSection({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final high = stats.highestNetWorthEver;
    final current = stats.currentNetWorth;
    final history = stats.monthlyHistory;
    final months = history.length;

    double? totalGrowth;
    if (history.length >= 2) {
      totalGrowth = history.last.netWorthEur - history.first.netWorthEur;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: RpgColors.panelBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: RpgColors.border),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Expanded(
              child: _Stat(
                label: 'ALL-TIME HIGH',
                value: high != null ? fmtEurCompact(high) : '—',
                sub: _peakSub(current, high),
                color: _peakSubColor(current, high),
              ),
            ),
            const _VDivider(),
            Expanded(
              child: _Stat(
                label: 'TOTAL GROWTH',
                value: totalGrowth != null ? _signed(totalGrowth) : '—',
                sub: months >= 2 ? 'since ${fmtMonth(history.first.snapshotMonth)}' : '',
                color: totalGrowth != null && totalGrowth >= 0
                    ? _emerald
                    : (totalGrowth != null ? _decline : RpgColors.textMuted),
              ),
            ),
            const _VDivider(),
            Expanded(
              child: _Stat(
                label: 'MONTHS LOGGED',
                value: '$months',
                sub: months == 1 ? 'snapshot' : 'snapshots',
                color: RpgColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _peakSub(double? current, double? high) {
    if (current == null || high == null) return '';
    if (current >= high) return 'at peak';
    return '${fmtEurCompact(high - current)} below';
  }

  Color _peakSubColor(double? current, double? high) {
    if (current == null || high == null) return RpgColors.textPrimary;
    return current >= high ? _emerald : RpgColors.textPrimary;
  }

  String _signed(double v) =>
      '${v >= 0 ? '+' : ''}${fmtEurCompact(v)}';
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final String sub;
  final Color color;

  const _Stat({
    required this.label,
    required this.value,
    required this.sub,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: RpgColors.textMuted,
              fontSize: 9,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.6,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.6,
            ),
          ),
          if (sub.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              sub,
              style: const TextStyle(
                color: RpgColors.textMuted,
                fontSize: 10,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _VDivider extends StatelessWidget {
  const _VDivider();
  @override
  Widget build(BuildContext context) =>
      Container(width: 1, color: RpgColors.divider);
}
