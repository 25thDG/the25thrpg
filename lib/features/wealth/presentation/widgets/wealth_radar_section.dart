import 'dart:math' show pi, min;

import 'package:flutter/material.dart';

import '../../domain/entities/wealth_stats.dart';
import 'section_card.dart';

class WealthRadarSection extends StatelessWidget {
  final WealthStats stats;

  const WealthRadarSection({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Progress to €1,000,000',
      child: Center(
        child: _RadialGauge(
          progress: stats.radarProgress,
          percent: stats.radarProgress * 100,
        ),
      ),
    );
  }
}

class _RadialGauge extends StatelessWidget {
  final double progress;
  final double percent;

  const _RadialGauge({required this.progress, required this.percent});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    final theme = Theme.of(context);

    return SizedBox(
      width: 160,
      height: 160,
      child: CustomPaint(
        painter: _GaugePainter(progress: progress, color: color),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${percent.toStringAsFixed(percent >= 10 ? 1 : 2)}%',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
              Text(
                'of €1M',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double progress;
  final Color color;

  const _GaugePainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 14;

    // 270° arc starting at 7 o'clock (225° = -pi * 0.75 in radians).
    const startAngle = -pi * 0.75;
    const sweepAngle = pi * 1.5;

    // Background track.
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      Paint()
        ..color = color.withValues(alpha: 0.12)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 14
        ..strokeCap = StrokeCap.round,
    );

    // Progress arc — shrinks when net worth drops.
    if (progress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle * progress.clamp(0.0, 1.0),
        false,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 14
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_GaugePainter old) =>
      old.progress != progress || old.color != color;
}
