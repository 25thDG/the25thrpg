import 'package:flutter/material.dart';

import '../../../../core/theme/rpg_colors.dart';
import '../../domain/entities/wealth_stats.dart';
import 'wealth_formatters.dart';

const _colorGold = Color(0xFFFFD54F);
const _target = 1_000_000.0;

class WealthMillionSection extends StatelessWidget {
  final WealthStats stats;

  const WealthMillionSection({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final current = stats.currentNetWorth;
    if (current == null || !stats.hasData) return const SizedBox.shrink();

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
              '€1M GOAL',
              style: TextStyle(
                color: RpgColors.textMuted,
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 2.4,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: _buildContent(current),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(double current) {
    if (current >= _target) return _buildReached();

    if (stats.monthlyHistory.length < 2) {
      return _buildNeedMoreData(current);
    }

    final avgMonthlyGrowth = _calcAvgMonthlyGrowth();
    if (avgMonthlyGrowth <= 0) {
      return _buildNotGrowing(current, avgMonthlyGrowth);
    }

    final monthsLeft = (_target - current) / avgMonthlyGrowth;
    final targetDate = _addMonths(DateTime.now(), monthsLeft.ceil());
    return _buildProjection(current, avgMonthlyGrowth, monthsLeft, targetDate);
  }

  Widget _buildReached() {
    return const Row(
      children: [
        Icon(Icons.emoji_events_rounded, color: _colorGold, size: 22),
        SizedBox(width: 10),
        Text(
          "You've reached €1,000,000!",
          style: TextStyle(
            color: _colorGold,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildNeedMoreData(double current) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _GoldBar(progress: current / _target),
        const SizedBox(height: 10),
        Text(
          '${fmtEur(_target - current)} remaining',
          style: const TextStyle(color: RpgColors.textSecondary, fontSize: 13),
        ),
        const SizedBox(height: 4),
        const Text(
          'Add more monthly snapshots to see your projected arrival date.',
          style: TextStyle(color: RpgColors.textMuted, fontSize: 11),
        ),
      ],
    );
  }

  Widget _buildNotGrowing(double current, double growth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _GoldBar(progress: current / _target),
        const SizedBox(height: 10),
        Text(
          '${fmtEur(_target - current)} remaining',
          style: const TextStyle(color: RpgColors.textSecondary, fontSize: 13),
        ),
        const SizedBox(height: 4),
        Text(
          growth == 0
              ? 'No growth detected yet — keep adding snapshots!'
              : 'Net worth is declining (${fmtEurCompact(growth)}/mo avg).',
          style: const TextStyle(color: Color(0xFFEF5350), fontSize: 11),
        ),
      ],
    );
  }

  Widget _buildProjection(
    double current,
    double avgMonthlyGrowth,
    double monthsLeft,
    DateTime targetDate,
  ) {
    final years = (monthsLeft / 12).floor();
    final months = monthsLeft.ceil() % 12;
    final timeStr = years > 0
        ? '$years yr${years > 1 ? 's' : ''}${months > 0 ? ' $months mo' : ''}'
        : '${monthsLeft.ceil()} mo';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _GoldBar(progress: current / _target),
        const SizedBox(height: 16),
        Row(
          children: [
            _StatChip(
              label: 'ESTIMATED',
              value: fmtMonth(targetDate),
              highlight: true,
            ),
            const SizedBox(width: 16),
            _StatChip(label: 'TIME LEFT', value: timeStr),
            const SizedBox(width: 16),
            _StatChip(
              label: 'AVG/MONTH',
              value:
                  '${avgMonthlyGrowth >= 0 ? '+' : ''}${fmtEurCompact(avgMonthlyGrowth)}',
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          '${fmtEur(_target - current)} remaining',
          style: const TextStyle(
            color: RpgColors.textMuted,
            fontSize: 11,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }

  double _calcAvgMonthlyGrowth() {
    final h = stats.monthlyHistory;
    final months = (h.last.snapshotMonth.year - h.first.snapshotMonth.year) *
            12 +
        (h.last.snapshotMonth.month - h.first.snapshotMonth.month);
    if (months == 0) return h.last.netWorthEur - h.first.netWorthEur;
    return (h.last.netWorthEur - h.first.netWorthEur) / months;
  }

  DateTime _addMonths(DateTime date, int months) {
    var m = date.month + months;
    final y = date.year + (m - 1) ~/ 12;
    m = ((m - 1) % 12) + 1;
    return DateTime(y, m, 1);
  }
}

class _GoldBar extends StatelessWidget {
  final double progress;
  const _GoldBar({required this.progress});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${(progress * 100).toStringAsFixed(1)}%',
              style: const TextStyle(
                color: _colorGold,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Text(
              '€1,000,000',
              style: TextStyle(color: RpgColors.textMuted, fontSize: 10),
            ),
          ],
        ),
        const SizedBox(height: 6),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: progress.clamp(0.0, 1.0)),
          duration: const Duration(milliseconds: 1200),
          curve: Curves.easeOutCubic,
          builder: (_, v, _) => ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: Stack(
              children: [
                Container(height: 6, color: RpgColors.progressTrack),
                FractionallySizedBox(
                  widthFactor: v,
                  child: Container(
                    height: 6,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [_colorGold, Color(0xFFFFEE58)],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;

  const _StatChip({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: RpgColors.textMuted,
            fontSize: 8,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.4,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(
            color: highlight ? _colorGold : RpgColors.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
      ],
    );
  }
}
