import 'package:flutter/material.dart';

import '../../domain/entities/skill_summary.dart';
import 'player_card.dart';
import 'rpg_colors.dart';
import 'skill_colors.dart';

/// One skill, as a card: identity on the left, level and progress on the right.
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
    final color = skillColor(skill.skill);
    final hasMastery = skill.mastery > 0;
    final remaining = skill.remainingToNextLevel;
    final target = hasMastery
        ? '$remaining to +${skill.mastery + 1}'
        : '$remaining to Lv ${skill.level + 1}';

    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.14),
          end: Offset.zero,
        ).animate(animation),
        child: PlayerCard(
          accent: color,
          onTap: onTap,
          padding: const EdgeInsets.fromLTRB(14, 13, 16, 13),
          child: Row(
            children: [
              // Glowing bead carries the skill identity.
              Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: skill.isActive
                      ? color
                      : color.withValues(alpha: 0.28),
                  boxShadow: skill.isActive
                      ? [
                          BoxShadow(
                            color: color.withValues(alpha: 0.6),
                            blurRadius: 8,
                          ),
                        ]
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      skill.skill.displayName,
                      style: TextStyle(
                        color: skill.isActive
                            ? RpgColors.textPrimary
                            : RpgColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.3,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      // Only the exception gets a word; the lit bead says
                      // "active" on its own.
                      skill.isActive ? target : 'DORMANT · $target',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: RpgColors.textMuted,
                        fontSize: 9,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    hasMastery ? '+${skill.mastery}' : '${skill.level}',
                    style: TextStyle(
                      color: hasMastery
                          ? RpgColors.accent
                          : RpgColors.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      height: 1.0,
                      letterSpacing: -0.6,
                    ),
                  ),
                  const SizedBox(height: 7),
                  SizedBox(
                    width: 58,
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(
                        begin: 0.0,
                        end: skill.progressToNextLevel.clamp(0.0, 1.0),
                      ),
                      duration: const Duration(milliseconds: 1200),
                      curve: Curves.easeOutCubic,
                      builder: (_, v, _) => ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                          value: v,
                          minHeight: 3,
                          backgroundColor: RpgColors.progressTrack,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            skill.isActive
                                ? color
                                : RpgColors.progressFillDormant,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
