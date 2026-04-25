import 'package:flutter/material.dart';

import '../../../../core/theme/rpg_colors.dart';
import '../../domain/entities/mindfulness_stats.dart';

const _teal = Color(0xFF26A69A);
const _tealLight = Color(0xFF80CBC4);

class MindfulnessLifetimeSection extends StatelessWidget {
  final MindfulnessStats stats;

  const MindfulnessLifetimeSection({super.key, required this.stats});

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
            Color(0xFF132A28),
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
                Container(width: 6, height: 6, color: _teal),
                const SizedBox(width: 8),
                const Text(
                  'PRACTICE',
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
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: stats.lifetimeHours),
              duration: const Duration(milliseconds: 1400),
              curve: Curves.easeOutCubic,
              builder: (_, v, _) => Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _formatHours(v),
                    style: const TextStyle(
                      color: Color(0xFFE6FFFA),
                      fontSize: 48,
                      fontWeight: FontWeight.w800,
                      height: 1.0,
                      letterSpacing: -2.2,
                      shadows: [
                        Shadow(color: Color(0x6626A69A), blurRadius: 22),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Padding(
                    padding: EdgeInsets.only(bottom: 6),
                    child: Text(
                      'hrs',
                      style: TextStyle(
                        color: RpgColors.textMuted,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      '${_formatMinutes(stats.lifetimeMinutes)} min total',
                      style: const TextStyle(
                        color: RpgColors.textMuted,
                        fontSize: 11,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(height: 1, color: RpgColors.divider),
          IntrinsicHeight(
            child: Row(
              children: [
                Expanded(
                  child: _RollingStat(
                    label: 'LAST 30 DAYS',
                    value: stats.last30DaysMinutes,
                    color: _teal,
                  ),
                ),
                Container(width: 1, color: RpgColors.divider),
                Expanded(
                  child: _RollingStat(
                    label: 'BEST 30-DAY',
                    value: stats.best30DayMinutes,
                    color: _tealLight,
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

  String _formatMinutes(int m) {
    if (m >= 1000000) return '${(m / 1000000).toStringAsFixed(2)}M';
    if (m >= 1000) return '${(m / 1000).toStringAsFixed(1)}k';
    return m.toString();
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
