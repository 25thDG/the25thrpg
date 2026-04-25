import 'package:flutter/material.dart';

import '../../../../core/theme/rpg_colors.dart';
import '../../domain/entities/japanese_stats.dart';

const _jp = Color(0xFF4FC3F7);
const _jpLight = Color(0xFF81D4FA);

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
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: RpgColors.border),
        gradient: const RadialGradient(
          center: Alignment(1.0, -1.0),
          radius: 1.4,
          colors: [
            Color(0xFF0F2A38),
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
                Container(width: 6, height: 6, color: _jp),
                const SizedBox(width: 8),
                const Text(
                  'JAPANESE',
                  style: TextStyle(
                    color: RpgColors.textSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2.4,
                  ),
                ),
                const Spacer(),
                Text(
                  '${percent.toStringAsFixed(1)}%',
                  style: const TextStyle(
                    color: _jpLight,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: lifeHours),
              duration: const Duration(milliseconds: 1400),
              curve: Curves.easeOutCubic,
              builder: (_, v, _) => Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _formatHours(v),
                    style: const TextStyle(
                      color: Color(0xFFE0F7FA),
                      fontSize: 48,
                      fontWeight: FontWeight.w800,
                      height: 1.0,
                      letterSpacing: -2.2,
                      shadows: [
                        Shadow(color: Color(0x664FC3F7), blurRadius: 22),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      '/ ${_formatHoursInt(horizonHours)} hrs',
                      style: const TextStyle(
                        color: RpgColors.textMuted,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _JpBar(progress: progress),
                const SizedBox(height: 6),
                Text(
                  '${_formatMinutes(stats.lifetimeMinutes)} total minutes',
                  style: const TextStyle(
                    color: RpgColors.textMuted,
                    fontSize: 10,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
          Container(height: 1, color: RpgColors.divider),
          IntrinsicHeight(
            child: Row(
              children: [
                Expanded(
                  child: _RollingStat(
                    label: 'LAST 30 DAYS',
                    value: stats.last30DaysWeightedMinutes.round(),
                    color: _jp,
                  ),
                ),
                Container(width: 1, color: RpgColors.divider),
                Expanded(
                  child: _RollingStat(
                    label: 'BEST 30-DAY',
                    value: stats.best30DayWeightedMinutes.round(),
                    color: _jpLight,
                    bold: true,
                  ),
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
                  gradient: LinearGradient(colors: [_jp, _jpLight]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RollingStat extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  final bool bold;

  const _RollingStat({
    required this.label,
    required this.value,
    required this.color,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: RpgColors.textMuted,
              fontSize: 9,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.6,
            ),
          ),
          const SizedBox(height: 6),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: value.toDouble()),
            duration: const Duration(milliseconds: 1100),
            curve: Curves.easeOutCubic,
            builder: (_, v, _) => RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: _fmt(v.round()),
                    style: TextStyle(
                      color: color,
                      fontSize: 22,
                      fontWeight: bold ? FontWeight.w800 : FontWeight.w700,
                      letterSpacing: -0.6,
                    ),
                  ),
                  const TextSpan(
                    text: ' min',
                    style: TextStyle(
                      color: RpgColors.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(int m) {
    if (m >= 1000) return '${(m / 1000).toStringAsFixed(1)}k';
    return m.toString();
  }
}
