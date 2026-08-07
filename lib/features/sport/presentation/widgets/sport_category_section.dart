import 'package:flutter/material.dart';

import '../../../../core/theme/rpg_colors.dart';
import '../../domain/entities/sport_session.dart';
import '../../domain/entities/sport_stats.dart';

const _categoryColors = {
  SportCategory.strength: Color(0xFFEF5350),
  SportCategory.cardio: Color(0xFFFF7043),
  SportCategory.mobility: Color(0xFF26A69A),
  SportCategory.sportSpecific: Color(0xFF7986CB),
};

class SportCategorySection extends StatelessWidget {
  final SportStats stats;

  const SportCategorySection({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final categories = SportCategory.values
        .where((c) => stats.categoryBreakdown.containsKey(c))
        .toList();

    if (categories.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: RpgColors.panelBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: RpgColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: RpgColors.divider)),
            ),
            child: const Text(
              'BREAKDOWN',
              style: TextStyle(
                color: RpgColors.textMuted,
                fontSize: 9,
                fontWeight: FontWeight.w600,
                letterSpacing: 2.4,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: categories.map((cat) {
                final data = stats.categoryBreakdown[cat]!;
                return _CategoryBar(stats: data);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryBar extends StatefulWidget {
  final SportCategoryStats stats;

  const _CategoryBar({required this.stats});

  @override
  State<_CategoryBar> createState() => _CategoryBarState();
}

class _CategoryBarState extends State<_CategoryBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color =
        _categoryColors[widget.stats.category] ?? const Color(0xFFFF7043);
    final pct = (widget.stats.percentage / 100).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration:
                        BoxDecoration(color: color, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 7),
                  Text(
                    widget.stats.category.displayName,
                    style: const TextStyle(
                      color: RpgColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Text(
                    '${widget.stats.percentage.toStringAsFixed(1)}%',
                    style: TextStyle(
                      color: color,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${widget.stats.minutes} min',
                    style: const TextStyle(
                      color: RpgColors.textMuted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          Container(
            height: 5,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(3),
            ),
            child: AnimatedBuilder(
              animation: _anim,
              builder: (_, _) => FractionallySizedBox(
                widthFactor: pct * _anim.value,
                alignment: Alignment.centerLeft,
                child: Container(
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
