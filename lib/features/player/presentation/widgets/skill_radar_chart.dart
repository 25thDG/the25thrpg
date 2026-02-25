import 'dart:math';
import 'package:flutter/material.dart';

import '../../domain/entities/skill_summary.dart';
import 'rpg_colors.dart';

/// Hexagonal radar chart displaying all 6 skill levels (capped at 100).
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
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 20),
            child: AspectRatio(
              aspectRatio: 1.0,
              child: _AnimatedRadar(skills: skills),
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
    return Container(
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
      duration: const Duration(milliseconds: 1200),
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

  // Order for the hexagon: top, then clockwise
  static const _displayOrder = [
    SkillId.japanese,
    SkillId.wealth,
    SkillId.sport,
    SkillId.social,
    SkillId.creation,
    SkillId.mindfulness,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 44; // leave room for labels
    final n = _displayOrder.length;

    // Build lookup
    final skillMap = {for (final s in skills) s.skill: s};

    // ── Grid rings at 25%, 50%, 75%, 100% ─────────────────────────────────
    final gridPaint = Paint()
      ..color = RpgColors.divider
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    for (final frac in [0.25, 0.5, 0.75, 1.0]) {
      final path = Path();
      for (int i = 0; i < n; i++) {
        final angle = -pi / 2 + (2 * pi / n) * i;
        final r = radius * frac;
        final p = Offset(center.dx + r * cos(angle), center.dy + r * sin(angle));
        if (i == 0) {
          path.moveTo(p.dx, p.dy);
        } else {
          path.lineTo(p.dx, p.dy);
        }
      }
      path.close();
      canvas.drawPath(path, gridPaint);
    }

    // ── Axis lines ─────────────────────────────────────────────────────────
    final axisPaint = Paint()
      ..color = RpgColors.divider.withValues(alpha: 0.5)
      ..strokeWidth = 0.5;

    for (int i = 0; i < n; i++) {
      final angle = -pi / 2 + (2 * pi / n) * i;
      final end = Offset(
        center.dx + radius * cos(angle),
        center.dy + radius * sin(angle),
      );
      canvas.drawLine(center, end, axisPaint);
    }

    // ── Data polygon ──────────────────────────────────────────────────────
    final dataPath = Path();
    final dataPoints = <Offset>[];

    for (int i = 0; i < n; i++) {
      final angle = -pi / 2 + (2 * pi / n) * i;
      final skill = skillMap[_displayOrder[i]];
      final rawLevel = skill?.level ?? 1;
      final frac = (rawLevel / 100.0).clamp(0.0, 1.0) * animationValue;
      final r = radius * frac;
      final p = Offset(center.dx + r * cos(angle), center.dy + r * sin(angle));
      dataPoints.add(p);
      if (i == 0) {
        dataPath.moveTo(p.dx, p.dy);
      } else {
        dataPath.lineTo(p.dx, p.dy);
      }
    }
    dataPath.close();

    // Fill
    final fillPaint = Paint()
      ..color = RpgColors.accent.withValues(alpha: 0.12)
      ..style = PaintingStyle.fill;
    canvas.drawPath(dataPath, fillPaint);

    // Stroke
    final strokePaint = Paint()
      ..color = RpgColors.accent.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawPath(dataPath, strokePaint);

    // ── Vertex dots ───────────────────────────────────────────────────────
    final dotPaint = Paint()
      ..color = RpgColors.accent
      ..style = PaintingStyle.fill;

    for (final p in dataPoints) {
      canvas.drawCircle(p, 3, dotPaint);
    }

    // ── Labels ────────────────────────────────────────────────────────────
    for (int i = 0; i < n; i++) {
      final angle = -pi / 2 + (2 * pi / n) * i;
      final skillId = _displayOrder[i];
      final skill = skillMap[skillId];
      final lvl = skill?.level ?? 1;
      final labelR = radius + 22;
      final p = Offset(
        center.dx + labelR * cos(angle),
        center.dy + labelR * sin(angle),
      );

      final nameSpan = TextSpan(
        text: skillId.displayName,
        style: TextStyle(
          color: RpgColors.textMuted.withValues(alpha: 0.8),
          fontSize: 8,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.0,
        ),
      );
      final namePainter = TextPainter(
        text: nameSpan,
        textDirection: TextDirection.ltr,
      )..layout();

      final levelSpan = TextSpan(
        text: '$lvl',
        style: const TextStyle(
          color: RpgColors.textSecondary,
          fontSize: 9,
          fontWeight: FontWeight.w700,
        ),
      );
      final levelPainter = TextPainter(
        text: levelSpan,
        textDirection: TextDirection.ltr,
      )..layout();

      // Position label centered on axis endpoint
      final totalHeight = namePainter.height + 2 + levelPainter.height;
      namePainter.paint(
        canvas,
        Offset(p.dx - namePainter.width / 2, p.dy - totalHeight / 2),
      );
      levelPainter.paint(
        canvas,
        Offset(
          p.dx - levelPainter.width / 2,
          p.dy - totalHeight / 2 + namePainter.height + 2,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RadarPainter oldDelegate) =>
      animationValue != oldDelegate.animationValue ||
      skills != oldDelegate.skills;
}
