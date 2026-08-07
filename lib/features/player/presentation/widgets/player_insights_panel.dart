import 'package:flutter/material.dart';

import '../../domain/entities/player_stats.dart';
import '../../domain/entities/skill_summary.dart';
import 'rpg_colors.dart';

const _colorJp = Color(0xFF4FC3F7);
const _colorLevel = Color(0xFFFFA726);
const _colorWealth = Color(0xFF10B981);
const _colorSober = Color(0xFF66BB6A);
const _colorBad = Color(0xFFEF5350);

/// Panel showing recent-pace and balance insights that react to the last few
/// days, rather than lifetime averages that only ever shrink.
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
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: RpgColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _InsightsHeader(),
          _japanesePaceRow(jp),
          const _Divider(),
          _nextLevelRow(jp),
          const _Divider(),
          _sobrietyRow(mind),
          const _Divider(),
          _InsightRow(
            color: _colorWealth,
            label: 'WEALTH',
            sublabel: 'est. time to €1,000,000',
            value: _wealthValue(wealth),
            valueColor: wealth != null &&
                    wealth.currentNetWorthEur >= 1_000_000
                ? _colorWealth
                : null,
          ),
        ],
      ),
    );
  }

  // ── Japanese: last 7d vs last 30d ──────────────────────────────────────────

  Widget _japanesePaceRow(SkillSummary? jp) {
    if (jp == null || !jp.hasPaceData) {
      return const _InsightRow(
        color: _colorJp,
        label: 'JAPANESE',
        sublabel: 'no sessions in the last 30 days',
        value: '—',
      );
    }

    final delta = jp.paceDeltaPerDay;
    // Below half a minute a day either way is noise, not a trend.
    final flat = delta.abs() < 0.5;

    return _InsightRow(
      color: _colorJp,
      label: 'JAPANESE',
      sublabel: flat
          ? 'last 7d avg · steady vs 30d'
          : 'last 7d avg · vs ${_fmtAvg(jp.avg30PerDay)} over 30d',
      value: _fmtAvg(jp.avg7PerDay),
      trend: flat ? null : _Trend(up: delta > 0, amount: _fmtAvg(delta.abs())),
    );
  }

  // ── Japanese: ETA to the next level ────────────────────────────────────────

  Widget _nextLevelRow(SkillSummary? jp) {
    if (jp == null) {
      return const _InsightRow(
        color: _colorLevel,
        label: 'NEXT LEVEL',
        sublabel: 'japanese',
        value: '—',
      );
    }

    final remaining = jp.minutesToNextLevel;
    if (remaining == null) {
      return _InsightRow(
        color: _colorLevel,
        label: 'NEXT LEVEL',
        sublabel: 'japanese · maxed, chasing mastery',
        value: 'MAX',
        valueColor: _colorLevel,
      );
    }

    final togo = '${jp.remainingToNextLevel} to go';
    final days = jp.daysToNextLevel;

    // No recent pace — show the distance, but no date we can't back up.
    if (days == null) {
      return _InsightRow(
        color: _colorLevel,
        label: 'NEXT LEVEL',
        sublabel: 'japanese Lv ${jp.nextLevel} · $togo · no recent pace',
        value: '—',
      );
    }

    return _InsightRow(
      color: _colorLevel,
      label: 'NEXT LEVEL',
      sublabel: 'japanese Lv ${jp.nextLevel} · $togo at 30d pace',
      value: _fmtDays(days),
      valueColor: _colorLevel,
    );
  }

  /// Compact ETA — days up to a month, then weeks, then months.
  static String _fmtDays(int days) {
    if (days <= 1) return 'TODAY';
    if (days <= 30) return '${days}d';
    if (days <= 90) return '${(days / 7).round()}w';
    if (days < 365) return '${(days / 30).round()}mo';
    return '${(days / 365).toStringAsFixed(1)}y';
  }

  // ── Mindfulness: sobriety streak ───────────────────────────────────────────

  Widget _sobrietyRow(SkillSummary? mind) {
    if (mind == null || mind.loggedCleanDays == 0) {
      return const _InsightRow(
        color: _colorSober,
        label: 'SOBRIETY',
        sublabel: 'no days logged yet',
        value: '—',
      );
    }

    final streak = mind.cleanStreak;
    final ratePct = (mind.cleanRate * 100).round();
    final history = '${mind.cleanDays}/${mind.loggedCleanDays} days clean '
        '($ratePct%) · best ${mind.longestCleanStreak}d';

    // Logging lapsed — a zero streak here means "unknown", not "relapsed".
    if (mind.isCleanLogStale) {
      return _InsightRow(
        color: RpgColors.textMuted,
        label: 'SOBRIETY',
        sublabel: 'not logged for ${mind.daysSinceLastCleanLog}d · $history',
        value: '—',
      );
    }

    return _InsightRow(
      color: streak > 0 ? _colorSober : _colorBad,
      label: 'SOBRIETY',
      sublabel: streak > 0 ? history : 'streak reset · $history',
      value: streak > 0 ? '$streak DAYS' : 'DAY 0',
      valueColor: streak > 0 ? _colorSober : _colorBad,
    );
  }

  // ── Wealth ─────────────────────────────────────────────────────────────────

  String _wealthValue(SkillSummary? wealth) {
    if (wealth == null) return '—';
    if (wealth.currentNetWorthEur >= 1_000_000) return 'ACHIEVED';
    return wealth.projectedTimeToMillion ?? '—';
  }

  static String _fmtAvg(double minPerDay) {
    if (minPerDay <= 0) return '0m';
    if (minPerDay < 60) return '${minPerDay.round()}m';
    final h = (minPerDay / 60).floor();
    final m = (minPerDay % 60).round();
    if (m == 0) return '${h}h';
    return '${h}h ${m}m';
  }
}

/// A rise or fall against the longer-run baseline.
class _Trend {
  final bool up;
  final String amount;

  const _Trend({required this.up, required this.amount});
}

class _InsightsHeader extends StatelessWidget {
  const _InsightsHeader();

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
  final Color? valueColor;
  final _Trend? trend;

  const _InsightRow({
    required this.color,
    required this.label,
    required this.sublabel,
    required this.value,
    this.valueColor,
    this.trend,
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
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: RpgColors.textMuted,
                            fontSize: 9,
                            height: 1.35,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Value + optional trend badge
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _AnimatedValue(value: value, color: valueColor),
                      if (trend != null) ...[
                        const SizedBox(height: 4),
                        _TrendBadge(trend: trend!),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrendBadge extends StatelessWidget {
  final _Trend trend;

  const _TrendBadge({required this.trend});

  @override
  Widget build(BuildContext context) {
    final color = trend.up ? _colorSober : _colorBad;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        '${trend.up ? '▲' : '▼'} ${trend.amount}',
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

class _AnimatedValue extends StatelessWidget {
  final String value;
  final Color? color;

  const _AnimatedValue({required this.value, this.color});

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
              : (color ?? RpgColors.textPrimary),
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
