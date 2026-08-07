import 'package:flutter/material.dart';

import '../../domain/entities/player_stats.dart';
import '../../domain/entities/skill_summary.dart';
import 'rpg_colors.dart';
import 'skill_radar_chart.dart';

const _crimson = Color(0xFFC0392B);
const _crimsonLight = Color(0xFFE74C3C);

/// The character view — the one loud thing on the screen.
///
/// With no character art, the radar *is* the character: a silhouette whose
/// shape is unique to this player and shifts as their skills move. The core in
/// its middle is the avatar slot; drop a portrait in later and nothing else has
/// to change.
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
            _StatusHeader(stats: stats),
            const SizedBox(height: 10),
            SkillRadarChart(
              skills: stats.skills,
              core: const AvatarCore(),
            ),
          ],
        ),
      ],
    );
  }
}

/// Level, XP and streak in one tight block.
class _StatusHeader extends StatelessWidget {
  final PlayerStats stats;

  const _StatusHeader({required this.stats});

  @override
  Widget build(BuildContext context) {
    final pct = (stats.playerProgressToNextLevel * 100).round();
    final next = stats.playerLevel >= 100
        ? 'MASTERY'
        : 'LV ${stats.playerLevel + 1}';

    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 4, 28, 0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Padding(
                padding: EdgeInsets.only(bottom: 14, right: 10),
                child: Text(
                  'LV',
                  style: TextStyle(
                    color: _crimsonLight,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 3.0,
                  ),
                ),
              ),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: stats.playerLevel.toDouble()),
                duration: const Duration(milliseconds: 1100),
                curve: Curves.easeOutCubic,
                builder: (_, value, _) => Text(
                  value.round().toString(),
                  style: TextStyle(
                    color: const Color(0xFFFDF4F2),
                    fontSize: stats.playerLevel >= 100 ? 62 : 74,
                    fontWeight: FontWeight.w900,
                    height: 1.0,
                    letterSpacing: -4.0,
                    shadows: const [
                      Shadow(color: Color(0xAAC0392B), blurRadius: 30),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _XpBar(progress: stats.playerProgressToNextLevel),
          const SizedBox(height: 7),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$pct% TO $next',
                style: const TextStyle(
                  color: RpgColors.textMuted,
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.4,
                ),
              ),
              Text(
                stats.streakDays > 0
                    ? '● ${stats.streakDays} DAY STREAK'
                    : '○ NO STREAK',
                style: TextStyle(
                  color: stats.streakDays > 0
                      ? _crimsonLight
                      : RpgColors.textMuted,
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.4,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The core at the heart of the polygon — a slow-breathing well of light rather
/// than an icon, so the figure reads as a power source instead of a profile row.
class AvatarCore extends StatefulWidget {
  const AvatarCore({super.key});

  @override
  State<AvatarCore> createState() => _AvatarCoreState();
}

class _AvatarCoreState extends State<AvatarCore>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (_, _) {
        final t = Curves.easeInOut.transform(_pulse.value);

        return SizedBox(
          width: 88,
          height: 88,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Containment ring — structure, so the light has an edge.
              Container(
                width: 74,
                height: 74,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _crimson.withValues(alpha: 0.20 + t * 0.10),
                  ),
                ),
              ),
              // The light itself. No opaque disc — a solid fill would punch a
              // dark hole through the middle of the figure.
              Container(
                width: 52 + t * 10,
                height: 52 + t * 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFFFFE3DC).withValues(alpha: 0.55 + t * 0.25),
                      _crimsonLight.withValues(alpha: 0.34 + t * 0.14),
                      _crimson.withValues(alpha: 0.10),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.34, 0.62, 1.0],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// A wide, very soft crimson wash behind the figure.
class _AmbientGlow extends StatelessWidget {
  const _AmbientGlow();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(0, 0.05),
          radius: 0.9,
          colors: [
            _crimson.withValues(alpha: 0.18),
            _crimson.withValues(alpha: 0.05),
            Colors.transparent,
          ],
          stops: const [0.0, 0.45, 1.0],
        ),
      ),
    );
  }
}

class _XpBar extends StatelessWidget {
  final double progress;

  const _XpBar({required this.progress});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: progress.clamp(0.0, 1.0)),
      duration: const Duration(milliseconds: 1400),
      curve: Curves.easeOutCubic,
      builder: (_, v, _) => ClipRRect(
        borderRadius: BorderRadius.circular(3),
        child: Stack(
          children: [
            Container(height: 5, color: RpgColors.progressTrack),
            FractionallySizedBox(
              widthFactor: v,
              child: Container(
                height: 5,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_crimson, _crimsonLight],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _crimsonLight.withValues(alpha: 0.6),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Top-skill / active / mastery summary, shown under the figure.
class PlayerStatLine extends StatelessWidget {
  final PlayerStats stats;

  const PlayerStatLine({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final cells = <(String, String)>[
      ('TOP SKILL', stats.topSkill?.skill.displayName ?? '—'),
      ('ACTIVE', '${stats.activeSkillCount}/${stats.skills.length}'),
      ('MASTERY', stats.totalMastery > 0 ? '+${stats.totalMastery}' : '—'),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 18),
      child: Row(
        children: [
          for (final (i, (label, value)) in cells.indexed) ...[
            if (i > 0)
              Container(
                width: 1,
                height: 26,
                color: RpgColors.divider,
                margin: const EdgeInsets.symmetric(horizontal: 14),
              ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: RpgColors.textMuted,
                      fontSize: 8,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.4,
                    ),
                  ),
                  const SizedBox(height: 5),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      value,
                      maxLines: 1,
                      style: const TextStyle(
                        color: RpgColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
