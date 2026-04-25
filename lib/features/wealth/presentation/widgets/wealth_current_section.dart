import 'package:flutter/material.dart';

import '../../../../core/theme/rpg_colors.dart';
import '../../domain/entities/wealth_snapshot.dart';
import '../../domain/entities/wealth_stats.dart';
import 'wealth_formatters.dart';

const _emerald = Color(0xFF10B981);
const _emeraldLight = Color(0xFF34D399);
const _decline = Color(0xFFEF5350);

class WealthCurrentSection extends StatelessWidget {
  final WealthStats stats;

  const WealthCurrentSection({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final current = stats.currentNetWorth;
    final history = stats.monthlyHistory;
    final delta = _monthDelta(history);
    final asOf = history.isNotEmpty ? fmtMonth(history.last.snapshotMonth) : '—';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: RpgColors.border),
        gradient: const RadialGradient(
          center: Alignment(1.0, -1.0),
          radius: 1.4,
          colors: [
            Color(0xFF173028),
            Color(0xFF101015),
            RpgColors.panelBg,
          ],
          stops: [0.0, 0.55, 1.0],
        ),
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
                  'NET WORTH',
                  style: TextStyle(
                    color: RpgColors.textSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2.4,
                  ),
                ),
                const Spacer(),
                Text(
                  asOf.toUpperCase(),
                  style: const TextStyle(
                    color: RpgColors.textMuted,
                    fontSize: 9,
                    letterSpacing: 1.6,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
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
                        duration: const Duration(milliseconds: 1400),
                        curve: Curves.easeOutCubic,
                        builder: (_, v, _) => Text(
                          fmtEur(v),
                          style: const TextStyle(
                            color: Color(0xFFF0FDF4),
                            fontSize: 44,
                            fontWeight: FontWeight.w800,
                            height: 1.0,
                            letterSpacing: -2.0,
                            shadows: [
                              Shadow(
                                color: Color(0x6610B981),
                                blurRadius: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _DeltaChip(delta: delta),
                    ],
                  ),
          ),
          if (history.length >= 2) ...[
            SizedBox(
              height: 44,
              width: double.infinity,
              child: CustomPaint(
                painter: _SparklinePainter(history: history),
              ),
            ),
            const SizedBox(height: 4),
          ],
        ],
      ),
    );
  }

  double? _monthDelta(List<WealthSnapshot> h) {
    if (h.length < 2) return null;
    return h.last.netWorthEur - h[h.length - 2].netWorthEur;
  }
}

class _DeltaChip extends StatelessWidget {
  final double? delta;
  const _DeltaChip({required this.delta});

  @override
  Widget build(BuildContext context) {
    if (delta == null) {
      return const Text(
        'First snapshot',
        style: TextStyle(
          color: RpgColors.textMuted,
          fontSize: 12,
          letterSpacing: 0.3,
        ),
      );
    }
    final positive = delta! >= 0;
    final color = positive ? _emerald : _decline;
    final icon = positive ? Icons.arrow_upward : Icons.arrow_downward;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 12),
          const SizedBox(width: 4),
          Text(
            '${positive ? '+' : ''}${fmtEurCompact(delta!)} this month',
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final List<WealthSnapshot> history;
  const _SparklinePainter({required this.history});

  @override
  void paint(Canvas canvas, Size size) {
    if (history.length < 2) return;
    final values = history.map((s) => s.netWorthEur).toList();
    final maxV = values.reduce((a, b) => a > b ? a : b);
    final minV = values.reduce((a, b) => a < b ? a : b);
    final range = maxV - minV;
    if (range == 0) return;

    final pad = 16.0;
    final w = size.width - pad * 2;
    final h = size.height - 8;

    final path = Path();
    final fillPath = Path();
    for (int i = 0; i < values.length; i++) {
      final x = pad + (w * i / (values.length - 1));
      final y = 4 + h - (h * (values[i] - minV) / range);
      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }
    fillPath.lineTo(pad + w, size.height);
    fillPath.close();

    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x4410B981), Color(0x0010B981)],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    canvas.drawPath(
      path,
      Paint()
        ..color = _emeraldLight
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..strokeCap = StrokeCap.round,
    );

    final lastX = pad + w;
    final lastY = 4 +
        h -
        (h * (values.last - minV) / range);
    canvas.drawCircle(
      Offset(lastX, lastY),
      4.5,
      Paint()
        ..color = _emerald.withValues(alpha: 0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    canvas.drawCircle(
      Offset(lastX, lastY),
      2.5,
      Paint()..color = _emeraldLight,
    );
  }

  @override
  bool shouldRepaint(_SparklinePainter old) =>
      old.history.length != history.length ||
      (history.isNotEmpty &&
          old.history.isNotEmpty &&
          old.history.last.netWorthEur != history.last.netWorthEur);
}

