import 'package:flutter/material.dart';

import '../../domain/entities/player_stats.dart';
import '../../domain/entities/skill_summary.dart';
import 'player_stat_grid.dart';
import 'rpg_colors.dart';
import 'skill_radar_chart.dart';

const _crimson = Color(0xFFC0392B);
const _crimsonLight = Color(0xFFE74C3C);

/// The character view — the one loud thing on the screen.
///
/// With no character art, the radar *is* the character: a silhouette whose
/// shape is unique to this player and changes as their skills move. The level
/// crowns it, a soft glow lifts it off the page, and everything below this is
/// deliberately quiet.
class PlayerHero extends StatelessWidget {
  final PlayerStats stats;

  const PlayerHero({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.topCenter,
      children: [
        const Positioned.fill(child: _AmbientGlow()),
        Column(
          children: [
            const SizedBox(height: 4),
            _LevelCore(level: stats.playerLevel),
            const SizedBox(height: 14),
            _XpBar(
              progress: stats.playerProgressToNextLevel,
              playerLevel: stats.playerLevel,
            ),
            // Enough air that the top skill label reads as part of the figure
            // rather than a caption on the XP bar.
            const SizedBox(height: 18),
            // The figure. Sits below the level so nothing can overlap it.
            SkillRadarChart(skills: stats.skills),
          ],
        ),
      ],
    );
  }
}

/// A wide, very soft crimson wash behind the figure. Not a visible shape —
/// just enough to stop the polygon floating on flat black.
class _AmbientGlow extends StatelessWidget {
  const _AmbientGlow();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(0, -0.15),
          radius: 0.85,
          colors: [
            _crimson.withValues(alpha: 0.16),
            _crimson.withValues(alpha: 0.05),
            Colors.transparent,
          ],
          stops: const [0.0, 0.45, 1.0],
        ),
      ),
    );
  }
}

/// The player level — the crown above the figure.
class _LevelCore extends StatelessWidget {
  final int level;

  const _LevelCore({required this.level});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'LEVEL',
          style: TextStyle(
            color: _crimsonLight,
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 3.0,
          ),
        ),
        const SizedBox(height: 2),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: level.toDouble()),
          duration: const Duration(milliseconds: 1100),
          curve: Curves.easeOutCubic,
          builder: (_, value, _) => Text(
            value.round().toString(),
            style: TextStyle(
              color: const Color(0xFFFAEDEA),
              fontSize: level >= 100 ? 60 : 72,
              fontWeight: FontWeight.w800,
              height: 1.0,
              letterSpacing: -3.0,
              shadows: const [
                Shadow(color: Color(0x99C0392B), blurRadius: 28),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Thin progress line between the level and the figure.
class _XpBar extends StatelessWidget {
  final double progress;
  final int playerLevel;

  const _XpBar({required this.progress, required this.playerLevel});

  @override
  Widget build(BuildContext context) {
    final pct = (progress * 100).round();
    final label = playerLevel >= 100
        ? 'to next mastery'
        : 'to level ${playerLevel + 1}';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: progress.clamp(0.0, 1.0)),
            duration: const Duration(milliseconds: 1400),
            curve: Curves.easeOutCubic,
            builder: (_, v, _) => ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: Stack(
                children: [
                  Container(height: 3, color: RpgColors.progressTrack),
                  FractionallySizedBox(
                    widthFactor: v,
                    child: Container(
                      height: 3,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [_crimson, _crimsonLight],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$pct% $label',
            style: const TextStyle(
              color: RpgColors.textMuted,
              fontSize: 10,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}

/// The character's summary numbers, in the same grid Today uses.
class PlayerStatLine extends StatelessWidget {
  final PlayerStats stats;

  const PlayerStatLine({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    return PlayerStatGrid(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 4),
      cells: [
        PlayerStatCell(
          label: 'TOP SKILL',
          value: stats.topSkill?.skill.displayName ?? '\u2014',
          // "MINDFULNESS" needs more room than "3/4" or "12d".
          flex: 4,
        ),
        PlayerStatCell(
          label: 'ACTIVE',
          value: '${stats.activeSkillCount}/${stats.skills.length}',
        ),
        PlayerStatCell(
          label: 'MASTERY',
          value: stats.totalMastery > 0 ? '+${stats.totalMastery}' : '\u2014',
          valueColor: stats.totalMastery > 0 ? _crimsonLight : null,
        ),
        PlayerStatCell(
          label: 'STREAK',
          value: stats.streakDays > 0 ? '${stats.streakDays}d' : '\u2014',
        ),
      ],
    );
  }
}
