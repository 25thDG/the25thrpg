import 'package:flutter/material.dart';

import '../../../../core/theme/rpg_colors.dart';
import '../../domain/entities/japanese_session.dart';
import '../../domain/entities/japanese_stats.dart';

const _categoryColors = {
  SessionCategory.vocab: Color(0xFF5C6BC0),
  SessionCategory.reading: Color(0xFF26A69A),
  SessionCategory.active: Color(0xFF4FC3F7),
  SessionCategory.passive: Color(0xFFAB47BC),
  SessionCategory.accent: Color(0xFFEC407A),
};

class CategoryBreakdownSection extends StatelessWidget {
  final JapaneseStats stats;

  const CategoryBreakdownSection({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final rows = SessionCategory.values
        .map((c) => stats.categoryBreakdown[c])
        .whereType<CategoryStats>()
        .toList();

    if (rows.isEmpty) return const SizedBox.shrink();

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
            width: double.infinity,
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(
              border:
                  Border(bottom: BorderSide(color: RpgColors.divider)),
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
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Column(
              children: rows.map((data) {
                final color = _categoryColors[data.category] ??
                    const Color(0xFF4FC3F7);
                final pct = (data.percentage / 100).clamp(0.0, 1.0);
                final isLast = data == rows.last;
                return Padding(
                  padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                data.category.displayName
                                    .toUpperCase(),
                                style: const TextStyle(
                                  color: RpgColors.textSecondary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Text(
                                '${data.percentage.toStringAsFixed(1)}%',
                                style: TextStyle(
                                  color: color,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                _fmtMin(data.totalMinutes),
                                style: const TextStyle(
                                  color: RpgColors.textMuted,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: pct),
                        duration: const Duration(milliseconds: 1000),
                        curve: Curves.easeOutCubic,
                        builder: (_, v, _) => ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: Stack(
                            children: [
                              Container(
                                  height: 5,
                                  color: RpgColors.progressTrack),
                              FractionallySizedBox(
                                widthFactor: v,
                                child: Container(
                                    height: 5, color: color),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  String _fmtMin(int m) {
    if (m >= 1000) return '${(m / 1000).toStringAsFixed(1)}k min';
    return '$m min';
  }
}
