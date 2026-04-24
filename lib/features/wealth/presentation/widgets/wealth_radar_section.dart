import 'dart:math' show pi, min;

import 'package:flutter/material.dart';

import '../../../../core/theme/rpg_colors.dart';
import '../../domain/entities/wealth_stats.dart';

const _colorGold = Color(0xFFFFD54F);

class WealthRadarSection extends StatelessWidget {
  final WealthStats stats;

  const WealthRadarSection({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final pct = stats.radarProgress * 100;

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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: RpgColors.divider)),
            ),
            child: const Text(
              'PROGRESS TO €1,000,000',
              style: TextStyle(
                color: RpgColors.textMuted,
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 2.4,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: SizedBox(
                width: 160,
                height: 160,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: stats.radarProgress),
                  duration: const Duration(milliseconds: 1400),
                  curve: Curves.easeOutCubic,
                  builder: (_, v, _) => CustomPaint(
                    painter: _GaugePainter(progress: v),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${pct.toStringAsFixed(pct >= 10 ? 1 : 2)}%',
                            style: const TextStyle(
                              color: _colorGold,
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -1.0,
                            ),
                          ),
                          const Text(
                            'of €1M',
                            style: TextStyle(
                              color: RpgColors.textMuted,
                              fontSize: 11,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double progress;

  const _GaugePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 14;
    const startAngle = -pi * 0.75;
    const sweepAngle = pi * 1.5;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      Paint()
        ..color = _colorGold.withValues(alpha: 0.1)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 14
        ..strokeCap = StrokeCap.round,
    );

    if (progress > 0) {
      // Glow
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle * progress.clamp(0.0, 1.0),
        false,
        Paint()
          ..color = _colorGold.withValues(alpha: 0.2)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 22
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
      // Solid arc
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle * progress.clamp(0.0, 1.0),
        false,
        Paint()
          ..color = _colorGold
          ..style = PaintingStyle.stroke
          ..strokeWidth = 14
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_GaugePainter old) => old.progress != progress;
}
