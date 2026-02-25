import 'package:flutter/material.dart';

import '../../domain/entities/player_stats.dart';
import '../../domain/entities/skill_summary.dart';
import 'rpg_colors.dart';

/// The primary stat panel — displays player level, XP progress,
/// and aggregate statistics in a structured two-column layout.
class PlayerLevelPanel extends StatelessWidget {
  final PlayerStats stats;

  const PlayerLevelPanel({super.key, required this.stats});

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
          _PanelHeader(),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(flex: 5, child: _LevelColumn(stats: stats)),
                Container(width: 1, color: RpgColors.divider),
                Expanded(flex: 6, child: _StatsColumn(stats: stats)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Panel header ─────────────────────────────────────────────────────────────

class _PanelHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: RpgColors.divider)),
      ),
      child: const Text(
        'CHARACTER PROFILE',
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

// ── Left column — level + XP bar ─────────────────────────────────────────────

class _LevelColumn extends StatelessWidget {
  final PlayerStats stats;

  const _LevelColumn({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'LEVEL',
            style: TextStyle(
              color: RpgColors.accent,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 2.2,
            ),
          ),
          const SizedBox(height: 8),
          _AnimatedLevelNumber(level: stats.playerLevel),
          const SizedBox(height: 20),
          const Text(
            'EXPERIENCE',
            style: TextStyle(
              color: RpgColors.textMuted,
              fontSize: 9,
              fontWeight: FontWeight.w500,
              letterSpacing: 1.8,
            ),
          ),
          const SizedBox(height: 8),
          _AnimatedXpBar(progress: stats.playerProgressToNextLevel),
          const SizedBox(height: 6),
          _XpBarFooter(
            progress: stats.playerProgressToNextLevel,
            playerLevel: stats.playerLevel,
          ),
        ],
      ),
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
          color: RpgColors.textPrimary,
          fontSize: 64,
          fontWeight: FontWeight.w700,
          height: 1.0,
          letterSpacing: -2,
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
      tween: Tween(begin: 0.0, end: progress),
      duration: const Duration(milliseconds: 1400),
      curve: Curves.easeOutCubic,
      builder: (_, value, _) => _ThinBar(
        progress: value,
        fillColor: RpgColors.progressFillActive,
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

// ── Right column — stat table ─────────────────────────────────────────────────

class _StatsColumn extends StatelessWidget {
  final PlayerStats stats;

  const _StatsColumn({required this.stats});

  @override
  Widget build(BuildContext context) {
    final topSkillName = stats.topSkill?.skill.displayName ?? '—';
    final totalMastery = stats.totalMastery;
    final masteryValue = totalMastery > 0 ? '+$totalMastery pts' : '—';

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _StatRow(label: 'TOP SKILL', value: topSkillName),
          const SizedBox(height: 18),
          _StatRow(
            label: 'ACTIVE SKILLS',
            value: '${stats.activeSkillCount} / ${stats.skills.length}',
          ),
          const SizedBox(height: 18),
          _StatRow(label: 'MASTERY PTS', value: masteryValue),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;

  const _StatRow({required this.label, required this.value});

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
            fontWeight: FontWeight.w500,
            letterSpacing: 1.8,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: RpgColors.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }
}

// ── Shared thin progress bar ──────────────────────────────────────────────────

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
