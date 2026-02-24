import 'package:flutter/material.dart';

import '../../domain/entities/skill_summary.dart';
import 'rpg_colors.dart';

/// A single row in the Skills window.
///
/// Layout:
///   [Skill name + descriptor] | [Level number] | [Progress bar + status]
///
/// Animates in via [animation] — caller supplies a staggered
/// [Animation<double>] (opacity + vertical offset).
class SkillRowWidget extends StatelessWidget {
  final SkillSummary skill;
  final Animation<double> animation;

  const SkillRowWidget({
    super.key,
    required this.skill,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.18),
          end: Offset.zero,
        ).animate(animation),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // LEFT — name + descriptor
              Expanded(
                flex: 5,
                child: _NameColumn(skill: skill),
              ),
              // CENTER — level number
              SizedBox(
                width: 64,
                child: _LevelDisplay(level: skill.level, isActive: skill.isActive),
              ),
              // RIGHT — bar + status
              Expanded(
                flex: 5,
                child: _ProgressColumn(skill: skill),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Name + descriptor ────────────────────────────────────────────────────────

class _NameColumn extends StatelessWidget {
  final SkillSummary skill;

  const _NameColumn({required this.skill});

  @override
  Widget build(BuildContext context) {
    final nameColor = skill.isActive
        ? RpgColors.textPrimary
        : RpgColors.textSecondary.withValues(alpha: 0.6);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          skill.skill.displayName,
          style: TextStyle(
            color: nameColor,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.6,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          skill.skill.descriptor,
          style: TextStyle(
            color: RpgColors.textMuted.withValues(
              alpha: skill.isActive ? 1.0 : 0.5,
            ),
            fontSize: 10,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }
}

// ── Level number ─────────────────────────────────────────────────────────────

class _LevelDisplay extends StatelessWidget {
  final int level;
  final bool isActive;

  const _LevelDisplay({required this.level, required this.isActive});

  @override
  Widget build(BuildContext context) {
    final numColor = isActive ? RpgColors.textPrimary : RpgColors.textSecondary.withValues(alpha: 0.5);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'Lv.',
          style: TextStyle(
            color: RpgColors.accent.withValues(alpha: isActive ? 0.9 : 0.4),
            fontSize: 9,
            fontWeight: FontWeight.w500,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 1),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: level.toDouble()),
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeOutCubic,
          builder: (_, value, _) => Text(
            value.round().toString(),
            style: TextStyle(
              color: numColor,
              fontSize: 28,
              fontWeight: FontWeight.w700,
              height: 1.0,
              letterSpacing: -0.5,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Progress bar + status ─────────────────────────────────────────────────────

class _ProgressColumn extends StatelessWidget {
  final SkillSummary skill;

  const _ProgressColumn({required this.skill});

  @override
  Widget build(BuildContext context) {
    final isActive = skill.isActive;
    final fillColor = isActive
        ? RpgColors.progressFillActive
        : RpgColors.progressFillDormant;
    final statusColor =
        isActive ? RpgColors.statusActive : RpgColors.statusDormant;
    final statusLabel = isActive ? 'ACTIVE' : 'DORMANT';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          statusLabel,
          style: TextStyle(
            color: statusColor,
            fontSize: 9,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.6,
          ),
        ),
        const SizedBox(height: 8),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: skill.progressToNextLevel),
          duration: const Duration(milliseconds: 1200),
          curve: Curves.easeOutCubic,
          builder: (_, value, _) => _ThinBar(
            progress: value,
            fillColor: fillColor,
          ),
        ),
      ],
    );
  }
}

// ── Thin progress bar ─────────────────────────────────────────────────────────

class _ThinBar extends StatelessWidget {
  final double progress;
  final Color fillColor;

  const _ThinBar({required this.progress, required this.fillColor});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(1),
      child: LinearProgressIndicator(
        value: progress,
        backgroundColor: RpgColors.progressTrack,
        valueColor: AlwaysStoppedAnimation<Color>(fillColor),
        minHeight: 3,
      ),
    );
  }
}
