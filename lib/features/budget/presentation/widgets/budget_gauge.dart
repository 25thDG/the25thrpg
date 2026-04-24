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
        vsync: this, duration: const Duration(milliseconds: 1200));
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
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, _) => SizedBox(
        width: 200,
        height: 200,
        child: CustomPaint(
          painter: _GaugePainter(fraction: _anim.value, color: color),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '€${widget.summary.spentEur.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: color,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1,
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'of €300 spent',
                  style: const TextStyle(
                    color: RpgColors.textMuted,
                    fontSize: 10,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    border:
                        Border.all(color: color.withValues(alpha: 0.35)),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Text(
                    widget.summary.isOverBudget
                        ? 'OVER BUDGET'
                        : widget.summary.isWarning
                            ? '${(widget.summary.spentFraction * 100).round()}%  WARNING'
                            : '€${widget.summary.remainingEur.toStringAsFixed(0)} left',
                    style: TextStyle(
                      color: color,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
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
    final radius = size.width / 2 - 12;
    const strokeWidth = 10.0;
    const startAngle = pi * 0.75; // 135°
    const sweepFull = pi * 1.5; // 270° arc

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
      // Glow
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepFull * fraction,
        false,
        Paint()
          ..color = color.withValues(alpha: 0.25)
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth + 6
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
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
    }
  }

  @override
  bool shouldRepaint(covariant _GaugePainter old) =>
      fraction != old.fraction || color != old.color;
}
