import 'package:flutter/material.dart';

import '../../../../core/theme/rpg_colors.dart';
import '../../domain/entities/quest.dart';

const _colorQuest = Color(0xFFF59E0B);
const _colorQuestLight = Color(0xFFFCD34D);

class QuestHeroSection extends StatelessWidget {
  final List<Quest> activeQuests;
  final List<Quest> completedQuests;

  const QuestHeroSection({
    super.key,
    required this.activeQuests,
    required this.completedQuests,
  });

  int get _totalXp =>
      completedQuests.fold(0, (sum, q) => sum + q.xpReward);

  int get _legendaryCount =>
      completedQuests.where((q) => q.difficulty == QuestDifficulty.legendary).length;

  @override
  Widget build(BuildContext context) {
    final xp = _totalXp;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: RpgColors.border),
        gradient: const RadialGradient(
          center: Alignment(0.9, -0.9),
          radius: 1.3,
          colors: [Color(0xFF271E06), RpgColors.panelBg],
          stops: [0.0, 1.0],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 3,
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
              gradient:
                  LinearGradient(colors: [_colorQuest, _colorQuestLight]),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
            child: Row(
              children: [
                Container(width: 6, height: 6, color: _colorQuest),
                const SizedBox(width: 8),
                const Text(
                  'QUEST LOG',
                  style: TextStyle(
                    color: RpgColors.textSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2.4,
                  ),
                ),
                const Spacer(),
                if (_legendaryCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF5350).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                          color:
                              const Color(0xFFEF5350).withValues(alpha: 0.4)),
                    ),
                    child: Text(
                      '$_legendaryCount LEGENDARY',
                      style: const TextStyle(
                        color: Color(0xFFEF5350),
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: xp.toDouble()),
              duration: const Duration(milliseconds: 1200),
              curve: Curves.easeOutCubic,
              builder: (_, v, _) => Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _fmtXp(v.round()),
                    style: const TextStyle(
                      color: Color(0xFFFFFBEB),
                      fontSize: 52,
                      fontWeight: FontWeight.w800,
                      height: 1.0,
                      letterSpacing: -2,
                      shadows: [
                        Shadow(color: Color(0x77F59E0B), blurRadius: 24),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Padding(
                    padding: EdgeInsets.only(bottom: 6),
                    child: Text(
                      'XP earned',
                      style: TextStyle(
                        color: RpgColors.textMuted,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
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
                  child: _StatCell(
                    label: 'ACTIVE',
                    value: '${activeQuests.length}',
                    color: _colorQuest,
                  ),
                ),
                Container(width: 1, color: RpgColors.divider),
                Expanded(
                  child: _StatCell(
                    label: 'COMPLETED',
                    value: '${completedQuests.length}',
                    color: _colorQuestLight,
                  ),
                ),
                Container(width: 1, color: RpgColors.divider),
                Expanded(
                  child: _StatCell(
                    label: 'TOTAL QUESTS',
                    value: '${activeQuests.length + completedQuests.length}',
                    color: RpgColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _fmtXp(int xp) {
    if (xp >= 10000) return '${(xp / 1000).toStringAsFixed(1)}k';
    return xp.toString();
  }
}

class _StatCell extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatCell(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}
