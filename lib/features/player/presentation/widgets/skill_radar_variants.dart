import 'dart:math';

import 'package:flutter/material.dart';

import '../../domain/entities/skill_summary.dart';
import 'rpg_colors.dart';
import 'skill_colors.dart';
import 'skill_radar_chart.dart' show radarAxisMax;

/// Five ways to draw the character. Same data, same colours, same reading
/// order — only the shape changes, so whichever wins drops straight into the
/// hero slot in place of [SkillRadarChart].

/// Clockwise from the top, so the figure stays recognisable across variants.
const _order = [
  SkillId.japanese,
  SkillId.wealth,
  SkillId.mindfulness,
  SkillId.resolve,
];

const _gridColor = Color(0xFF8FA8C8);

Map<SkillId, SkillSummary> _byId(List<SkillSummary> skills) =>
    {for (final s in skills) s.skill: s};

/// Level as a fraction of the zoomed axis. The floor keeps a level-1 skill
/// visible instead of collapsing it into the centre.
double _frac(SkillSummary? s, int axisMax) =>
    ((s?.level ?? 1) / axisMax).clamp(0.08, 1.0);

double _angle(int i) => -pi / 2 + (pi / 2) * i;

Offset _at(Offset c, double r, int i) =>
    Offset(c.dx + r * cos(_angle(i)), c.dy + r * sin(_angle(i)));

double _radiusFor(Size size) =>
    min((size.width - 132) / 2, (size.height - 104) / 2);

enum _Anchor { above, below, middle }

/// Skill name over its level — identical on every variant.
void _paintLabel(Canvas canvas, Offset at, SkillId id, int lvl, _Anchor a) {
  final color = skillColor(id);

  final name = TextPainter(
    text: TextSpan(
      text: id.displayName,
      style: TextStyle(
        color: color.withValues(alpha: 0.75),
        fontSize: 8,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.0,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();

  final level = TextPainter(
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

  final blockH = name.height + 1 + level.height;
  final top = switch (a) {
    _Anchor.above => at.dy - blockH - 2,
    _Anchor.below => at.dy + 2,
    _Anchor.middle => at.dy - blockH / 2,
  };

  name.paint(canvas, Offset(at.dx - name.width / 2, top));
  level.paint(
    canvas,
    Offset(at.dx - level.width / 2, top + name.height + 1),
  );
}

_Anchor _anchorFor(int i) => switch (i) {
      0 => _Anchor.above,
      2 => _Anchor.below,
      _ => _Anchor.middle,
    };

/// The soft light at the centre, shared by the radial variants.
void _paintCore(Canvas canvas, Offset c, {double radius = 34}) {
  canvas.drawCircle(
    c,
    radius,
    Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFFFE3DC).withValues(alpha: 0.55),
          const Color(0xFFE74C3C).withValues(alpha: 0.32),
          const Color(0xFFC0392B).withValues(alpha: 0.08),
          Colors.transparent,
        ],
        stops: const [0.0, 0.34, 0.62, 1.0],
      ).createShader(Rect.fromCircle(center: c, radius: radius)),
  );
}

/// Wide halo → tight bloom → bright core line. Three passes is what makes a
/// stroke read as emitting light rather than being coloured.
void _glowStroke(
  Canvas canvas,
  Path path, {
  required Color halo,
  required Color bloom,
  required Color core,
  double scale = 1.0,
}) {
  canvas.drawPath(
    path,
    Paint()
      ..color = halo
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12 * scale
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 14 * scale),
  );
  canvas.drawPath(
    path,
    Paint()
      ..color = bloom
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4 * scale
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 4 * scale),
  );
  canvas.drawPath(
    path,
    Paint()
      ..color = core
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6 * scale,
  );
}

// ══ A · AURA ══════════════════════════════════════════════════════════════════

/// The current diamond, but curved. A closed spline through the four points
/// turns the wireframe into an organic silhouette — the figure reads as an aura
/// rather than a chart, while the vertices stay exactly where the data puts them.
class RadarAura extends StatelessWidget {
  final List<SkillSummary> skills;

  const RadarAura({super.key, required this.skills});

  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        height: 340,
        child: CustomPaint(
          painter: _AuraPainter(skills: skills, axisMax: radarAxisMax(skills)),
        ),
      );
}

class _AuraPainter extends CustomPainter {
  final List<SkillSummary> skills;
  final int axisMax;

  _AuraPainter({required this.skills, required this.axisMax});

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = _radiusFor(size);
    final m = _byId(skills);

    for (final f in [0.45, 0.72, 1.0]) {
      final outer = f == 1.0;
      if (outer) {
        canvas.drawCircle(
          c,
          r,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3
            ..color = _gridColor.withValues(alpha: 0.14)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
        );
      }
      canvas.drawCircle(
        c,
        r * f,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = outer ? 1.0 : 0.6
          ..color = _gridColor.withValues(alpha: outer ? 0.30 : 0.10),
      );
    }

    final pts = [
      for (int i = 0; i < 4; i++)
        _at(c, r * _frac(m[_order[i]], axisMax), i),
    ];
    final path = _spline(pts);

    canvas.drawPath(
      path,
      Paint()
        ..shader = RadialGradient(
          colors: [
            RpgColors.accent.withValues(alpha: 0.02),
            RpgColors.accent.withValues(alpha: 0.12),
            RpgColors.accent.withValues(alpha: 0.46),
          ],
          stops: const [0.0, 0.45, 1.0],
        ).createShader(Rect.fromCircle(center: c, radius: r)),
    );

    _paintCore(canvas, c);

    _glowStroke(
      canvas,
      path,
      halo: const Color(0xFFE74C3C).withValues(alpha: 0.30),
      bloom: const Color(0xFFFF7A6B).withValues(alpha: 0.55),
      core: const Color(0xFFFFD9D2),
    );

    for (int i = 0; i < 4; i++) {
      final p = pts[i];
      final color = skillColor(_order[i]);
      canvas.drawCircle(
        p,
        11,
        Paint()
          ..color = color.withValues(alpha: 0.35)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
      canvas.drawCircle(p, 4.5, Paint()..color = const Color(0xFFFFF3F0));
      _paintLabel(
        canvas,
        _at(c, r + 15, i),
        _order[i],
        m[_order[i]]?.level ?? 1,
        _anchorFor(i),
      );
    }
  }

  /// Closed Catmull-Rom through the vertices, converted to cubics.
  Path _spline(List<Offset> p) {
    final n = p.length;
    final path = Path()..moveTo(p[0].dx, p[0].dy);
    for (int i = 0; i < n; i++) {
      final p0 = p[(i - 1 + n) % n];
      final p1 = p[i];
      final p2 = p[(i + 1) % n];
      final p3 = p[(i + 2) % n];
      final cp1 = p1 + (p2 - p0) / 6;
      final cp2 = p2 - (p3 - p1) / 6;
      path.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, p2.dx, p2.dy);
    }
    return path..close();
  }

  @override
  bool shouldRepaint(covariant _AuraPainter old) =>
      old.skills != skills || old.axisMax != axisMax;
}

// ══ B · ORBITS ════════════════════════════════════════════════════════════════

/// One ring per skill, each filled clockwise from twelve o'clock. No shape to
/// read — just four arcs you can compare at a glance, in each skill's own
/// colour. The most legible of the five, and the least "chart".
class RadarOrbits extends StatelessWidget {
  final List<SkillSummary> skills;

  const RadarOrbits({super.key, required this.skills});

  @override
  Widget build(BuildContext context) {
    final m = _byId(skills);
    final axisMax = radarAxisMax(skills);

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 268,
          child: CustomPaint(
            painter: _OrbitsPainter(skills: skills, axisMax: axisMax),
          ),
        ),
        const SizedBox(height: 14),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 34),
          child: Row(
            children: [
              for (int i = 0; i < 4; i++)
                Expanded(
                  child: _OrbitKey(
                    id: _order[i],
                    level: m[_order[i]]?.level ?? 1,
                    pct: _frac(m[_order[i]], axisMax),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _OrbitKey extends StatelessWidget {
  final SkillId id;
  final int level;
  final double pct;

  const _OrbitKey({required this.id, required this.level, required this.pct});

  @override
  Widget build(BuildContext context) {
    final color = skillColor(id);
    return Column(
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            boxShadow: [
              BoxShadow(color: color.withValues(alpha: 0.6), blurRadius: 7),
            ],
          ),
        ),
        const SizedBox(height: 7),
        Text(
          '$level',
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.w800,
            height: 1.0,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            id.displayName,
            maxLines: 1,
            style: const TextStyle(
              color: RpgColors.textMuted,
              fontSize: 7.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
        ),
      ],
    );
  }
}

class _OrbitsPainter extends CustomPainter {
  final List<SkillSummary> skills;
  final int axisMax;

  _OrbitsPainter({required this.skills, required this.axisMax});

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final outer = min(size.width, size.height) / 2 - 16;
    final m = _byId(skills);
    const gap = 20.0;
    const w = 9.0;

    for (int i = 0; i < 4; i++) {
      final id = _order[i];
      final color = skillColor(id);
      final rr = outer - i * gap;
      final rect = Rect.fromCircle(center: c, radius: rr);
      final sweep = 2 * pi * _frac(m[id], axisMax);

      canvas.drawCircle(
        c,
        rr,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = w
          ..color = const Color(0xFF1C1C24),
      );

      canvas.drawArc(
        rect,
        -pi / 2,
        sweep,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = w + 5
          ..strokeCap = StrokeCap.round
          ..color = color.withValues(alpha: 0.30)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9),
      );
      canvas.drawArc(
        rect,
        -pi / 2,
        sweep,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = w
          ..strokeCap = StrokeCap.butt
          ..shader = SweepGradient(
            startAngle: -pi / 2,
            endAngle: 3 * pi / 2,
            colors: [color.withValues(alpha: 0.45), color],
            stops: const [0.0, 1.0],
            transform: const GradientRotation(-pi / 2),
          ).createShader(rect),
      );

      // Bright head on the leading edge of each arc.
      final head = Offset(
        c.dx + rr * cos(-pi / 2 + sweep),
        c.dy + rr * sin(-pi / 2 + sweep),
      );
      canvas.drawCircle(
        head,
        w / 2,
        Paint()..color = const Color(0xFFFFFFFF).withValues(alpha: 0.9),
      );
    }

    _paintCore(canvas, c, radius: 40);
  }

  @override
  bool shouldRepaint(covariant _OrbitsPainter old) =>
      old.skills != skills || old.axisMax != axisMax;
}

// ══ C · PRISM ═════════════════════════════════════════════════════════════════

/// Four beams out of the core, length set by level. Keeps the compass layout of
/// the radar but drops the connecting web, so nothing about the shape can
/// disguise a weak skill — the gap between beams is the whole story.
class RadarPrism extends StatelessWidget {
  final List<SkillSummary> skills;

  const RadarPrism({super.key, required this.skills});

  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        height: 340,
        child: CustomPaint(
          painter: _PrismPainter(skills: skills, axisMax: radarAxisMax(skills)),
        ),
      );
}

class _PrismPainter extends CustomPainter {
  final List<SkillSummary> skills;
  final int axisMax;

  _PrismPainter({required this.skills, required this.axisMax});

  static const _inner = 34.0;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = _radiusFor(size);
    final m = _byId(skills);

    // Faint distance rings, so a beam can be read against a scale.
    for (final f in [0.5, 1.0]) {
      canvas.drawCircle(
        c,
        _inner + (r - _inner) * f,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = f == 1.0 ? 0.9 : 0.6
          ..color = _gridColor.withValues(alpha: f == 1.0 ? 0.20 : 0.08),
      );
    }

    for (int i = 0; i < 4; i++) {
      final id = _order[i];
      final color = skillColor(id);
      final a = _angle(i);
      final dir = Offset(cos(a), sin(a));
      final start = c + dir * _inner;
      final full = c + dir * r;
      final tip = c + dir * (_inner + (r - _inner) * _frac(m[id], axisMax));

      canvas.drawLine(
        start,
        full,
        Paint()
          ..strokeWidth = 13
          ..strokeCap = StrokeCap.round
          ..color = Colors.white.withValues(alpha: 0.035),
      );

      canvas.drawLine(
        start,
        tip,
        Paint()
          ..strokeWidth = 17
          ..strokeCap = StrokeCap.round
          ..color = color.withValues(alpha: 0.28)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 11),
      );
      canvas.drawLine(
        start,
        tip,
        Paint()
          ..strokeWidth = 13
          ..strokeCap = StrokeCap.round
          ..shader = LinearGradient(
            colors: [color.withValues(alpha: 0.30), color],
          ).createShader(Rect.fromPoints(start, tip)),
      );

      // Hot cap at the end of the beam.
      canvas.drawCircle(
        tip,
        3.4,
        Paint()..color = const Color(0xFFFFFFFF).withValues(alpha: 0.92),
      );

      _paintLabel(canvas, c + dir * (r + 15), id, m[id]?.level ?? 1,
          _anchorFor(i));
    }

    _paintCore(canvas, c, radius: 30);
  }

  @override
  bool shouldRepaint(covariant _PrismPainter old) =>
      old.skills != skills || old.axisMax != axisMax;
}

// ══ D · SONAR ═════════════════════════════════════════════════════════════════

/// The diamond as a live instrument: dotted range rings, tick marks, corner
/// brackets and a sweep that circles the dial once every five seconds. The only
/// variant that moves on its own.
class RadarSonar extends StatefulWidget {
  final List<SkillSummary> skills;

  const RadarSonar({super.key, required this.skills});

  @override
  State<RadarSonar> createState() => _RadarSonarState();
}

class _RadarSonarState extends State<RadarSonar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _sweep;

  @override
  void initState() {
    super.initState();
    _sweep = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();
  }

  @override
  void dispose() {
    _sweep.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        height: 340,
        child: AnimatedBuilder(
          animation: _sweep,
          builder: (_, _) => CustomPaint(
            painter: _SonarPainter(
              skills: widget.skills,
              axisMax: radarAxisMax(widget.skills),
              t: _sweep.value,
            ),
          ),
        ),
      );
}

class _SonarPainter extends CustomPainter {
  final List<SkillSummary> skills;
  final int axisMax;
  final double t;

  _SonarPainter({
    required this.skills,
    required this.axisMax,
    required this.t,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = _radiusFor(size);
    final m = _byId(skills);
    final rot = -pi / 2 + 2 * pi * t;

    // Dotted range rings.
    for (final f in [0.34, 0.67, 1.0]) {
      final rr = r * f;
      final step = 2 * pi / (rr / 3.2);
      for (double a = 0; a < 2 * pi; a += step) {
        canvas.drawCircle(
          Offset(c.dx + rr * cos(a), c.dy + rr * sin(a)),
          f == 1.0 ? 1.0 : 0.7,
          Paint()..color = _gridColor.withValues(alpha: f == 1.0 ? 0.34 : 0.16),
        );
      }
    }

    // Sweep: a fading wedge trailing the leading edge.
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = SweepGradient(
          colors: [
            Colors.transparent,
            RpgColors.accent.withValues(alpha: 0.0),
            RpgColors.accent.withValues(alpha: 0.26),
          ],
          stops: const [0.0, 0.68, 1.0],
          transform: GradientRotation(rot),
        ).createShader(Rect.fromCircle(center: c, radius: r)),
    );
    canvas.drawLine(
      c,
      Offset(c.dx + r * cos(rot), c.dy + r * sin(rot)),
      Paint()
        ..strokeWidth = 1.2
        ..color = const Color(0xFFFF8A7A).withValues(alpha: 0.55),
    );

    // Axes with tick marks.
    for (int i = 0; i < 4; i++) {
      final a = _angle(i);
      final dir = Offset(cos(a), sin(a));
      canvas.drawLine(
        c + dir * 22,
        c + dir * r,
        Paint()
          ..strokeWidth = 0.5
          ..color = _gridColor.withValues(alpha: 0.22),
      );
      final normal = Offset(-dir.dy, dir.dx);
      for (final f in [0.25, 0.5, 0.75]) {
        final p = c + dir * (r * f);
        canvas.drawLine(
          p - normal * 3,
          p + normal * 3,
          Paint()
            ..strokeWidth = 0.8
            ..color = _gridColor.withValues(alpha: 0.28),
        );
      }
    }

    // Corner brackets — the frame that makes it read as an instrument.
    const b = 13.0;
    final box = Rect.fromCircle(center: c, radius: r + 16);
    final bracket = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = RpgColors.accent.withValues(alpha: 0.45);
    for (final (cx, cy, sx, sy) in [
      (box.left, box.top, 1.0, 1.0),
      (box.right, box.top, -1.0, 1.0),
      (box.left, box.bottom, 1.0, -1.0),
      (box.right, box.bottom, -1.0, -1.0),
    ]) {
      canvas.drawPath(
        Path()
          ..moveTo(cx, cy + b * sy)
          ..lineTo(cx, cy)
          ..lineTo(cx + b * sx, cy),
        bracket,
      );
    }

    // Data shape — hard straight lines, this one is a readout not an aura.
    final pts = [
      for (int i = 0; i < 4; i++) _at(c, r * _frac(m[_order[i]], axisMax), i),
    ];
    final path = Path()..moveTo(pts[0].dx, pts[0].dy);
    for (int i = 1; i < 4; i++) {
      path.lineTo(pts[i].dx, pts[i].dy);
    }
    path.close();

    canvas.drawPath(
      path,
      Paint()..color = RpgColors.accent.withValues(alpha: 0.16),
    );
    _glowStroke(
      canvas,
      path,
      halo: const Color(0xFFE74C3C).withValues(alpha: 0.22),
      bloom: const Color(0xFFFF7A6B).withValues(alpha: 0.45),
      core: const Color(0xFFFFD9D2),
      scale: 0.8,
    );

    // Square nodes read as instrument markers rather than dots.
    for (int i = 0; i < 4; i++) {
      final color = skillColor(_order[i]);
      canvas.drawRect(
        Rect.fromCenter(center: pts[i], width: 7, height: 7),
        Paint()..color = RpgColors.pageBg,
      );
      canvas.drawRect(
        Rect.fromCenter(center: pts[i], width: 7, height: 7),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = color,
      );
      _paintLabel(canvas, _at(c, r + 17, i), _order[i],
          m[_order[i]]?.level ?? 1, _anchorFor(i));
    }
  }

  @override
  bool shouldRepaint(covariant _SonarPainter old) =>
      old.t != t || old.skills != skills || old.axisMax != axisMax;
}

// ══ E · MONOLITH ══════════════════════════════════════════════════════════════

/// Not a radar at all: four lit pillars on a floor, tallest skill first to the
/// eye. The silhouette still changes as the character grows, and a 26-vs-9 gap
/// is impossible to misread — but it gives up the "one shape = one character"
/// idea the polygon variants keep.
class RadarMonolith extends StatelessWidget {
  final List<SkillSummary> skills;

  const RadarMonolith({super.key, required this.skills});

  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        height: 300,
        child: CustomPaint(
          painter:
              _MonolithPainter(skills: skills, axisMax: radarAxisMax(skills)),
        ),
      );
}

class _MonolithPainter extends CustomPainter {
  final List<SkillSummary> skills;
  final int axisMax;

  _MonolithPainter({required this.skills, required this.axisMax});

  @override
  void paint(Canvas canvas, Size size) {
    final m = _byId(skills);
    const padX = 30.0;
    const barW = 40.0;
    final slot = (size.width - padX * 2) / 4;
    final baseY = size.height - 44;
    final maxH = baseY - 54;

    // Floor.
    canvas.drawLine(
      Offset(padX - 8, baseY),
      Offset(size.width - padX + 8, baseY),
      Paint()
        ..strokeWidth = 1
        ..color = _gridColor.withValues(alpha: 0.16),
    );

    for (int i = 0; i < 4; i++) {
      final id = _order[i];
      final color = skillColor(id);
      final lvl = m[id]?.level ?? 1;
      final h = 16 + (maxH - 16) * _frac(m[id], axisMax);
      final cx = padX + slot * i + slot / 2;
      final rect = Rect.fromLTRB(cx - barW / 2, baseY - h, cx + barW / 2, baseY);

      final body = RRect.fromRectAndCorners(
        rect,
        topLeft: const Radius.circular(12),
        topRight: const Radius.circular(12),
        bottomLeft: const Radius.circular(3),
        bottomRight: const Radius.circular(3),
      );

      canvas.drawRRect(
        body,
        Paint()
          ..color = color.withValues(alpha: 0.26)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16),
      );
      canvas.drawRRect(
        body,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              color.withValues(alpha: 0.10),
              color.withValues(alpha: 0.85),
            ],
          ).createShader(rect),
      );

      // Bright cap, inset so it sits inside the rounded top instead of
      // overhanging the corners.
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(rect.left + 5, rect.top + 1.5, barW - 10, 3),
          const Radius.circular(2),
        ),
        Paint()..color = const Color(0xFFFFFFFF).withValues(alpha: 0.85),
      );

      // Reflection on the floor.
      final refl = Rect.fromLTWH(rect.left, baseY + 1, barW, h * 0.3);
      canvas.drawRect(
        refl,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [color.withValues(alpha: 0.16), Colors.transparent],
          ).createShader(refl),
      );

      final level = TextPainter(
        text: TextSpan(
          text: '$lvl',
          style: TextStyle(
            color: color,
            fontSize: 19,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      level.paint(
        canvas,
        Offset(cx - level.width / 2, rect.top - level.height - 8),
      );

      final name = TextPainter(
        text: TextSpan(
          text: id.displayName,
          style: TextStyle(
            color: color.withValues(alpha: 0.7),
            fontSize: 7.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.9,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: slot);
      name.paint(canvas, Offset(cx - name.width / 2, baseY + 14));
    }
  }

  @override
  bool shouldRepaint(covariant _MonolithPainter old) =>
      old.skills != skills || old.axisMax != axisMax;
}

// ══ F · CRYSTAL ═══════════════════════════════════════════════════════════════

/// The diamond cut into four facets, each one owned by its skill. The
/// silhouette is still a single gem, but every quadrant is tinted by the skill
/// that built it, so colour tells you which side of the character is heavy.
class RadarCrystal extends StatelessWidget {
  final List<SkillSummary> skills;

  const RadarCrystal({super.key, required this.skills});

  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        height: 340,
        child: CustomPaint(
          painter:
              _CrystalPainter(skills: skills, axisMax: radarAxisMax(skills)),
        ),
      );
}

class _CrystalPainter extends CustomPainter {
  final List<SkillSummary> skills;
  final int axisMax;

  _CrystalPainter({required this.skills, required this.axisMax});

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = _radiusFor(size);
    final m = _byId(skills);

    // Outline of the full arena, so the gem has something to sit in.
    final hull = Path();
    for (int i = 0; i < 4; i++) {
      final p = _at(c, r, i);
      i == 0 ? hull.moveTo(p.dx, p.dy) : hull.lineTo(p.dx, p.dy);
    }
    hull.close();
    canvas.drawPath(
      hull,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8
        ..color = _gridColor.withValues(alpha: 0.16),
    );

    final pts = [
      for (int i = 0; i < 4; i++) _at(c, r * _frac(m[_order[i]], axisMax), i),
    ];

    // One facet per quadrant, blending the two skills that form its edge.
    for (int i = 0; i < 4; i++) {
      final a = pts[i];
      final b = pts[(i + 1) % 4];
      final blend = Color.lerp(
        skillColor(_order[i]),
        skillColor(_order[(i + 1) % 4]),
        0.5,
      )!;

      final facet = Path()
        ..moveTo(c.dx, c.dy)
        ..lineTo(a.dx, a.dy)
        ..lineTo(b.dx, b.dy)
        ..close();

      // Ramp across the facet's own reach — spanning the whole arena left a
      // short facet sampling only the transparent inner end.
      final reach = max((a - c).distance, (b - c).distance);
      canvas.drawPath(
        facet,
        Paint()
          ..shader = RadialGradient(
            colors: [
              blend.withValues(alpha: 0.10),
              blend.withValues(alpha: 0.58),
            ],
          ).createShader(Rect.fromCircle(center: c, radius: max(reach, 1))),
      );
      // Facet edge catches the light.
      canvas.drawLine(
        a,
        b,
        Paint()
          ..strokeWidth = 1.2
          ..color = blend.withValues(alpha: 0.75),
      );
    }

    // Internal edges from the core out to each vertex — the cut lines.
    for (int i = 0; i < 4; i++) {
      final color = skillColor(_order[i]);
      canvas.drawLine(
        c,
        pts[i],
        Paint()
          ..strokeWidth = 6
          ..color = color.withValues(alpha: 0.20)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
      canvas.drawLine(
        c,
        pts[i],
        Paint()
          ..strokeWidth = 1.0
          ..color = color.withValues(alpha: 0.85),
      );
    }

    _paintCore(canvas, c, radius: 26);

    for (int i = 0; i < 4; i++) {
      final color = skillColor(_order[i]);
      canvas.drawCircle(
        pts[i],
        10,
        Paint()
          ..color = color.withValues(alpha: 0.4)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
      canvas.drawCircle(pts[i], 3.6, Paint()..color = const Color(0xFFFFFFFF));
      _paintLabel(canvas, _at(c, r + 15, i), _order[i],
          m[_order[i]]?.level ?? 1, _anchorFor(i));
    }
  }

  @override
  bool shouldRepaint(covariant _CrystalPainter old) =>
      old.skills != skills || old.axisMax != axisMax;
}

// ══ G · BLOOM ═════════════════════════════════════════════════════════════════

/// Four petals opening out of the core, each one as long as its level. Softer
/// than the beams — the skill has body and weight rather than being a line.
class RadarBloom extends StatelessWidget {
  final List<SkillSummary> skills;

  const RadarBloom({super.key, required this.skills});

  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        height: 340,
        child: CustomPaint(
          painter: _BloomPainter(skills: skills, axisMax: radarAxisMax(skills)),
        ),
      );
}

class _BloomPainter extends CustomPainter {
  final List<SkillSummary> skills;
  final int axisMax;

  _BloomPainter({required this.skills, required this.axisMax});

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = _radiusFor(size);
    final m = _byId(skills);

    canvas.drawCircle(
      c,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8
        ..color = _gridColor.withValues(alpha: 0.14),
    );

    for (int i = 0; i < 4; i++) {
      final id = _order[i];
      final color = skillColor(id);
      final a = _angle(i);
      final dir = Offset(cos(a), sin(a));
      final normal = Offset(-dir.dy, dir.dx);
      final len = r * _frac(m[id], axisMax);
      final w = 16 + len * 0.16;

      // Two quadratics out to the tip and back — a leaf, not a line.
      final petal = Path()
        ..moveTo(c.dx, c.dy)
        ..quadraticBezierTo(
          c.dx + dir.dx * len * 0.42 + normal.dx * w,
          c.dy + dir.dy * len * 0.42 + normal.dy * w,
          c.dx + dir.dx * len,
          c.dy + dir.dy * len,
        )
        ..quadraticBezierTo(
          c.dx + dir.dx * len * 0.42 - normal.dx * w,
          c.dy + dir.dy * len * 0.42 - normal.dy * w,
          c.dx,
          c.dy,
        )
        ..close();

      canvas.drawPath(
        petal,
        Paint()
          ..color = color.withValues(alpha: 0.30)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 13),
      );
      canvas.drawPath(
        petal,
        Paint()
          ..shader = LinearGradient(
            // Base to tip along the petal's own axis, not the whole arena.
            begin: Alignment(-dir.dx, -dir.dy),
            end: Alignment(dir.dx, dir.dy),
            colors: [
              color.withValues(alpha: 0.24),
              color.withValues(alpha: 0.82),
            ],
          ).createShader(petal.getBounds()),
      );
      canvas.drawPath(
        petal,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.1
          ..color = color.withValues(alpha: 0.9),
      );

      _paintLabel(canvas, c + dir * (r + 15), id, m[id]?.level ?? 1,
          _anchorFor(i));
    }

    _paintCore(canvas, c, radius: 30);
  }

  @override
  bool shouldRepaint(covariant _BloomPainter old) =>
      old.skills != skills || old.axisMax != axisMax;
}

// ══ H · NOTCHES ═══════════════════════════════════════════════════════════════

/// Orbits, but each ring is cut into one notch per level. You can literally
/// count the level off the dial, and a level-up lights one more notch —
/// the most game-like way to show progress.
class RadarNotches extends StatelessWidget {
  final List<SkillSummary> skills;

  const RadarNotches({super.key, required this.skills});

  @override
  Widget build(BuildContext context) {
    final m = _byId(skills);
    final axisMax = radarAxisMax(skills);

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 268,
          child: CustomPaint(
            painter: _NotchesPainter(skills: skills, axisMax: axisMax),
          ),
        ),
        const SizedBox(height: 14),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 34),
          child: Row(
            children: [
              for (int i = 0; i < 4; i++)
                Expanded(
                  child: _OrbitKey(
                    id: _order[i],
                    level: m[_order[i]]?.level ?? 1,
                    pct: _frac(m[_order[i]], axisMax),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _NotchesPainter extends CustomPainter {
  final List<SkillSummary> skills;
  final int axisMax;

  _NotchesPainter({required this.skills, required this.axisMax});

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final outer = min(size.width, size.height) / 2 - 16;
    final m = _byId(skills);
    const gap = 20.0;
    const w = 9.0;

    final seg = 2 * pi / axisMax;
    final pad = seg * 0.22; // dark sliver between notches

    for (int i = 0; i < 4; i++) {
      final id = _order[i];
      final color = skillColor(id);
      final rr = outer - i * gap;
      final rect = Rect.fromCircle(center: c, radius: rr);
      final lit = (m[id]?.level ?? 1).clamp(0, axisMax);

      for (int n = 0; n < axisMax; n++) {
        final start = -pi / 2 + n * seg + pad / 2;
        final sweep = seg - pad;
        final on = n < lit;

        if (on) {
          canvas.drawArc(
            rect,
            start,
            sweep,
            false,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = w + 4
              ..color = color.withValues(alpha: 0.28)
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
          );
        }
        canvas.drawArc(
          rect,
          start,
          sweep,
          false,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = w
            ..color = on ? color : const Color(0xFF1E1E27),
        );
      }
    }

    _paintCore(canvas, c, radius: 40);
  }

  @override
  bool shouldRepaint(covariant _NotchesPainter old) =>
      old.skills != skills || old.axisMax != axisMax;
}

// ══ I · CONSTELLATION ═════════════════════════════════════════════════════════

/// The character as a star map. The four skills are stars whose brightness and
/// flare grow with level, joined by faint lines into one constellation. The
/// quietest of all the variants — almost nothing but the dark and four points.
class RadarConstellation extends StatelessWidget {
  final List<SkillSummary> skills;

  const RadarConstellation({super.key, required this.skills});

  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        height: 340,
        child: CustomPaint(
          painter: _ConstellationPainter(
            skills: skills,
            axisMax: radarAxisMax(skills),
          ),
        ),
      );
}

class _ConstellationPainter extends CustomPainter {
  final List<SkillSummary> skills;
  final int axisMax;

  _ConstellationPainter({required this.skills, required this.axisMax});

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = _radiusFor(size);
    final m = _byId(skills);

    // Fixed seed: the sky is the same every time the screen opens.
    final rng = Random(11);
    for (int i = 0; i < 70; i++) {
      final a = rng.nextDouble() * 2 * pi;
      final d = sqrt(rng.nextDouble()) * (r + 22);
      canvas.drawCircle(
        Offset(c.dx + d * cos(a), c.dy + d * sin(a)),
        rng.nextDouble() * 0.9 + 0.3,
        Paint()
          ..color = Colors.white.withValues(alpha: rng.nextDouble() * 0.30 + 0.06),
      );
    }

    final pts = [
      for (int i = 0; i < 4; i++) _at(c, r * _frac(m[_order[i]], axisMax), i),
    ];

    // Constellation lines.
    for (int i = 0; i < 4; i++) {
      canvas.drawLine(
        pts[i],
        pts[(i + 1) % 4],
        Paint()
          ..strokeWidth = 0.9
          ..color = const Color(0xFFBFCBE0).withValues(alpha: 0.30),
      );
    }

    for (int i = 0; i < 4; i++) {
      final p = pts[i];
      final color = skillColor(_order[i]);
      final f = _frac(m[_order[i]], axisMax);
      final flare = 9 + 16 * f;

      canvas.drawCircle(
        p,
        7 + 9 * f,
        Paint()
          ..color = color.withValues(alpha: 0.45)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 8 + 6 * f),
      );
      // Four-point flare — the brighter the skill, the longer the spikes.
      final spike = Paint()
        ..strokeWidth = 1.0
        ..color = Colors.white.withValues(alpha: 0.75);
      canvas.drawLine(p - Offset(flare, 0), p + Offset(flare, 0), spike);
      canvas.drawLine(p - Offset(0, flare), p + Offset(0, flare), spike);
      canvas.drawCircle(p, 2.6 + 1.6 * f, Paint()..color = Colors.white);

      _paintLabel(canvas, _at(c, r + 15, i), _order[i],
          m[_order[i]]?.level ?? 1, _anchorFor(i));
    }
  }

  @override
  bool shouldRepaint(covariant _ConstellationPainter old) =>
      old.skills != skills || old.axisMax != axisMax;
}

// ══ J · ROSE ══════════════════════════════════════════════════════════════════

/// Four wedges, each reaching out as far as its level. Area does the work here,
/// so a big skill genuinely looks big — the strongest read of the whole set,
/// and it fills the circle instead of hanging off a thin line.
class RadarRose extends StatelessWidget {
  final List<SkillSummary> skills;

  const RadarRose({super.key, required this.skills});

  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        height: 340,
        child: CustomPaint(
          painter: _RosePainter(skills: skills, axisMax: radarAxisMax(skills)),
        ),
      );
}

class _RosePainter extends CustomPainter {
  final List<SkillSummary> skills;
  final int axisMax;

  _RosePainter({required this.skills, required this.axisMax});

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = _radiusFor(size);
    final m = _byId(skills);

    for (final f in [0.5, 1.0]) {
      canvas.drawCircle(
        c,
        r * f,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = f == 1.0 ? 0.9 : 0.6
          ..color = _gridColor.withValues(alpha: f == 1.0 ? 0.20 : 0.09),
      );
    }

    const half = 42 * pi / 180; // 4° of night between wedges

    for (int i = 0; i < 4; i++) {
      final id = _order[i];
      final color = skillColor(id);
      final rad = r * _frac(m[id], axisMax);
      final rect = Rect.fromCircle(center: c, radius: rad);
      final start = _angle(i) - half;
      const sweep = half * 2;

      // Built as one closed path: drawArc(useCenter: true) fans the wedge into
      // triangles and the seams show straight through a shader.
      final wedge = Path()
        ..moveTo(c.dx, c.dy)
        ..arcTo(rect, start, sweep, false)
        ..close();

      canvas.drawPath(
        wedge,
        Paint()
          ..color = color.withValues(alpha: 0.22)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
      );
      canvas.drawPath(
        wedge,
        Paint()
          ..shader = RadialGradient(
            colors: [
              color.withValues(alpha: 0.28),
              color.withValues(alpha: 0.70),
            ],
          ).createShader(rect),
      );
      // Lit rim on the outer edge.
      canvas.drawArc(
        rect,
        start,
        sweep,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round
          ..color = Color.lerp(color, Colors.white, 0.45)!,
      );

      _paintLabel(canvas, _at(c, r + 15, i), id, m[id]?.level ?? 1,
          _anchorFor(i));
    }

    _paintCore(canvas, c, radius: 24);
  }

  @override
  bool shouldRepaint(covariant _RosePainter old) =>
      old.skills != skills || old.axisMax != axisMax;
}

// ══ K · RIDGE ═════════════════════════════════════════════════════════════════

/// The four skills as a landscape: a lit ridgeline with a peak for each, filled
/// underneath. Reads left to right like a chart rather than out from a centre,
/// which makes the ranking obvious at the cost of the radial symmetry.
class RadarRidge extends StatelessWidget {
  final List<SkillSummary> skills;

  const RadarRidge({super.key, required this.skills});

  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        height: 300,
        child: CustomPaint(
          painter: _RidgePainter(skills: skills, axisMax: radarAxisMax(skills)),
        ),
      );
}

class _RidgePainter extends CustomPainter {
  final List<SkillSummary> skills;
  final int axisMax;

  _RidgePainter({required this.skills, required this.axisMax});

  @override
  void paint(Canvas canvas, Size size) {
    final m = _byId(skills);
    const padX = 76.0;
    final baseY = size.height - 42;
    final maxH = baseY - 66;
    final step = (size.width - padX * 2) / 3;

    final peaks = [
      for (int i = 0; i < 4; i++)
        Offset(
          padX + step * i,
          baseY - (14 + (maxH - 14) * _frac(m[_order[i]], axisMax)),
        ),
    ];

    // Smooth ridge through the peaks, running off both edges.
    final ridge = Path()..moveTo(0, peaks.first.dy);
    ridge.lineTo(peaks.first.dx, peaks.first.dy);
    for (int i = 0; i < peaks.length - 1; i++) {
      final a = peaks[i];
      final b = peaks[i + 1];
      final mx = (a.dx + b.dx) / 2;
      ridge.cubicTo(mx, a.dy, mx, b.dy, b.dx, b.dy);
    }
    ridge.lineTo(size.width, peaks.last.dy);

    final fill = Path.from(ridge)
      ..lineTo(size.width, baseY)
      ..lineTo(0, baseY)
      ..close();

    canvas.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            RpgColors.accent.withValues(alpha: 0.42),
            RpgColors.accent.withValues(alpha: 0.03),
          ],
        ).createShader(Rect.fromLTRB(0, 0, size.width, baseY)),
    );

    _glowStroke(
      canvas,
      ridge,
      halo: const Color(0xFFE74C3C).withValues(alpha: 0.28),
      bloom: const Color(0xFFFF7A6B).withValues(alpha: 0.50),
      core: const Color(0xFFFFD9D2),
      scale: 0.85,
    );

    canvas.drawLine(
      Offset(0, baseY),
      Offset(size.width, baseY),
      Paint()
        ..strokeWidth = 1
        ..color = _gridColor.withValues(alpha: 0.16),
    );

    for (int i = 0; i < 4; i++) {
      final id = _order[i];
      final color = skillColor(id);
      final p = peaks[i];

      canvas.drawLine(
        p,
        Offset(p.dx, baseY),
        Paint()
          ..strokeWidth = 0.7
          ..color = color.withValues(alpha: 0.25),
      );
      canvas.drawCircle(
        p,
        10,
        Paint()
          ..color = color.withValues(alpha: 0.4)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
      canvas.drawCircle(p, 5, Paint()..color = RpgColors.pageBg);
      canvas.drawCircle(
        p,
        5,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6
          ..color = color,
      );

      final level = TextPainter(
        text: TextSpan(
          text: '${m[id]?.level ?? 1}',
          style: TextStyle(
            color: color,
            fontSize: 17,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.4,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      level.paint(canvas, Offset(p.dx - level.width / 2, p.dy - 30));

      final name = TextPainter(
        text: TextSpan(
          text: id.displayName,
          style: TextStyle(
            color: color.withValues(alpha: 0.7),
            fontSize: 7.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.9,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      name.paint(canvas, Offset(p.dx - name.width / 2, baseY + 13));
    }
  }

  @override
  bool shouldRepaint(covariant _RidgePainter old) =>
      old.skills != skills || old.axisMax != axisMax;
}

// ══ L · HALO ══════════════════════════════════════════════════════════════════

/// One ring, four quarters, each as thick as its skill is strong. The most
/// restrained of the set — a single clean circle around the core, with the
/// level printed at each quarter.
class RadarHalo extends StatelessWidget {
  final List<SkillSummary> skills;

  const RadarHalo({super.key, required this.skills});

  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        height: 320,
        child: CustomPaint(
          painter: _HaloPainter(skills: skills, axisMax: radarAxisMax(skills)),
        ),
      );
}

class _HaloPainter extends CustomPainter {
  final List<SkillSummary> skills;
  final int axisMax;

  _HaloPainter({required this.skills, required this.axisMax});

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = _radiusFor(size) * 0.82;
    final m = _byId(skills);
    // Butt caps and a wide gap: a round cap overhangs by half the stroke, so a
    // thick quarter used to run into its neighbour and the four read as one.
    const half = 39 * pi / 180;

    for (int i = 0; i < 4; i++) {
      final id = _order[i];
      final color = skillColor(id);
      final f = _frac(m[id], axisMax);
      final w = 5 + 26 * f;
      final rect = Rect.fromCircle(center: c, radius: r);
      final start = _angle(i) - half;
      const sweep = half * 2;

      canvas.drawArc(
        rect,
        start,
        sweep,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = w + 6
          ..strokeCap = StrokeCap.butt
          ..color = color.withValues(alpha: 0.26)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
      );
      canvas.drawArc(
        rect,
        start,
        sweep,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = w
          ..strokeCap = StrokeCap.butt
          ..shader = SweepGradient(
            colors: [
              color.withValues(alpha: 0.55),
              color,
              color.withValues(alpha: 0.55),
            ],
            startAngle: start,
            endAngle: start + sweep,
            transform: GradientRotation(start),
          ).createShader(rect),
      );

      _paintLabel(canvas, _at(c, r + 30, i), id, m[id]?.level ?? 1,
          _anchorFor(i));
    }

    _paintCore(canvas, c, radius: 44);
  }

  @override
  bool shouldRepaint(covariant _HaloPainter old) =>
      old.skills != skills || old.axisMax != axisMax;
}
