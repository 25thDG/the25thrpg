import 'package:flutter/material.dart';

import '../../../../core/theme/rpg_colors.dart';
import '../../domain/entities/japanese_stats.dart';

const _colorJp = Color(0xFF4FC3F7);

class LifetimeStatsSection extends StatelessWidget {
  final JapaneseStats stats;

  const LifetimeStatsSection({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final lifeHours = stats.lifetimeHours;
    final horizonHours = stats.currentHorizonHours;
    final progress = stats.progressToHorizon;
    final percent = stats.progressPercent;

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
          // Accent bar
          Container(
            height: 3,
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
              gradient: LinearGradient(
                colors: [_colorJp, Color(0xFF81D4FA)],
              ),
            ),
          ),
          // Header
          Container(
            width: double.infinity,
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(
              border:
                  Border(bottom: BorderSide(color: RpgColors.divider)),
            ),
            child: const Text(
              'LIFETIME PROGRESS',
              style: TextStyle(
                color: RpgColors.textMuted,
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 2.4,
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Big hours number
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: lifeHours),
                      duration: const Duration(milliseconds: 1200),
                      curve: Curves.easeOutCubic,
                      builder: (_, v, _) => Text(
                        _formatHours(v),
                        style: const TextStyle(
                          color: RpgColors.textPrimary,
                          fontSize: 40,
                          fontWeight: FontWeight.w700,
                          height: 1.0,
                          letterSpacing: -1.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '/ ${_formatHoursInt(horizonHours)} hrs',
                      style: const TextStyle(
                        color: RpgColors.textMuted,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Progress bar
                _JpBar(progress: progress),
                const SizedBox(height: 8),

                // Footer row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${_formatMinutes(stats.lifetimeMinutes)} total minutes',
                      style: const TextStyle(
                        color: RpgColors.textMuted,
                        fontSize: 10,
                        letterSpacing: 0.3,
                      ),
                    ),
                    Text(
                      '${percent.toStringAsFixed(1)}%',
                      style: const TextStyle(
                        color: _colorJp,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatHours(double h) {
    if (h >= 1000) return '${(h / 1000).toStringAsFixed(2)}k';
    return h.toStringAsFixed(1);
  }

  String _formatHoursInt(int h) {
    if (h >= 1000) return '${(h / 1000).toStringAsFixed(1)}k';
    return h.toString();
  }

  String _formatMinutes(int m) {
    if (m >= 1_000_000) return '${(m / 1_000_000).toStringAsFixed(2)}M';
    if (m >= 1000) return '${(m / 1000).toStringAsFixed(1)}k';
    return m.toString();
  }
}

class _JpBar extends StatelessWidget {
  final double progress;
  const _JpBar({required this.progress});

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
            Container(height: 6, color: RpgColors.progressTrack),
            FractionallySizedBox(
              widthFactor: v,
              child: Container(
                height: 6,
                decoration: const BoxDecoration(
                  gradient:
                      LinearGradient(colors: [_colorJp, Color(0xFF81D4FA)]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
