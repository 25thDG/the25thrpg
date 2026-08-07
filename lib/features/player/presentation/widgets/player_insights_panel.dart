import 'package:flutter/material.dart';

import '../../domain/entities/player_stats.dart';
import '../../domain/entities/skill_summary.dart';
import 'player_row.dart';
import 'player_section.dart';
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

    return PlayerSection(
      title: 'INSIGHTS',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _japanesePaceRow(jp),
          const PlayerRowDivider(),
          _nextLevelRow(jp),
          const PlayerRowDivider(),
          _sobrietyRow(mind),
          const PlayerRowDivider(),
          _insightRow(
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
      return _insightRow(
        color: _colorJp,
        label: 'JAPANESE',
        sublabel: 'no sessions in the last 30 days',
        value: '—',
      );
    }

    final delta = jp.paceDeltaPerDay;
    // Below half a minute a day either way is noise, not a trend.
    final flat = delta.abs() < 0.5;

    return _insightRow(
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
      return _insightRow(
        color: _colorLevel,
        label: 'NEXT LEVEL',
        sublabel: 'japanese',
        value: '—',
      );
    }

    final remaining = jp.minutesToNextLevel;
    if (remaining == null) {
      return _insightRow(
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
      return _insightRow(
        color: _colorLevel,
        label: 'NEXT LEVEL',
        sublabel: 'japanese Lv ${jp.nextLevel} · $togo · no recent pace',
        value: '—',
      );
    }

    return _insightRow(
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
      return _insightRow(
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
      return _insightRow(
        color: RpgColors.textMuted,
        label: 'SOBRIETY',
        sublabel: 'not logged for ${mind.daysSinceLastCleanLog}d · $history',
        value: '—',
      );
    }

    return _insightRow(
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

/// Maps an insight onto the shared row shape.
Widget _insightRow({
  required Color color,
  required String label,
  required String sublabel,
  required String value,
  Color? valueColor,
  _Trend? trend,
}) =>
    PlayerRow(
      dotColor: color,
      title: label,
      subtitle: sublabel,
      value: value,
      valueColor: valueColor,
      badge: trend == null ? null : _TrendBadge(trend: trend),
    );

/// A rise or fall against the longer-run baseline.
class _Trend {
  final bool up;
  final String amount;

  const _Trend({required this.up, required this.amount});
}

/// A rise or fall shown as a small badge under the value.
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
        '${trend.up ? '\u25B2' : '\u25BC'} ${trend.amount}',
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
