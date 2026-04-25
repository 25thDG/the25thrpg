import 'package:flutter/material.dart';

import '../../domain/entities/player_stats.dart';
import '../../domain/entities/skill_summary.dart';
import 'rpg_colors.dart';

const _crimson = Color(0xFFC0392B);
const _crimsonLight = Color(0xFFE74C3C);

class PlayerLevelPanel extends StatelessWidget {
  final PlayerStats stats;

  const PlayerLevelPanel({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: RpgColors.border),
        gradient: const RadialGradient(
          center: Alignment(-1.0, -1.0),
          radius: 1.4,
          colors: [
            Color(0xFF2A0F12),
            Color(0xFF101015),
            RpgColors.panelBg,
          ],
          stops: [0.0, 0.55, 1.0],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
            child: Row(
              children: [
                Container(width: 6, height: 6, color: _crimson),
                const SizedBox(width: 8),
                const Text(
                  'CHARACTER',
                  style: TextStyle(
                    color: RpgColors.textSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2.4,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(flex: 5, child: _LevelColumn(stats: stats)),
                  const SizedBox(width: 18),
                  Expanded(flex: 6, child: _StatsColumn(stats: stats)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LevelColumn extends StatelessWidget {
  final PlayerStats stats;

  const _LevelColumn({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'LEVEL',
          style: TextStyle(
            color: _crimsonLight,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 2.2,
          ),
        ),
        const SizedBox(height: 4),
        _AnimatedLevelNumber(level: stats.playerLevel),
        const SizedBox(height: 18),
        const Text(
          'EXPERIENCE',
          style: TextStyle(
            color: RpgColors.textMuted,
            fontSize: 9,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.8,
          ),
        ),
        const SizedBox(height: 6),
        _AnimatedXpBar(progress: stats.playerProgressToNextLevel),
        const SizedBox(height: 6),
        _XpBarFooter(
          progress: stats.playerProgressToNextLevel,
          playerLevel: stats.playerLevel,
        ),
      ],
    );
  }
}

class _AnimatedLevelNumber extends StatelessWidget {
  final int level;
  const _AnimatedLevelNumber({required this.level});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: level.toDouble()),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (_, value, _) => Text(
        value.round().toString(),
        style: const TextStyle(
          color: Color(0xFFFAEDEA),
          fontSize: 76,
          fontWeight: FontWeight.w800,
          height: 1.0,
          letterSpacing: -3.0,
          shadows: [
            Shadow(color: Color(0x77C0392B), blurRadius: 24),
          ],
        ),
      ),
    );
  }
}

class _AnimatedXpBar extends StatelessWidget {
  final double progress;
  const _AnimatedXpBar({required this.progress});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: progress.clamp(0.0, 1.0)),
      duration: const Duration(milliseconds: 1400),
      curve: Curves.easeOutCubic,
      builder: (_, v, _) => ClipRRect(
        borderRadius: BorderRadius.circular(2),
        child: Stack(
          children: [
            Container(height: 4, color: RpgColors.progressTrack),
            FractionallySizedBox(
              widthFactor: v,
              child: Container(
                height: 4,
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
    );
  }
}

class _XpBarFooter extends StatelessWidget {
  final double progress;
  final int playerLevel;

  const _XpBarFooter({required this.progress, required this.playerLevel});

  @override
  Widget build(BuildContext context) {
    final pct = (progress * 100).round();
    final label = playerLevel >= 100 ? 'to next mastery' : 'to next level';
    return Text(
      '$pct% $label',
      style: const TextStyle(
        color: RpgColors.textMuted,
        fontSize: 10,
        letterSpacing: 0.4,
      ),
    );
  }
}

class _StatsColumn extends StatelessWidget {
  final PlayerStats stats;
  const _StatsColumn({required this.stats});

  @override
  Widget build(BuildContext context) {
    final topSkillName = stats.topSkill?.skill.displayName ?? '—';
    final masteryValue = stats.totalMastery > 0 ? '+${stats.totalMastery}' : '—';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _StatRow(label: 'TOP SKILL', value: topSkillName),
        const SizedBox(height: 14),
        _StatRow(
          label: 'ACTIVE',
          value: '${stats.activeSkillCount} / ${stats.skills.length}',
        ),
        const SizedBox(height: 14),
        _StatRow(
          label: 'MASTERY',
          value: masteryValue,
          highlight: stats.totalMastery > 0,
        ),
        const SizedBox(height: 14),
        _StatRow(
          label: 'STREAK',
          value: stats.streakDays > 0 ? '${stats.streakDays} days' : '—',
        ),
      ],
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;

  const _StatRow({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: RpgColors.textMuted,
            fontSize: 9,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.8,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(
            color: highlight ? _crimsonLight : RpgColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }
}
