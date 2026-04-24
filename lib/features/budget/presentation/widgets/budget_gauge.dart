import 'dart:math';
import 'package:flutter/material.dart';

import '../../../../core/theme/rpg_colors.dart';
import '../../domain/entities/budget_summary.dart';

const _safe = Color(0xFF26A69A);
const _warn = Color(0xFFFF7043);
const _over = Color(0xFFEF5350);

Color _gaugeColor(BudgetSummary s) {
  if (s.isOverBudget) return _over;
  if (s.isWarning) return _warn;
  return _safe;
}

class BudgetGauge extends StatefulWidget {
  final BudgetSummary summary;

  const BudgetGauge({super.key, required this.summary});

  @override
  State<BudgetGauge> createState() => _BudgetGaugeState();
}

class _BudgetGaugeState extends State<BudgetGauge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late Animation<double> _anim;
  double _prevFraction = 0;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1400));
    _anim = Tween(begin: 0.0, end: widget.summary.spentFraction)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _ctrl.forward();
  }

  @override
  void didUpdateWidget(BudgetGauge old) {
    super.didUpdateWidget(old);
    if (old.summary.spentFraction != widget.summary.spentFraction) {
      _prevFraction = old.summary.spentFraction;
      _anim = Tween(begin: _prevFraction, end: widget.summary.spentFraction)
          .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
      _ctrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = _gaugeColor(widget.summary);
    final pct = (widget.summary.spentFraction * 100).round();

    return AnimatedBuilder(
      animation: _anim,
      builder: (_, _) => SizedBox(
        width: 220,
        height: 220,
        child: CustomPaint(
          painter: _GaugePainter(fraction: _anim.value, color: color),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Percentage badge
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: color.withValues(alpha: 0.35), width: 1),
                  ),
                  child: Text(
                    '$pct%',
                    style: TextStyle(
                      color: color,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // Big spent amount
                TweenAnimationBuilder<double>(
                  tween: Tween(
                      begin: 0, end: widget.summary.spentEur),
                  duration: const Duration(milliseconds: 1400),
                  curve: Curves.easeOutCubic,
                  builder: (_, v, _) => Text(
                    '€${v.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: color,
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1.5,
                      height: 1.0,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'of €300 spent',
                  style: TextStyle(
                    color: RpgColors.textMuted.withValues(alpha: 0.8),
                    fontSize: 11,
                    letterSpacing: 0.3,
                  ),
                ),
                if (widget.summary.isOverBudget) ...[
                  const SizedBox(height: 6),
                  Text(
                    'OVER BUDGET',
                    style: TextStyle(
                      color: _over,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2.0,
                    ),
                  ),
                ] else if (widget.summary.isWarning) ...[
                  const SizedBox(height: 6),
                  Text(
                    '⚠  WARNING',
                    style: TextStyle(
                      color: _warn,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.6,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double fraction;
  final Color color;

  _GaugePainter({required this.fraction, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 14;
    const strokeWidth = 12.0;
    const startAngle = pi * 0.75;  // 135°
    const sweepFull = pi * 1.5;    // 270° arc

    // Outer subtle ring
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius + 8),
      startAngle,
      sweepFull,
      false,
      Paint()
        ..color = color.withValues(alpha: 0.04)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Track
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepFull,
      false,
      Paint()
        ..color = RpgColors.progressTrack
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );

    if (fraction > 0) {
      // Wide outer glow
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepFull * fraction,
        false,
        Paint()
          ..color = color.withValues(alpha: 0.18)
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth + 10
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
      // Tight inner glow
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepFull * fraction,
        false,
        Paint()
          ..color = color.withValues(alpha: 0.45)
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth + 3
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );
      // Solid arc
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepFull * fraction,
        false,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round,
      );
      // Bright tip dot
      final tipAngle = startAngle + sweepFull * fraction;
      final tip = Offset(
        center.dx + radius * cos(tipAngle),
        center.dy + radius * sin(tipAngle),
      );
      canvas.drawCircle(tip, strokeWidth / 2 + 2,
          Paint()..color = color.withValues(alpha: 0.3)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
      canvas.drawCircle(tip, strokeWidth / 2 - 1,
          Paint()..color = Colors.white.withValues(alpha: 0.9));
    }
  }

  @override
  bool shouldRepaint(covariant _GaugePainter old) =>
      fraction != old.fraction || color != old.color;
}
