import 'dart:math' show pi, min;

import 'package:flutter/material.dart';

import '../../../../core/theme/rpg_colors.dart';
import '../../domain/entities/wealth_stats.dart';
import 'wealth_formatters.dart';

const _emerald = Color(0xFF10B981);
const _emeraldLight = Color(0xFF34D399);
const _decline = Color(0xFFEF5350);
const _target = 1_000_000.0;

class WealthMillionSection extends StatelessWidget {
  final WealthStats stats;

  const WealthMillionSection({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final current = stats.currentNetWorth;
    if (current == null || !stats.hasData) return const SizedBox.shrink();

    final pct = (current / _target).clamp(0.0, 1.0);
    final reached = current >= _target;
    final avgGrowth =
        stats.monthlyHistory.length >= 2 ? _calcAvgMonthlyGrowth(stats) : 0.0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: RpgColors.panelBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: RpgColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
            child: Row(
              children: [
                Container(width: 6, height: 6, color: _emerald),
                const SizedBox(width: 8),
                const Text(
                  '€1M GOAL',
                  style: TextStyle(
                    color: RpgColors.textSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2.4,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: reached
                ? _buildReached()
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 130,
                        height: 130,
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.0, end: pct),
                          duration: const Duration(milliseconds: 1400),
                          curve: Curves.easeOutCubic,
                          builder: (_, v, _) => CustomPaint(
                            painter: _RingPainter(progress: v),
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '${(v * 100).toStringAsFixed(v >= 0.1 ? 1 : 2)}%',
                                    style: const TextStyle(
                                      color: _emeraldLight,
                                      fontSize: 24,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -1.0,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  const Text(
                                    'OF €1M',
                                    style: TextStyle(
                                      color: RpgColors.textMuted,
                                      fontSize: 9,
                                      letterSpacing: 1.6,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(child: _projectionPanel(current, avgGrowth)),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildReached() {
    return Row(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: _emerald.withValues(alpha: 0.15),
            shape: BoxShape.circle,
            border: Border.all(color: _emerald, width: 2),
          ),
          child: const Icon(Icons.emoji_events_rounded, color: _emerald, size: 30),
        ),
        const SizedBox(width: 16),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '€1,000,000 reached',
                style: TextStyle(
                  color: _emeraldLight,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Goal achieved.',
                style: TextStyle(
                  color: RpgColors.textMuted,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _projectionPanel(double current, double avgGrowth) {
    final remaining = _target - current;

    if (stats.monthlyHistory.length < 2) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ESTIMATED ARRIVAL',
            style: TextStyle(
              color: RpgColors.textMuted,
              fontSize: 9,
              letterSpacing: 1.6,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            '—',
            style: TextStyle(
              color: RpgColors.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${fmtEur(remaining)} to go',
            style: const TextStyle(
              color: RpgColors.textMuted,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Add more snapshots for projection.',
            style: TextStyle(color: RpgColors.textMuted, fontSize: 10),
          ),
        ],
      );
    }

    if (avgGrowth <= 0) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ESTIMATED ARRIVAL',
            style: TextStyle(
              color: RpgColors.textMuted,
              fontSize: 9,
              letterSpacing: 1.6,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Stalled',
            style: TextStyle(
              color: _decline,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            avgGrowth == 0
                ? 'No growth yet — keep logging.'
                : 'Trending down (${fmtEurCompact(avgGrowth)}/mo).',
            style: const TextStyle(color: _decline, fontSize: 11),
          ),
        ],
      );
    }

    final monthsLeft = remaining / avgGrowth;
    final targetDate = _addMonths(DateTime.now(), monthsLeft.ceil());
    final years = (monthsLeft / 12).floor();
    final months = monthsLeft.ceil() % 12;
    final timeStr = years > 0
        ? '$years yr${years > 1 ? 's' : ''}${months > 0 ? ' $months mo' : ''}'
        : '${monthsLeft.ceil()} mo';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ESTIMATED ARRIVAL',
          style: TextStyle(
            color: RpgColors.textMuted,
            fontSize: 9,
            letterSpacing: 1.6,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          fmtMonth(targetDate),
          style: const TextStyle(
            color: _emeraldLight,
            fontSize: 22,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.6,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '$timeStr left',
          style: const TextStyle(
            color: RpgColors.textPrimary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            const Icon(Icons.trending_up, color: _emerald, size: 12),
            const SizedBox(width: 4),
            Text(
              '+${fmtEurCompact(avgGrowth)}/mo avg',
              style: const TextStyle(
                color: _emerald,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  double _calcAvgMonthlyGrowth(WealthStats stats) {
    final h = stats.monthlyHistory;
    final months =
        (h.last.snapshotMonth.year - h.first.snapshotMonth.year) * 12 +
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

class _RingPainter extends CustomPainter {
  final double progress;
  const _RingPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 10;
    const startAngle = -pi / 2;
    const sweepAngle = 2 * pi;

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = _emerald.withValues(alpha: 0.08)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 9,
    );

    if (progress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle * progress,
        false,
        Paint()
          ..color = _emerald.withValues(alpha: 0.25)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 16
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle * progress,
        false,
        Paint()
          ..shader = const SweepGradient(
            startAngle: -pi / 2,
            colors: [_emerald, _emeraldLight, _emerald],
          ).createShader(Rect.fromCircle(center: center, radius: radius))
          ..style = PaintingStyle.stroke
          ..strokeWidth = 9
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress;
}
