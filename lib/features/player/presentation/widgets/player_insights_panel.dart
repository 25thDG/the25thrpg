import 'package:flutter/material.dart';

import '../../domain/entities/player_stats.dart';
import '../../domain/entities/skill_summary.dart';
import 'rpg_colors.dart';

/// Panel showing daily-average practice times for JP & Mindfulness
/// and a wealth projection to €1M.
class PlayerInsightsPanel extends StatelessWidget {
  final PlayerStats stats;

  const PlayerInsightsPanel({super.key, required this.stats});

  SkillSummary? _skill(SkillId id) {
    try {
      return stats.skills.firstWhere((s) => s.skill == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final jp = _skill(SkillId.japanese);
    final mind = _skill(SkillId.mindfulness);
    final wealth = _skill(SkillId.wealth);

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
          _InsightsHeader(),
          _InsightRow(
            color: const Color(0xFF4FC3F7),
            label: 'JAPANESE',
            sublabel: 'avg / day since Apr 11',
            value: _fmtAvg(jp?.dailyAverageMinutes ?? 0),
          ),
          const _Divider(),
          _InsightRow(
            color: const Color(0xFF26A69A),
            label: 'MINDFULNESS',
            sublabel: 'avg / day since Apr 11',
            value: _fmtAvg(mind?.dailyAverageMinutes ?? 0),
          ),
          const _Divider(),
          _InsightRow(
            color: const Color(0xFF10B981),
            label: 'WEALTH',
            sublabel: 'est. time to €1,000,000',
            value: _wealthValue(wealth),
          ),
        ],
      ),
    );
  }

  String _wealthValue(SkillSummary? wealth) {
    if (wealth == null) return '—';
    if (wealth.currentNetWorthEur >= 1_000_000) return 'ACHIEVED';
    return wealth.projectedTimeToMillion ?? '—';
  }

  static String _fmtAvg(double minPerDay) {
    if (minPerDay <= 0) return '—';
    if (minPerDay < 60) return '${minPerDay.round()}m';
    final h = (minPerDay / 60).floor();
    final m = (minPerDay % 60).round();
    if (m == 0) return '${h}h';
    return '${h}h ${m}m';
  }
}

class _InsightsHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 3,
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
            gradient: LinearGradient(
              colors: [Color(0xFFC0392B), Color(0xFFE74C3C)],
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
            'INSIGHTS',
            style: TextStyle(
              color: RpgColors.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 2.4,
            ),
          ),
        ),
      ],
    );
  }
}

class _InsightRow extends StatelessWidget {
  final Color color;
  final String label;
  final String sublabel;
  final String value;

  const _InsightRow({
    required this.color,
    required this.label,
    required this.sublabel,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Colored left accent bar
          Container(width: 3, color: color),
          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Label + sublabel
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          label,
                          style: TextStyle(
                            color: color.withValues(alpha: 0.9),
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.8,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          sublabel,
                          style: const TextStyle(
                            color: RpgColors.textMuted,
                            fontSize: 9,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Value
                  _AnimatedValue(value: value, color: color),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedValue extends StatelessWidget {
  final String value;
  final Color color;

  const _AnimatedValue({required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutCubic,
      builder: (_, t, child) => Opacity(
        opacity: t,
        child: child,
      ),
      child: Text(
        value,
        style: TextStyle(
          color: value == '—'
              ? RpgColors.textMuted
              : (value == 'ACHIEVED'
                  ? const Color(0xFF10B981)
                  : RpgColors.textPrimary),
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return const Divider(
      height: 1,
      thickness: 1,
      color: RpgColors.divider,
      indent: 3,
    );
  }
}
