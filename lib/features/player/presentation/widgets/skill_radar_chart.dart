import 'dart:math';
import 'package:flutter/material.dart';

import '../../domain/entities/skill_summary.dart';
import 'rpg_colors.dart';

// Label clearance constants (shared between widget sizing and painter)
const _sidePad = 58.0; // horizontal space reserved for side labels
const _topPad = 44.0; // vertical space above top vertex for its label
const _botPad = 22.0; // vertical space below bottom vertices
const _labelGap = 14.0; // gap between vertex and label anchor

/// Triangular radar chart — box is sized exactly to contain the triangle
/// plus its labels, with no wasted whitespace.
class SkillRadarChart extends StatelessWidget {
  final List<SkillSummary> skills;

  const SkillRadarChart({super.key, required this.skills});

  @override
  Widget build(BuildContext context) {
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
          _RadarHeader(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
            child: LayoutBuilder(
              builder: (_, constraints) {
                // Radius constrained by horizontal space after side labels.
                // Triangle width = r * √3, so r = availableWidth / √3.
                final r = (constraints.maxWidth - 2 * _sidePad) / sqrt(3);
                // Exact height: label above top vertex + triangle height + label below.
                // Triangle spans r above centre and r/2 below (equilateral geometry).
                final h = _topPad + r + r / 2 + _botPad;
                return SizedBox(
                  width: constraints.maxWidth,
                  height: h,
                  child: _AnimatedRadar(skills: skills),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _RadarHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 3,
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
            gradient: LinearGradient(
              colors: [Color(0xFFC0392B), Color(0xFFE74C3C)],
            ),
          ),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: RpgColors.divider)),
          ),
          child: const Text(
            'SKILL RADAR',
            style: TextStyle(
              color: RpgColors.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 2.4,
            ),
          ),
        ),
      ],
    );
  }
}

class _AnimatedRadar extends StatefulWidget {
  final List<SkillSummary> skills;

  const _AnimatedRadar({required this.skills});

  @override
  State<_AnimatedRadar> createState() => _AnimatedRadarState();
}

class _AnimatedRadarState extends State<_AnimatedRadar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (_, _) => CustomPaint(
        painter: _RadarPainter(
          skills: widget.skills,
          animationValue: _animation.value,
        ),
      ),
    );
  }
}

class _RadarPainter extends CustomPainter {
  final List<SkillSummary> skills;
  final double animationValue;

  _RadarPainter({required this.skills, required this.animationValue});

  static const _displayOrder = [
    SkillId.japanese,
    SkillId.wealth,
    SkillId.mindfulness,
  ];

  static const _skillColors = {
    SkillId.japanese: Color(0xFF4FC3F7),
    SkillId.wealth: Color(0xFF10B981),
    SkillId.mindfulness: Color(0xFF26A69A),
  };

  /// Sqrt-scale so low-level skills don't collapse to a point at centre.
  /// Minimum floor of 0.05 keeps even level-1 skills visible.
  static double _visualFrac(int level) =>
      sqrt(level.clamp(0, 100) / 100.0).clamp(0.05, 1.0);

  @override
  void paint(Canvas canvas, Size size) {
    // Mirror the same geometry as the widget's LayoutBuilder calculation.
    final r = (size.width - 2 * _sidePad) / sqrt(3);
    // Centre sits _topPad + r below the widget top (top vertex sits at _topPad).
    final center = Offset(size.width / 2, _topPad + r);
    const n = 3;

    final skillMap = {for (final s in skills) s.skill: s};

    // ── Grid rings ────────────────────────────────────────────────────────────
    final gridPaint = Paint()
      ..color = RpgColors.divider.withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    for (final frac in [0.25, 0.5, 0.75, 1.0]) {
      final path = Path();
      for (int i = 0; i < n; i++) {
        final angle = -pi / 2 + (2 * pi / n) * i;
        final p = Offset(
          center.dx + r * frac * cos(angle),
          center.dy + r * frac * sin(angle),
        );
        i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
      }
      path.close();
      canvas.drawPath(path, gridPaint);
    }

    // ── Axis lines ────────────────────────────────────────────────────────────
    final axisPaint = Paint()
      ..color = RpgColors.divider.withValues(alpha: 0.4)
      ..strokeWidth = 0.5;

    for (int i = 0; i < n; i++) {
      final angle = -pi / 2 + (2 * pi / n) * i;
      canvas.drawLine(
        center,
        Offset(center.dx + r * cos(angle), center.dy + r * sin(angle)),
        axisPaint,
      );
    }

    // ── Data polygon ──────────────────────────────────────────────────────────
    final dataPath = Path();
    final dataPoints = <Offset>[];

    for (int i = 0; i < n; i++) {
      final angle = -pi / 2 + (2 * pi / n) * i;
      final skill = skillMap[_displayOrder[i]];
      final frac = _visualFrac(skill?.level ?? 1) * animationValue;
      final p = Offset(center.dx + r * frac * cos(angle), center.dy + r * frac * sin(angle));
      dataPoints.add(p);
      i == 0 ? dataPath.moveTo(p.dx, p.dy) : dataPath.lineTo(p.dx, p.dy);
    }
    dataPath.close();

    canvas.drawPath(
      dataPath,
      Paint()
        ..color = RpgColors.accent.withValues(alpha: 0.15)
        ..style = PaintingStyle.fill,
    );
    // Glow
    canvas.drawPath(
      dataPath,
      Paint()
        ..color = RpgColors.accent.withValues(alpha: 0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    // Solid stroke
    canvas.drawPath(
      dataPath,
      Paint()
        ..color = RpgColors.accent.withValues(alpha: 0.75)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // ── Vertex dots ───────────────────────────────────────────────────────────
    for (int i = 0; i < dataPoints.length; i++) {
      final color = _skillColors[_displayOrder[i]] ?? RpgColors.accent;
      canvas.drawCircle(dataPoints[i], 5.5,
          Paint()..color = color.withValues(alpha: 0.2));
      canvas.drawCircle(dataPoints[i], 3,
          Paint()..color = color..style = PaintingStyle.fill);
    }

    // ── Labels ────────────────────────────────────────────────────────────────
    for (int i = 0; i < n; i++) {
      final angle = -pi / 2 + (2 * pi / n) * i;
      final skillId = _displayOrder[i];
      final skill = skillMap[skillId];
      final lvl = skill?.level ?? 1;
      final color = _skillColors[skillId] ?? RpgColors.accent;

      // Anchor point just beyond the full-radius vertex
      final anchor = Offset(
        center.dx + (r + _labelGap) * cos(angle),
        center.dy + (r + _labelGap) * sin(angle),
      );

      final namePainter = TextPainter(
        text: TextSpan(
          text: skillId.displayName,
          style: TextStyle(
            color: color.withValues(alpha: 0.9),
            fontSize: 7,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.0,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final levelPainter = TextPainter(
        text: TextSpan(
          text: 'Lv.$lvl',
          style: TextStyle(
            color: RpgColors.textSecondary.withValues(alpha: 0.85),
            fontSize: 8,
            fontWeight: FontWeight.w700,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final blockH = namePainter.height + 2 + levelPainter.height;

      // Top vertex (i==0): render block ABOVE the anchor.
      // Side vertices: centre block vertically on the anchor.
      final topY = i == 0
          ? anchor.dy - blockH - 2
          : anchor.dy - blockH / 2;

      namePainter.paint(
          canvas, Offset(anchor.dx - namePainter.width / 2, topY));
      levelPainter.paint(
          canvas,
          Offset(anchor.dx - levelPainter.width / 2,
              topY + namePainter.height + 2));
    }
  }

  @override
  bool shouldRepaint(covariant _RadarPainter old) =>
      animationValue != old.animationValue || skills != old.skills;
}
