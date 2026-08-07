import 'dart:math';
import 'package:flutter/material.dart';

import '../../domain/entities/skill_summary.dart';
import 'rpg_colors.dart';
import 'skill_colors.dart';

// Label clearance constants (shared between widget sizing and painter)
const _sidePad = 58.0; // horizontal space reserved for side labels
const _topPad = 50.0; // vertical space above top vertex for its label
const _botPad = 48.0; // vertical space below the bottom vertex for its label
const _labelGap = 15.0; // gap between vertex and label anchor

/// Radius of the avatar core sitting at the centre of the polygon.
const _coreRadius = 42.0;

/// Number of axes drawn — one per skill on the character sheet.
const kRadarAxes = 4;

/// Half-extents of the unit polygon (radius 1) in each direction, so the box
/// can be sized for any number of axes rather than a hardcoded triangle.
({double top, double bottom, double side}) _unitExtents(int n) {
  double top = 0, bottom = 0, side = 0;
  for (int i = 0; i < n; i++) {
    final a = -pi / 2 + (2 * pi / n) * i;
    top = max(top, -sin(a));
    bottom = max(bottom, sin(a));
    side = max(side, cos(a).abs());
  }
  return (top: top, bottom: bottom, side: side);
}

/// Upper bound of the radar axis — the next multiple of 10 above the best
/// skill, so the shape fills the chart instead of hugging the centre.
int radarAxisMax(List<SkillSummary> skills) {
  final best = skills.fold(1, (m, s) => max(m, s.level));
  if (best <= 10) return 10;
  if (best >= 100) return 100;
  return (best / 10).ceil() * 10;
}

/// The character itself: a polygon whose shape is unique to the player and
/// shifts as their skills move. Rendered chrome-free so it reads as a figure on
/// the page rather than a chart in a box.
class SkillRadarChart extends StatelessWidget {
  final List<SkillSummary> skills;

  /// Sits in the middle of the polygon — the avatar core.
  final Widget? core;

  const SkillRadarChart({super.key, required this.skills, this.core});

  @override
  Widget build(BuildContext context) {
    final axisMax = radarAxisMax(skills);

    return LayoutBuilder(
      builder: (_, constraints) {
        final e = _unitExtents(kRadarAxes);
        final r = (constraints.maxWidth - 2 * _sidePad) / (2 * e.side);
        final h = _topPad + (e.top + e.bottom) * r + _botPad;
        final cy = _topPad + e.top * r;

        return SizedBox(
          width: constraints.maxWidth,
          height: h,
          child: Stack(
            children: [
              if (core != null)
                Positioned(
                  left: 0,
                  right: 0,
                  top: cy - _coreRadius,
                  height: _coreRadius * 2,
                  child: Center(child: core!),
                ),
              Positioned.fill(
                child: _AnimatedRadar(skills: skills, axisMax: axisMax),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AnimatedRadar extends StatefulWidget {
  final List<SkillSummary> skills;
  final int axisMax;

  const _AnimatedRadar({required this.skills, required this.axisMax});

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
          axisMax: widget.axisMax,
          animationValue: _animation.value,
        ),
      ),
    );
  }
}

class _RadarPainter extends CustomPainter {
  final List<SkillSummary> skills;
  final int axisMax;
  final double animationValue;

  _RadarPainter({
    required this.skills,
    required this.axisMax,
    required this.animationValue,
  });

  /// Clockwise from the top. Resolve sits opposite Wealth so the two
  /// non-time skills balance the shape.
  static const _displayOrder = [
    SkillId.japanese,
    SkillId.wealth,
    SkillId.mindfulness,
    SkillId.resolve,
  ];

  /// Linear against the zoomed axis, so a 26-vs-9 gap looks like a 26-vs-9 gap.
  /// A small floor keeps a level-1 skill from vanishing into the centre.
  double _visualFrac(int level) =>
      (level / axisMax).clamp(0.06, 1.0);

  @override
  void paint(Canvas canvas, Size size) {
    // Mirror the same geometry as the widget's LayoutBuilder calculation.
    final n = _displayOrder.length;
    final e = _unitExtents(n);
    final r = (size.width - _sidePad * 2) / (2 * e.side);
    final center = Offset(size.width / 2, _topPad + e.top * r);

    final skillMap = {for (final s in skills) s.skill: s};

    Offset vertex(int i, double frac) {
      final angle = -pi / 2 + (2 * pi / n) * i;
      return Offset(
        center.dx + r * frac * cos(angle),
        center.dy + r * frac * sin(angle),
      );
    }

    // ── Grid rings ────────────────────────────────────────────────────────────
    // The outer ring gets a faint cyan-white bloom so the arena reads as lit
    // glass rather than a flat wireframe.
    for (final frac in [0.5, 0.75, 1.0]) {
      final isOuter = frac == 1.0;
      final path = Path();
      for (int i = 0; i < n; i++) {
        final p = vertex(i, frac);
        i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
      }
      path.close();

      if (isOuter) {
        canvas.drawPath(
          path,
          Paint()
            ..color = const Color(0xFF8FA8C8).withValues(alpha: 0.18)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
        );
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = const Color(0xFF8FA8C8)
              .withValues(alpha: isOuter ? 0.42 : 0.13)
          ..style = PaintingStyle.stroke
          ..strokeWidth = isOuter ? 1.1 : 0.7,
      );
    }

    // ── Axis lines ────────────────────────────────────────────────────────────
    final axisPaint = Paint()
      ..color = RpgColors.divider.withValues(alpha: 0.4)
      ..strokeWidth = 0.5;

    for (int i = 0; i < n; i++) {
      final angle = -pi / 2 + (2 * pi / n) * i;
      final start = Offset(
        center.dx + (_coreRadius + 6) * cos(angle),
        center.dy + (_coreRadius + 6) * sin(angle),
      );
      canvas.drawLine(start, vertex(i, 1.0), axisPaint);
    }

    // ── Data polygon ──────────────────────────────────────────────────────────
    final dataPath = Path();
    final dataPoints = <Offset>[];

    for (int i = 0; i < n; i++) {
      final skill = skillMap[_displayOrder[i]];
      final frac = _visualFrac(skill?.level ?? 1) * animationValue;
      final p = vertex(i, frac);
      dataPoints.add(p);
      i == 0 ? dataPath.moveTo(p.dx, p.dy) : dataPath.lineTo(p.dx, p.dy);
    }
    dataPath.close();

    // Radial gradient fill — denser at the centre, fading toward the edge.
    canvas.drawPath(
      dataPath,
      Paint()
        // Hollow core so the level number reads cleanly, dense at the rim so
        // the silhouette still has body.
        ..shader = RadialGradient(
          colors: [
            RpgColors.accent.withValues(alpha: 0.02),
            RpgColors.accent.withValues(alpha: 0.10),
            RpgColors.accent.withValues(alpha: 0.42),
          ],
          stops: const [0.0, 0.45, 1.0],
        ).createShader(Rect.fromCircle(center: center, radius: r)),
    );
    // Two blur passes — a wide soft halo plus a tight bloom — then a bright
    // core line, which is what makes a stroke read as "emitting" light.
    canvas.drawPath(
      dataPath,
      Paint()
        ..color = const Color(0xFFE74C3C).withValues(alpha: 0.30)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
    );
    canvas.drawPath(
      dataPath,
      Paint()
        ..color = const Color(0xFFFF7A6B).withValues(alpha: 0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    canvas.drawPath(
      dataPath,
      Paint()
        ..color = const Color(0xFFFFD9D2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6,
    );

    // ── Vertex dots ───────────────────────────────────────────────────────────
    for (int i = 0; i < dataPoints.length; i++) {
      final color = skillColor(_displayOrder[i]);
      final p = dataPoints[i];
      canvas.drawCircle(
        p,
        10,
        Paint()
          ..color = color.withValues(alpha: 0.35)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
      canvas.drawCircle(p, 5.5, Paint()..color = RpgColors.pageBg);
      canvas.drawCircle(
        p,
        5.5,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6,
      );
      canvas.drawCircle(p, 2.6, Paint()..color = color);
    }

    // ── Labels ────────────────────────────────────────────────────────────────
    for (int i = 0; i < n; i++) {
      final angle = -pi / 2 + (2 * pi / n) * i;
      final skillId = _displayOrder[i];
      final skill = skillMap[skillId];
      final lvl = skill?.level ?? 1;
      final color = skillColor(skillId);

      // Anchor point just beyond the full-radius vertex
      final anchor = Offset(
        center.dx + (r + _labelGap) * cos(angle),
        center.dy + (r + _labelGap) * sin(angle),
      );

      final namePainter = TextPainter(
        text: TextSpan(
          text: skillId.displayName,
          style: TextStyle(
            color: color.withValues(alpha: 0.75),
            fontSize: 8,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.0,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      // The level is the point of the chart — make it the loudest element.
      final levelPainter = TextPainter(
        text: TextSpan(
          children: [
            TextSpan(
              text: 'Lv ',
              style: TextStyle(
                color: color.withValues(alpha: 0.6),
                fontSize: 9,
                fontWeight: FontWeight.w600,
              ),
            ),
            TextSpan(
              text: '$lvl',
              style: TextStyle(
                color: color,
                fontSize: 15,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final blockH = namePainter.height + 1 + levelPainter.height;

      // Top vertex: block sits above it. Bottom vertex: below it.
      // Side vertices: centred on the anchor.
      final sinA = sin(angle);
      final topY = sinA < -0.9
          ? anchor.dy - blockH - 2
          : (sinA > 0.9 ? anchor.dy + 2 : anchor.dy - blockH / 2);

      namePainter.paint(
          canvas, Offset(anchor.dx - namePainter.width / 2, topY));
      levelPainter.paint(
          canvas,
          Offset(anchor.dx - levelPainter.width / 2,
              topY + namePainter.height + 1));
    }
  }

  @override
  bool shouldRepaint(covariant _RadarPainter old) =>
      animationValue != old.animationValue ||
      skills != old.skills ||
      axisMax != old.axisMax;
}
