import 'dart:math';

import 'package:flutter/material.dart';

import '../../domain/entities/quest.dart';

// ── Palette: a tavern board — dark planks, aged parchment, iron-gall ink ─────

const _woodDark = Color(0xFF1C130C);
const _woodMid = Color(0xFF2B1D13);
const _woodLight = Color(0xFF342319);
const _seam = Color(0xFF100A06);

const _parchmentLight = Color(0xFFF2E6C6);
const _parchment = Color(0xFFE5D2A6);
const _parchmentDark = Color(0xFFD3BA84);

const _ink = Color(0xFF3A2716);
const _inkFaded = Color(0xFF6E5638);
const _inkRed = Color(0xFF9B2B1F);
const _inkGreen = Color(0xFF2F6B35);
const _inkAmber = Color(0xFF9A6512);

/// Lettering on the wood itself — bone white, not paper.
const _chalk = Color(0xFFE9D8B4);

/// Rank as it reads on paper: wax and ink, darker than the neon elsewhere.
const _rankColors = {
  QuestDifficulty.side: Color(0xFF56616B),
  QuestDifficulty.normal: Color(0xFFA06A12),
  QuestDifficulty.epic: Color(0xFF6E3A86),
  QuestDifficulty.legendary: Color(0xFFA3261C),
};

const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

/// A system serif — Georgia on Apple platforms, Noto Serif on Android — so the
/// notices read as print without bundling a font.
TextStyle _type(
  double size, {
  Color color = _ink,
  FontWeight weight = FontWeight.w400,
  FontStyle? style,
  double spacing = 0,
  double? height,
  TextDecoration? decoration,
  List<Shadow>? shadows,
}) =>
    TextStyle(
      fontFamily: 'Georgia',
      fontFamilyFallback: const ['serif'],
      fontSize: size,
      color: color,
      fontWeight: weight,
      fontStyle: style,
      letterSpacing: spacing,
      height: height,
      decoration: decoration,
      decorationColor: color,
      shadows: shadows,
    );

String _fmtDate(DateTime d) => '${d.day} ${_months[d.month - 1]} ${d.year}';

String _fmtDays(int days) {
  if (days == 1) return '1 day';
  if (days < 60) return '$days days';
  if (days < 365) return '${(days / 30).round()} months';
  return '${(days / 365).toStringAsFixed(1)} years';
}

/// Notices hang a little crooked, and always the same way for the same quest.
double _tiltFor(String id) {
  final h = id.codeUnits.fold(0, (a, b) => (a * 31 + b) & 0x7fffffff);
  const degrees = [-1.4, -0.6, 0.5, 1.1, -0.9, 0.8];
  return degrees[h % degrees.length] * pi / 180;
}

// ── The board ─────────────────────────────────────────────────────────────────

/// Framed planks with the sign on top; everything else is pinned to it.
class QuestBoard extends StatelessWidget {
  final int openCount;
  final int fulfilledCount;
  final List<Widget> children;

  const QuestBoard({
    super.key,
    required this.openCount,
    required this.fulfilledCount,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: _woodDark,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: _seam, width: 5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.6),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(2),
        child: CustomPaint(
          painter: const _PlanksPainter(),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _BoardSign(open: openCount, fulfilled: fulfilledCount),
                const SizedBox(height: 22),
                ...children,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PlanksPainter extends CustomPainter {
  const _PlanksPainter();

  @override
  void paint(Canvas canvas, Size size) {
    const planks = 4;
    const shades = [_woodMid, _woodLight, _woodMid, Color(0xFF2F2016)];
    final w = size.width / planks;
    // Seeded, so the grain is identical on every repaint.
    final rnd = Random(25);

    for (int i = 0; i < planks; i++) {
      final rect = Rect.fromLTWH(i * w, 0, w, size.height);
      final base = shades[i];
      canvas.drawRect(
        rect,
        Paint()
          ..shader = LinearGradient(
            colors: [
              Color.lerp(base, _woodDark, 0.4)!,
              base,
              Color.lerp(base, _woodDark, 0.25)!,
            ],
            stops: const [0.0, 0.45, 1.0],
          ).createShader(rect),
      );

      // Grain: long wavering strokes down the plank.
      for (int g = 0; g < 8; g++) {
        final x = rect.left + 6 + rnd.nextDouble() * (w - 12);
        final sway = 1.5 + rnd.nextDouble() * 3.5;
        final period = 50 + rnd.nextDouble() * 60;
        final path = Path()..moveTo(x, 0);
        for (double y = 0; y <= size.height; y += 24) {
          path.lineTo(x + sin(y / period + g) * sway, y);
        }
        canvas.drawPath(
          path,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = g.isEven ? 1.0 : 0.6
            ..color = g.isEven
                ? Colors.black.withValues(alpha: 0.22)
                : const Color(0xFFFFE2BF).withValues(alpha: 0.04),
        );
      }

      // A knot or two.
      if (rnd.nextBool()) {
        final knot = Offset(
          rect.left + w * (0.3 + rnd.nextDouble() * 0.4),
          size.height * rnd.nextDouble(),
        );
        canvas.drawOval(
          Rect.fromCenter(center: knot, width: 9, height: 22),
          Paint()..color = Colors.black.withValues(alpha: 0.28),
        );
      }

      if (i > 0) {
        canvas.drawLine(
          Offset(rect.left, 0),
          Offset(rect.left, size.height),
          Paint()
            ..color = _seam
            ..strokeWidth = 2.5,
        );
        canvas.drawLine(
          Offset(rect.left + 2, 0),
          Offset(rect.left + 2, size.height),
          Paint()
            ..color = const Color(0xFFFFE2BF).withValues(alpha: 0.05)
            ..strokeWidth = 1,
        );
      }
    }

    // The edges fall into shadow under the frame.
    final all = Offset.zero & size;
    canvas.drawRect(
      all,
      Paint()
        ..shader = LinearGradient(
          colors: [
            Colors.black.withValues(alpha: 0.4),
            Colors.transparent,
            Colors.transparent,
            Colors.black.withValues(alpha: 0.4),
          ],
          stops: const [0.0, 0.1, 0.9, 1.0],
        ).createShader(all),
    );
  }

  @override
  bool shouldRepaint(covariant _PlanksPainter old) => false;
}

class _BoardSign extends StatelessWidget {
  final int open;
  final int fulfilled;

  const _BoardSign({required this.open, required this.fulfilled});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.only(top: 18),
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF5E422C), Color(0xFF3E2A1B)],
            ),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: const Color(0xFF1A110A), width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.55),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const _Nail(),
              const SizedBox(width: 14),
              Text(
                'QUEST BOARD',
                style: _type(
                  19,
                  color: _chalk,
                  weight: FontWeight.w700,
                  spacing: 4,
                  shadows: const [
                    Shadow(color: Colors.black, offset: Offset(0, 1.5)),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              const _Nail(),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Text(
          '$open open  ·  $fulfilled fulfilled',
          style: _type(
            13,
            color: _chalk.withValues(alpha: 0.6),
            style: FontStyle.italic,
          ),
        ),
      ],
    );
  }
}

class _Nail extends StatelessWidget {
  const _Nail();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 7,
      height: 7,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: Alignment(-0.4, -0.4),
          colors: [Color(0xFFB8B2A8), Color(0xFF4A4640)],
        ),
      ),
    );
  }
}

// ── Paper, pins and seals ─────────────────────────────────────────────────────

class _Parchment extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;

  const _Parchment({required this.child, required this.padding});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(2),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_parchmentLight, _parchment, _parchmentDark],
          stops: [0.0, 0.55, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.55),
            blurRadius: 10,
            offset: const Offset(2, 7),
          ),
        ],
      ),
      // Age at the edges, over the ink as well as the paper.
      foregroundDecoration: BoxDecoration(
        borderRadius: BorderRadius.circular(2),
        gradient: const RadialGradient(
          radius: 1.1,
          colors: [Colors.transparent, Color(0x4D6B4520)],
          stops: [0.6, 1.0],
        ),
      ),
      child: child,
    );
  }
}

class _Pin extends StatelessWidget {
  const _Pin();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(
          center: Alignment(-0.35, -0.4),
          colors: [Color(0xFFFF8A80), Color(0xFFC62828), Color(0xFF6E1111)],
          stops: [0.0, 0.45, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.6),
            blurRadius: 4,
            offset: const Offset(1.5, 3),
          ),
        ],
      ),
    );
  }
}

/// Rank pressed in wax: the initial of the difficulty in its colour.
class _WaxSeal extends StatelessWidget {
  final QuestDifficulty difficulty;

  const _WaxSeal({required this.difficulty});

  @override
  Widget build(BuildContext context) {
    final color = _rankColors[difficulty]!;
    return Transform.rotate(
      angle: -0.2,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            center: const Alignment(-0.3, -0.35),
            colors: [
              Color.lerp(color, Colors.white, 0.25)!,
              color,
              Color.lerp(color, Colors.black, 0.4)!,
            ],
            stops: const [0.0, 0.55, 1.0],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 3,
              offset: const Offset(1, 2),
            ),
          ],
        ),
        child: Center(
          child: Container(
            width: 29,
            height: 29,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.black.withValues(alpha: 0.25),
                width: 1.2,
              ),
            ),
            child: Center(
              child: Text(
                difficulty.displayName[0],
                style: _type(
                  16,
                  color: const Color(0xFFF7E9E4).withValues(alpha: 0.9),
                  weight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InkRule extends StatelessWidget {
  const _InkRule();

  @override
  Widget build(BuildContext context) {
    final line = Expanded(
      child: Container(height: 1, color: _ink.withValues(alpha: 0.25)),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(
        children: [
          line,
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 7),
            child: Transform.rotate(
              angle: pi / 4,
              child: Container(
                width: 5,
                height: 5,
                color: _ink.withValues(alpha: 0.45),
              ),
            ),
          ),
          line,
        ],
      ),
    );
  }
}

class _InkButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _InkButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(3),
          border: Border.all(color: color.withValues(alpha: 0.75), width: 1.3),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: color),
            const SizedBox(width: 5),
            Text(
              label,
              style: _type(14, color: color, weight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

class _InkIcon extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final Color color;

  const _InkIcon({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.color = _inkFaded,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, size: 20),
      color: color,
      onPressed: onTap,
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
    );
  }
}

// ── An open quest ─────────────────────────────────────────────────────────────

class QuestNotice extends StatelessWidget {
  final Quest quest;
  final VoidCallback onEdit;
  final VoidCallback onComplete;
  final VoidCallback onDelete;
  final ValueChanged<String> onToggleObjective;

  const QuestNotice({
    super.key,
    required this.quest,
    required this.onEdit,
    required this.onComplete,
    required this.onDelete,
    required this.onToggleObjective,
  });

  @override
  Widget build(BuildContext context) {
    final q = quest;
    final rank = _rankColors[q.difficulty]!;

    return Padding(
      padding: const EdgeInsets.only(bottom: 26),
      child: Transform.rotate(
        angle: _tiltFor(q.id),
        child: Stack(
          // Pass the board's width through, so every notice spans it.
          fit: StackFit.passthrough,
          clipBehavior: Clip.none,
          children: [
            _Parchment(
              padding: const EdgeInsets.fromLTRB(18, 24, 10, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 52),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${q.difficulty.displayName.toUpperCase()} QUEST',
                          style: _type(
                            10,
                            color: rank,
                            weight: FontWeight.w700,
                            spacing: 2.6,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          q.title,
                          style: _type(
                            22,
                            weight: FontWeight.w700,
                            height: 1.15,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (q.description != null) ...[
                          const SizedBox(height: 7),
                          Text(
                            q.description!,
                            style: _type(
                              14,
                              color: _inkFaded,
                              style: FontStyle.italic,
                              height: 1.35,
                            ),
                          ),
                        ],
                        const _InkRule(),
                        if (q.objectives.isNotEmpty) ...[
                          _Objectives(
                            quest: q,
                            onToggle: onToggleObjective,
                          ),
                          const SizedBox(height: 8),
                        ],
                        if (q.daysLeft != null) _DueLine(quest: q),
                        if (q.pace == QuestPace.onTrack ||
                            q.pace == QuestPace.behind)
                          _PaceLine(quest: q),
                        if (q.hasReward) _RewardLine(quest: q),
                        if (q.objectives.isEmpty &&
                            q.daysLeft == null &&
                            !q.hasReward)
                          Text(
                            'No terms set. Tap the quill to add steps, a '
                            'deadline or a reward.',
                            style: _type(
                              12.5,
                              color: _inkFaded,
                              style: FontStyle.italic,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _InkButton(
                        icon: Icons.check,
                        label: 'Fulfil',
                        color: _inkGreen,
                        onTap: onComplete,
                      ),
                      const Spacer(),
                      _InkIcon(
                        icon: Icons.history_edu,
                        tooltip: 'Edit',
                        onTap: onEdit,
                      ),
                      _InkIcon(
                        icon: Icons.close,
                        tooltip: 'Tear down',
                        onTap: onDelete,
                        color: _inkRed,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Positioned(
              top: -7,
              left: 0,
              right: 0,
              child: Center(child: _Pin()),
            ),
            Positioned(
              top: 16,
              right: 14,
              child: _WaxSeal(difficulty: q.difficulty),
            ),
          ],
        ),
      ),
    );
  }
}

class _Objectives extends StatelessWidget {
  final Quest quest;
  final ValueChanged<String> onToggle;

  const _Objectives({required this.quest, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final done = quest.completedObjectives;
    final total = quest.objectives.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'TASKS',
              style: _type(
                10,
                color: _inkFaded,
                weight: FontWeight.w700,
                spacing: 2.4,
              ),
            ),
            const Spacer(),
            Text(
              '$done of $total',
              style: _type(12, color: _inkFaded, style: FontStyle.italic),
            ),
          ],
        ),
        const SizedBox(height: 6),
        for (final o in quest.objectives)
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => onToggle(o.id),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 2),
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2),
                      border: Border.all(
                        color: _ink.withValues(alpha: 0.7),
                        width: 1.3,
                      ),
                    ),
                    child: o.completed
                        ? const Icon(Icons.check, size: 14, color: _inkGreen)
                        : null,
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      o.text,
                      style: _type(
                        15,
                        color: o.completed ? _inkFaded : _ink,
                        height: 1.3,
                        decoration:
                            o.completed ? TextDecoration.lineThrough : null,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _DueLine extends StatelessWidget {
  final Quest quest;

  const _DueLine({required this.quest});

  @override
  Widget build(BuildContext context) {
    final left = quest.daysLeft!;
    final date = _fmtDate(quest.targetDate!);
    final (text, color) = switch (left) {
      < 0 => ('Due $date — ${_fmtDays(-left)} overdue', _inkRed),
      0 => ('Due today', _inkRed),
      <= 14 => ('Due $date — ${_fmtDays(left)} left', _inkAmber),
      _ => ('Due $date — ${_fmtDays(left)} left', _inkFaded),
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(Icons.hourglass_bottom, size: 15, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: _type(14, color: color, style: FontStyle.italic),
            ),
          ),
        ],
      ),
    );
  }
}

/// Tasks done against time spent, so a quest quietly falling behind says so.
class _PaceLine extends StatelessWidget {
  final Quest quest;

  const _PaceLine({required this.quest});

  @override
  Widget build(BuildContext context) {
    final onTrack = quest.pace == QuestPace.onTrack;
    final color = onTrack ? _inkGreen : _inkAmber;
    final elapsed = quest.timeElapsedFraction;
    final done = quest.objectiveFraction;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(
            onTrack ? Icons.trending_up : Icons.trending_down,
            size: 15,
            color: color,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              [
                onTrack ? 'On pace' : 'Behind pace',
                if (elapsed != null && done != null)
                  '${(done * 100).round()}% done, '
                      '${(elapsed * 100).round()}% of the time gone',
              ].join(' — '),
              style: _type(14, color: color, style: FontStyle.italic),
            ),
          ),
        ],
      ),
    );
  }
}

/// The prize: locked while the quest is open, claimable once it is fulfilled,
/// crossed out once collected.
class _RewardLine extends StatelessWidget {
  final Quest quest;
  final VoidCallback? onClaim;

  const _RewardLine({required this.quest, this.onClaim});

  @override
  Widget build(BuildContext context) {
    final claimable = quest.isRewardClaimable;
    final claimed = quest.isRewardClaimed;
    final cost = quest.rewardCostCents;

    final (icon, note) = claimed
        ? (Icons.check_circle_outline, 'Claimed')
        : claimable
            ? (Icons.card_giftcard, 'Ready to claim')
            : (Icons.lock_outline, 'Locked until fulfilled');

    return Container(
      margin: const EdgeInsets.only(top: 4, bottom: 4),
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: BoxDecoration(
        color: _ink.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: _ink.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 17, color: claimable ? _inkGreen : _inkFaded),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'REWARD',
                  style: _type(
                    9,
                    color: _inkFaded,
                    weight: FontWeight.w700,
                    spacing: 2.4,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  quest.rewardText!,
                  style: _type(
                    15,
                    weight: FontWeight.w700,
                    color: claimed ? _inkFaded : _ink,
                    decoration: claimed ? TextDecoration.lineThrough : null,
                  ),
                ),
                Text(
                  note,
                  style: _type(
                    11.5,
                    color: claimable ? _inkGreen : _inkFaded,
                    style: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          if (cost != null && !claimed)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Text(
                '€${(cost / 100).round()}',
                style: _type(17, weight: FontWeight.w700),
              ),
            ),
          if (claimable && onClaim != null) ...[
            const SizedBox(width: 10),
            _InkButton(
              icon: Icons.card_giftcard,
              label: 'Claim',
              color: _inkGreen,
              onTap: onClaim!,
            ),
          ],
        ],
      ),
    );
  }
}

// ── Posting a new one ─────────────────────────────────────────────────────────

class PostQuestSlip extends StatelessWidget {
  final VoidCallback onTap;

  const PostQuestSlip({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Transform.rotate(
          angle: 0.7 * pi / 180,
          child: Opacity(
            opacity: 0.72,
            child: Stack(
              fit: StackFit.passthrough,
              clipBehavior: Clip.none,
              children: [
                _Parchment(
                  padding: const EdgeInsets.symmetric(vertical: 22),
                  child: Column(
                    children: [
                      const Icon(Icons.add, size: 24, color: _inkFaded),
                      const SizedBox(height: 4),
                      Text(
                        'Post a new quest',
                        style: _type(
                          17,
                          color: _inkFaded,
                          weight: FontWeight.w700,
                          style: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
                const Positioned(
                  top: -7,
                  left: 0,
                  right: 0,
                  child: Center(child: _Pin()),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Shown on the board when nothing is pinned to it.
class EmptyBoardNote extends StatelessWidget {
  const EmptyBoardNote({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Text(
        'Nothing is posted. The board is waiting.',
        textAlign: TextAlign.center,
        style: _type(
          14,
          color: _chalk.withValues(alpha: 0.55),
          style: FontStyle.italic,
        ),
      ),
    );
  }
}

// ── Fulfilled ─────────────────────────────────────────────────────────────────

/// Finished notices, kept below the open ones and folded away by default.
class FulfilledShelf extends StatefulWidget {
  final List<Quest> quests;
  final ValueChanged<Quest> onReopen;
  final ValueChanged<Quest> onDelete;
  final ValueChanged<Quest> onClaimReward;

  const FulfilledShelf({
    super.key,
    required this.quests,
    required this.onReopen,
    required this.onDelete,
    required this.onClaimReward,
  });

  @override
  State<FulfilledShelf> createState() => _FulfilledShelfState();
}

class _FulfilledShelfState extends State<FulfilledShelf> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final line = Expanded(
      child: Container(height: 1, color: _chalk.withValues(alpha: 0.15)),
    );
    // A prize waiting to be collected should not hide behind the fold.
    final waiting = widget.quests.where((q) => q.isRewardClaimable).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => setState(() => _open = !_open),
          child: Padding(
            padding: const EdgeInsets.only(top: 16, bottom: 14),
            child: Row(
              children: [
                line,
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    'FULFILLED  ·  ${widget.quests.length}'
                    '${waiting > 0 ? '  ·  $waiting TO CLAIM' : ''}',
                    style: _type(
                      11,
                      color: _chalk.withValues(alpha: 0.65),
                      weight: FontWeight.w700,
                      spacing: 2.6,
                    ),
                  ),
                ),
                Icon(
                  _open ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  size: 18,
                  color: _chalk.withValues(alpha: 0.55),
                ),
                const SizedBox(width: 6),
                line,
              ],
            ),
          ),
        ),
        if (_open)
          for (final q in widget.quests)
            _FulfilledNotice(
              quest: q,
              onReopen: () => widget.onReopen(q),
              onDelete: () => widget.onDelete(q),
              onClaimReward: () => widget.onClaimReward(q),
            ),
      ],
    );
  }
}

class _FulfilledNotice extends StatelessWidget {
  final Quest quest;
  final VoidCallback onReopen;
  final VoidCallback onDelete;
  final VoidCallback onClaimReward;

  const _FulfilledNotice({
    required this.quest,
    required this.onReopen,
    required this.onDelete,
    required this.onClaimReward,
  });

  @override
  Widget build(BuildContext context) {
    final q = quest;
    final rank = _rankColors[q.difficulty]!;

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Transform.rotate(
        angle: _tiltFor(q.id),
        child: Stack(
          // Pass the board's width through, so every notice spans it.
          fit: StackFit.passthrough,
          clipBehavior: Clip.none,
          children: [
            _Parchment(
              padding: const EdgeInsets.fromLTRB(16, 18, 6, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 110),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${q.difficulty.displayName.toUpperCase()} QUEST',
                          style: _type(
                            9.5,
                            color: rank.withValues(alpha: 0.8),
                            weight: FontWeight.w700,
                            spacing: 2.4,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          q.title,
                          style: _type(
                            18,
                            weight: FontWeight.w700,
                            color: _ink.withValues(alpha: 0.8),
                            height: 1.15,
                          ),
                        ),
                        if (q.completedAt != null) ...[
                          const SizedBox(height: 3),
                          Text(
                            'Fulfilled ${_fmtDate(q.completedAt!.toLocal())}',
                            style: _type(
                              12.5,
                              color: _inkFaded,
                              style: FontStyle.italic,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (q.hasReward)
                    Padding(
                      padding: const EdgeInsets.only(top: 8, right: 10),
                      child: _RewardLine(quest: q, onClaim: onClaimReward),
                    ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      _InkIcon(
                        icon: Icons.replay,
                        tooltip: 'Reopen',
                        onTap: onReopen,
                      ),
                      _InkIcon(
                        icon: Icons.close,
                        tooltip: 'Tear down',
                        onTap: onDelete,
                        color: _inkRed,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Positioned(
              top: -7,
              left: 0,
              right: 0,
              child: Center(child: _Pin()),
            ),
            const Positioned(top: 22, right: 16, child: _Stamp()),
          ],
        ),
      ),
    );
  }
}

class _Stamp extends StatelessWidget {
  const _Stamp();

  @override
  Widget build(BuildContext context) {
    final red = _inkRed.withValues(alpha: 0.8);
    return Transform.rotate(
      angle: -0.24,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(3),
          border: Border.all(color: red, width: 2),
        ),
        child: Text(
          'FULFILLED',
          style: _type(13, color: red, weight: FontWeight.w800, spacing: 2),
        ),
      ),
    );
  }
}
