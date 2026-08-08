import 'package:flutter/material.dart';

import '../../domain/entities/skill_summary.dart';
import '../widgets/player_hero.dart' show AvatarCore;
import '../widgets/rpg_colors.dart';
import '../widgets/skill_radar_chart.dart';
import '../widgets/skill_radar_variants.dart';

/// Temporary side-by-side of every radar treatment, stacked so they can be
/// compared on the real data. Delete once a winner is picked.


class RadarGalleryPage extends StatelessWidget {
  final List<SkillSummary> skills;

  const RadarGalleryPage({super.key, required this.skills});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RpgColors.pageBg,
      appBar: AppBar(
        backgroundColor: RpgColors.pageBg,
        foregroundColor: RpgColors.textSecondary,
        scrolledUnderElevation: 0,
        elevation: 0,
        title: const Text(
          'RADAR STYLES',
          style: TextStyle(
            color: RpgColors.textMuted,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 2.8,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 60),
        children: [
          _Entry(
            tag: 'NOW',
            title: 'DIAMOND',
            blurb: 'What is on the screen today.',
            child: SkillRadarChart(skills: skills, core: const AvatarCore()),
          ),
          _Entry(
            tag: 'A',
            title: 'AURA',
            blurb: 'Same diamond, curved. Reads as a living silhouette.',
            child: RadarAura(skills: skills),
          ),
          _Entry(
            tag: 'B',
            title: 'ORBITS',
            blurb: 'One ring per skill. The clearest to read.',
            child: RadarOrbits(skills: skills),
          ),
          _Entry(
            tag: 'C',
            title: 'PRISM',
            blurb: 'Four beams from the core. No web to hide a weak skill.',
            child: RadarPrism(skills: skills),
          ),
          _Entry(
            tag: 'D',
            title: 'SONAR',
            blurb: 'A live instrument, with a sweep that circles the dial.',
            child: RadarSonar(skills: skills),
          ),
          _Entry(
            tag: 'E',
            title: 'MONOLITH',
            blurb: 'Lit pillars on a floor. Loudest, least radar-like.',
            child: RadarMonolith(skills: skills),
          ),
          _Entry(
            tag: 'F',
            title: 'CRYSTAL',
            blurb: 'One gem, cut into four facets — a colour per skill.',
            child: RadarCrystal(skills: skills),
          ),
          _Entry(
            tag: 'G',
            title: 'BLOOM',
            blurb: 'Four petals opening from the core. Softer than beams.',
            child: RadarBloom(skills: skills),
          ),
          _Entry(
            tag: 'H',
            title: 'NOTCHES',
            blurb: 'One notch per level. You can count it off the dial.',
            child: RadarNotches(skills: skills),
          ),
          _Entry(
            tag: 'I',
            title: 'CONSTELLATION',
            blurb: 'Four stars and a star map. The quietest of them all.',
            child: RadarConstellation(skills: skills),
          ),
          _Entry(
            tag: 'J',
            title: 'ROSE',
            blurb: 'Wedges sized by level. Area does the work.',
            child: RadarRose(skills: skills),
          ),
          _Entry(
            tag: 'K',
            title: 'RIDGE',
            blurb: 'A lit landscape. Ranking left to right.',
            child: RadarRidge(skills: skills),
          ),
          _Entry(
            tag: 'L',
            title: 'HALO',
            blurb: 'One ring, four quarters, thickness is the level.',
            child: RadarHalo(skills: skills),
          ),
        ],
      ),
    );
  }
}

class _Entry extends StatelessWidget {
  final String tag;
  final String title;
  final String blurb;
  final Widget child;

  const _Entry({
    required this.tag,
    required this.title,
    required this.blurb,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 1, thickness: 1, color: RpgColors.divider),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: RpgColors.accent.withValues(alpha: 0.14),
                  border: Border.all(
                    color: RpgColors.accent.withValues(alpha: 0.45),
                  ),
                ),
                child: Text(
                  tag,
                  style: const TextStyle(
                    color: RpgColors.accent,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: RpgColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      blurb,
                      style: const TextStyle(
                        color: RpgColors.textMuted,
                        fontSize: 10,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        child,
        const SizedBox(height: 14),
      ],
    );
  }
}
