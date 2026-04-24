import 'package:flutter/material.dart';

import '../../domain/entities/skill_summary.dart';
import 'rpg_colors.dart';

void showSkillMilestoneSheet(BuildContext context, SkillSummary skill) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => _MilestoneSheet(skill: skill),
  );
}

// ── Color mapping ─────────────────────────────────────────────────────────────

Color _skillColor(SkillId id) {
  switch (id) {
    case SkillId.japanese:
      return const Color(0xFF4FC3F7);
    case SkillId.wealth:
      return const Color(0xFFFFD54F);
    case SkillId.mindfulness:
      return const Color(0xFF26A69A);
  }
}

// ── Sheet root ────────────────────────────────────────────────────────────────

class _MilestoneSheet extends StatefulWidget {
  final SkillSummary skill;

  const _MilestoneSheet({required this.skill});

  @override
  State<_MilestoneSheet> createState() => _MilestoneSheetState();
}

class _MilestoneSheetState extends State<_MilestoneSheet>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  static const _count = 5;

  // 1 header animation + 5 milestone animations
  late final List<Animation<double>> _anims;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _anims = List.generate(_count + 1, (i) {
      final start = i * 0.10;
      final end = (start + 0.45).clamp(0.0, 1.0);
      return CurvedAnimation(
        parent: _ctrl,
        curve: Interval(start, end, curve: Curves.easeOutCubic),
      );
    });
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = _skillColor(widget.skill.skill);
    final milestones = widget.skill.nextLevelMilestones();
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: BoxDecoration(
        color: RpgColors.panelBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        border: Border.all(color: RpgColors.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 4),
              width: 40,
              height: 3,
              decoration: BoxDecoration(
                color: RpgColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Colored top accent line
          Container(height: 1, color: color.withValues(alpha: 0.4)),

          SingleChildScrollView(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 24,
              bottom: 24 + bottomPad,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ────────────────────────────────────────────────
                FadeTransition(
                  opacity: _anims[0],
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.15),
                      end: Offset.zero,
                    ).animate(_anims[0]),
                    child: _SheetHeader(skill: widget.skill, color: color),
                  ),
                ),

                const SizedBox(height: 28),

                // ── Section label ─────────────────────────────────────────
                FadeTransition(
                  opacity: _anims[0],
                  child: const Text(
                    'ASCENSION PATH',
                    style: TextStyle(
                      color: RpgColors.textMuted,
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 2.4,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // ── Milestone path ────────────────────────────────────────
                _AscensionPath(
                  milestones: milestones,
                  color: color,
                  animations: _anims.sublist(1),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _SheetHeader extends StatelessWidget {
  final SkillSummary skill;
  final Color color;

  const _SheetHeader({required this.skill, required this.color});

  @override
  Widget build(BuildContext context) {
    final hasMastery = skill.mastery > 0;
    final levelLabel =
        hasMastery ? 'MASTERY +${skill.mastery}' : 'LEVEL ${skill.level}';
    final progress = skill.progressToNextLevel;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Glow bar
        Container(
          width: 3,
          height: 60,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.5),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Skill name
              Text(
                skill.skill.displayName,
                style: TextStyle(
                  color: color,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2.4,
                ),
              ),
              const SizedBox(height: 2),
              // Descriptor + level badge on same line
              Row(
                children: [
                  Expanded(
                    child: Text(
                      skill.skill.descriptor,
                      style: const TextStyle(
                        color: RpgColors.textSecondary,
                        fontSize: 11,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      border: Border.all(
                          color: color.withValues(alpha: 0.4), width: 1),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Text(
                      levelLabel,
                      style: TextStyle(
                        color: color,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Progress bar
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: progress),
                duration: const Duration(milliseconds: 1000),
                curve: Curves.easeOutCubic,
                builder: (_, v, _) => ClipRRect(
                  borderRadius: BorderRadius.circular(1),
                  child: LinearProgressIndicator(
                    value: v,
                    backgroundColor: RpgColors.progressTrack,
                    valueColor: AlwaysStoppedAnimation(color),
                    minHeight: 3,
                  ),
                ),
              ),
              const SizedBox(height: 5),
              Text(
                '${(progress * 100).round()}%  ·  ${skill.remainingToNextLevel} to '
                '${hasMastery ? 'mastery +${skill.mastery + 1}' : 'level ${skill.level + 1}'}',
                style: TextStyle(
                  color: RpgColors.textMuted.withValues(alpha: 0.8),
                  fontSize: 9,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Ascension path ────────────────────────────────────────────────────────────

class _AscensionPath extends StatelessWidget {
  final List<({int level, bool isMastery, String remaining, String? target})> milestones;
  final Color color;
  final List<Animation<double>> animations;

  const _AscensionPath({
    required this.milestones,
    required this.color,
    required this.animations,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(milestones.length, (i) {
        final anim =
            animations[i.clamp(0, animations.length - 1)];
        final isLast = i == milestones.length - 1;
        // Each successive milestone fades
        final dimFactor = 1.0 - i * 0.14;

        return FadeTransition(
          opacity: anim,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.25),
              end: Offset.zero,
            ).animate(anim),
            child: _MilestoneRow(
              milestone: milestones[i],
              index: i,
              isLast: isLast,
              color: color,
              dimFactor: dimFactor.clamp(0.35, 1.0),
            ),
          ),
        );
      }),
    );
  }
}

// ── Single milestone row ──────────────────────────────────────────────────────

class _MilestoneRow extends StatelessWidget {
  final ({int level, bool isMastery, String remaining, String? target}) milestone;
  final int index;
  final bool isLast;
  final Color color;
  final double dimFactor;

  const _MilestoneRow({
    required this.milestone,
    required this.index,
    required this.isLast,
    required this.color,
    required this.dimFactor,
  });

  @override
  Widget build(BuildContext context) {
    final nodeColor = color.withValues(alpha: dimFactor);
    final nodeLabel = milestone.isMastery
        ? '+${milestone.level}'
        : '${milestone.level}';
    final levelTitle = milestone.isMastery
        ? 'MASTERY +${milestone.level}'
        : 'LEVEL ${milestone.level}';

    // First milestone is the next immediate one — make it slightly larger
    final isNext = index == 0;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Timeline column ──────────────────────────────────────────────
          SizedBox(
            width: 44,
            child: Column(
              children: [
                // Node
                _Node(
                  label: nodeLabel,
                  color: nodeColor,
                  isNext: isNext,
                ),
                // Connector line to next
                if (!isLast)
                  Expanded(
                    child: Center(
                      child: Container(
                        width: 1,
                        color: color.withValues(alpha: dimFactor * 0.3),
                        margin: const EdgeInsets.symmetric(vertical: 4),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // ── Content ──────────────────────────────────────────────────────
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                left: 12,
                bottom: isLast ? 0 : 20,
                top: isNext ? 2 : 4,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Label
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          levelTitle,
                          style: TextStyle(
                            color: nodeColor,
                            fontSize: isNext ? 12 : 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.6,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'cumulative from now',
                          style: TextStyle(
                            color: RpgColors.textMuted
                                .withValues(alpha: dimFactor * 0.7),
                            fontSize: 9,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Remaining + optional total target (wealth only)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '+${milestone.remaining}',
                        style: TextStyle(
                          color: nodeColor,
                          fontSize: isNext ? 22 : 18,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.5,
                          height: 1.1,
                        ),
                      ),
                      if (milestone.target != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          '${milestone.target} total',
                          style: TextStyle(
                            color: nodeColor.withValues(alpha: 0.55),
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Node circle ───────────────────────────────────────────────────────────────

class _Node extends StatelessWidget {
  final String label;
  final Color color;
  final bool isNext;

  const _Node({required this.label, required this.color, required this.isNext});

  @override
  Widget build(BuildContext context) {
    final size = isNext ? 36.0 : 30.0;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isNext ? color.withValues(alpha: 0.12) : Colors.transparent,
        border: Border.all(
          color: color,
          width: isNext ? 1.5 : 1.0,
        ),
        boxShadow: isNext
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.25),
                  blurRadius: 10,
                  spreadRadius: 1,
                )
              ]
            : null,
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: label.length > 2 ? 8 : (isNext ? 11 : 9),
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
      ),
    );
  }
}
