import 'package:flutter/material.dart';

import '../../domain/entities/skill_summary.dart';
import 'player_row.dart';
import 'rpg_colors.dart';
import 'skill_colors.dart';

/// A single skill in the Skills list.
///
/// Was three dense columns (name+descriptor | big level | status+bar+remaining)
/// which fought the airy character view above it. Now it is the same two-part
/// row as everything else: identity on the left, level and progress on the
/// right, with the "what's left" text folded into the subtitle.
class SkillRowWidget extends StatelessWidget {
  final SkillSummary skill;
  final Animation<double> animation;
  final VoidCallback? onTap;

  const SkillRowWidget({
    super.key,
    required this.skill,
    required this.animation,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasMastery = skill.mastery > 0;
    final remaining = skill.remainingToNextLevel;

    // Only the exception gets a word. "ACTIVE" on three of four rows was noise;
    // the lit dot already says it.
    final target = hasMastery
        ? '$remaining to +${skill.mastery + 1}'
        : '$remaining to Lv ${skill.level + 1}';
    final subtitle =
        skill.isActive ? target : 'DORMANT · $target';

    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.18),
          end: Offset.zero,
        ).animate(animation),
        child: PlayerRow(
          dotColor: skillColor(skill.skill),
          dimDot: !skill.isActive,
          title: skill.skill.displayName,
          subtitle: subtitle,
          value: hasMastery ? '+${skill.mastery}' : '${skill.level}',
          valueColor: hasMastery ? RpgColors.accent : null,
          valueFooter: _ThinBar(
            progress: skill.progressToNextLevel,
            isActive: skill.isActive,
          ),
          onTap: onTap,
        ),
      ),
    );
  }
}

/// Short progress bar sitting under the level number.
class _ThinBar extends StatelessWidget {
  final double progress;
  final bool isActive;

  const _ThinBar({required this.progress, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 56,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: progress.clamp(0.0, 1.0)),
        duration: const Duration(milliseconds: 1200),
        curve: Curves.easeOutCubic,
        builder: (_, value, _) => ClipRRect(
          borderRadius: BorderRadius.circular(1),
          child: LinearProgressIndicator(
            value: value,
            backgroundColor: RpgColors.progressTrack,
            valueColor: AlwaysStoppedAnimation<Color>(
              isActive
                  ? RpgColors.progressFillActive
                  : RpgColors.progressFillDormant,
            ),
            minHeight: 3,
          ),
        ),
      ),
    );
  }
}
