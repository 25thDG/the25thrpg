import 'package:flutter/material.dart';

import '../../../../core/theme/rpg_colors.dart';
import '../../domain/entities/mindfulness_session.dart';
import '../../domain/entities/mindfulness_stats.dart';

const _colorTeal = Color(0xFF26A69A);

const _categoryColors = {
  MindfulnessCategory.meditation: Color(0xFF26A69A),
  MindfulnessCategory.journaling: Color(0xFFFFA726),
  MindfulnessCategory.walking: Color(0xFF66BB6A),
  MindfulnessCategory.nonfiction: Color(0xFF7986CB),
};

class MindfulnessCategorySection extends StatelessWidget {
  final MindfulnessStats stats;

  const MindfulnessCategorySection({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final rows = MindfulnessCategory.values
        .where((c) => !c.isAddiction)
        .map((c) => stats.categoryBreakdown[c])
        .whereType<MindfulnessCategoryStats>()
        .toList();

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
          Container(
            height: 3,
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
              gradient: LinearGradient(
                colors: [_colorTeal, Color(0xFF4DB6AC)],
              ),
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: RpgColors.divider)),
            ),
            child: const Text(
              'CATEGORY BREAKDOWN',
              style: TextStyle(
                color: RpgColors.textMuted,
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 2.4,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              children: [
                for (final r in rows)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _CategoryRow(stats: r),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  final MindfulnessCategoryStats stats;

  const _CategoryRow({required this.stats});

  @override
  Widget build(BuildContext context) {
    final color = _categoryColors[stats.category] ?? _colorTeal;
    final pct = (stats.percentage / 100).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(width: 6, height: 6, color: color),
            const SizedBox(width: 8),
            Text(
              stats.category.displayName.toUpperCase(),
              style: const TextStyle(
                color: RpgColors.textSecondary,
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.4,
              ),
            ),
            const Spacer(),
            Text(
              '${stats.percentage.toStringAsFixed(1)}%',
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              _fmtMin(stats.totalMinutes),
              style: const TextStyle(
                color: RpgColors.textMuted,
                fontSize: 11,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: pct),
          duration: const Duration(milliseconds: 1100),
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
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [color, color.withValues(alpha: 0.7)],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _fmtMin(int m) {
    if (m >= 1000) return '${(m / 1000).toStringAsFixed(1)}k m';
    return '${m}m';
  }
}
