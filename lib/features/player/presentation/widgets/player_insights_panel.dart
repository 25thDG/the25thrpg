import 'package:flutter/material.dart';

import '../../domain/entities/player_stats.dart';
import '../../domain/entities/skill_summary.dart';
import 'insight_charts.dart';
import 'insight_detail_sheets.dart';
import 'player_card.dart';
import 'player_section.dart';
import 'rpg_colors.dart';

/// Insight cards, all driven by recent activity rather than lifetime averages
/// that only ever shrink.
///
/// Every card is a door: the face carries the one number worth glancing at, and
/// a tap opens the full breakdown in a detail sheet.
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
      trailing: 'TAP FOR DETAIL',
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            JapaneseInsightCard(skill: jp),
            SobrietyInsightCard(skill: mind),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: _NextLevelCard(skill: jp)),
                  const SizedBox(width: 10),
                  Expanded(child: _WealthCard(skill: wealth)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Japanese: 7-day bars + trend ──────────────────────────────────────────────

/// Shows the week itself, not a sentence about it: one bar per day, today
/// highlighted, with the 7-day average and its move against the 30-day pace.
class JapaneseInsightCard extends StatelessWidget {
  final SkillSummary? skill;

  const JapaneseInsightCard({super.key, required this.skill});

  @override
  Widget build(BuildContext context) {
    final s = skill;
    final days = s?.dailyMinutesLast7 ?? const <int>[];
    final delta = s?.paceDeltaPerDay ?? 0;
    final flat = delta.abs() < 0.5;
    final hasPace = s != null && s.hasPaceData;

    return PlayerCard(
      accent: InsightColors.jp,
      onTap: s == null ? null : () => showJapaneseInsight(context, s),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CardLabel('JAPANESE · LAST 7 DAYS', color: InsightColors.jp),
              const Spacer(),
              if (hasPace && !flat)
                TrendPill(up: delta > 0, amount: fmtPerDay(delta.abs())),
              const SizedBox(width: 4),
              const TapHint(color: InsightColors.jp),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                hasPace ? fmtPerDay(s.avg7PerDay) : '—',
                style: TextStyle(
                  color:
                      hasPace ? RpgColors.textPrimary : RpgColors.textMuted,
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  height: 1.0,
                  letterSpacing: -1.0,
                ),
              ),
              const SizedBox(width: 6),
              const Padding(
                padding: EdgeInsets.only(bottom: 3),
                child: Text(
                  'avg / day',
                  style: TextStyle(color: RpgColors.textMuted, fontSize: 10),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          WeekBars(days: days, color: InsightColors.jp),
        ],
      ),
    );
  }
}

// ── Sobriety: flame + 14-day strip ────────────────────────────────────────────

/// The streak as a flame, plus the last fortnight as a row of pips so a wobble
/// is visible instead of hidden inside an average.
class SobrietyInsightCard extends StatelessWidget {
  final SkillSummary? skill;

  const SobrietyInsightCard({super.key, required this.skill});

  @override
  Widget build(BuildContext context) {
    final s = skill;
    final logged = s?.loggedCleanDays ?? 0;
    final streak = s?.cleanStreak ?? 0;
    final stale = s?.isCleanLogStale ?? false;
    final live = logged > 0 && !stale;
    final lit = live && streak > 0;
    final color = lit ? InsightColors.sober : InsightColors.bad;

    return PlayerCard(
      accent: live ? color : null,
      onTap: s == null ? null : () => showSobrietyInsight(context, s),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CardLabel(
                'SOBRIETY',
                color: live ? color : RpgColors.textMuted,
              ),
              const Spacer(),
              if (logged > 0)
                Text(
                  '${(s!.cleanRate * 100).round()}% CLEAN · BEST ${s.longestCleanStreak}d',
                  style: const TextStyle(
                    color: RpgColors.textMuted,
                    fontSize: 8,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                  ),
                ),
              const SizedBox(width: 4),
              TapHint(color: live ? color : RpgColors.textSecondary),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                lit ? Icons.local_fire_department : Icons.mode_night_outlined,
                size: 30,
                color: color.withValues(alpha: live ? 1.0 : 0.5),
                shadows: lit
                    ? [
                        Shadow(
                          color: color.withValues(alpha: 0.7),
                          blurRadius: 14,
                        ),
                      ]
                    : null,
              ),
              const SizedBox(width: 10),
              Text(
                logged == 0 || stale ? '—' : '$streak',
                style: TextStyle(
                  color: live ? RpgColors.textPrimary : RpgColors.textMuted,
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  height: 1.0,
                  letterSpacing: -1.0,
                ),
              ),
              const SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(
                  logged == 0
                      ? 'nothing logged'
                      : (stale
                          ? 'unlogged ${s!.daysSinceLastCleanLog}d'
                          : 'day streak'),
                  style: const TextStyle(
                    color: RpgColors.textMuted,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          if (logged > 0) ...[
            const SizedBox(height: 14),
            DayPips(days: s!.last14CleanDays),
          ],
        ],
      ),
    );
  }
}

// ── Compact cards ─────────────────────────────────────────────────────────────

class _NextLevelCard extends StatelessWidget {
  final SkillSummary? skill;

  const _NextLevelCard({required this.skill});

  @override
  Widget build(BuildContext context) {
    final s = skill;
    final days = s?.daysToNextLevel;
    final maxed = s != null && s.minutesToNextLevel == null;

    return PlayerCard(
      accent: InsightColors.level,
      margin: EdgeInsets.zero,
      onTap: s == null ? null : () => showNextLevelInsight(context, s),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CardLabel('NEXT LEVEL', color: InsightColors.level),
              const Spacer(),
              const TapHint(color: InsightColors.level),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            maxed ? 'MAX' : (days == null ? '—' : fmtEta(days)),
            style: TextStyle(
              color: days == null && !maxed
                  ? RpgColors.textMuted
                  : InsightColors.level,
              fontSize: 26,
              fontWeight: FontWeight.w800,
              height: 1.0,
              letterSpacing: -0.8,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            s == null
                ? 'japanese'
                : (maxed
                    ? 'chasing mastery'
                    : 'JP Lv ${s.nextLevel} · ${s.remainingToNextLevel} to go'),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: RpgColors.textMuted,
              fontSize: 9,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _WealthCard extends StatelessWidget {
  final SkillSummary? skill;

  const _WealthCard({required this.skill});

  @override
  Widget build(BuildContext context) {
    final s = skill;
    final achieved = s != null && s.currentNetWorthEur >= 1_000_000;
    final value = s == null
        ? '—'
        : (achieved ? 'DONE' : (s.projectedTimeToMillion ?? '—'));
    final progress =
        s == null ? 0.0 : (s.currentNetWorthEur / 1_000_000).clamp(0.0, 1.0);

    return PlayerCard(
      accent: InsightColors.wealth,
      margin: EdgeInsets.zero,
      onTap: s == null ? null : () => showWealthInsight(context, s),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CardLabel('TO €1M', color: InsightColors.wealth),
              const Spacer(),
              const TapHint(color: InsightColors.wealth),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              color: value == '—'
                  ? RpgColors.textMuted
                  : InsightColors.wealth,
              fontSize: 26,
              fontWeight: FontWeight.w800,
              height: 1.0,
              letterSpacing: -0.8,
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: progress),
              duration: const Duration(milliseconds: 1200),
              curve: Curves.easeOutCubic,
              builder: (_, v, _) => LinearProgressIndicator(
                value: v,
                minHeight: 4,
                backgroundColor: RpgColors.progressTrack,
                valueColor:
                    const AlwaysStoppedAnimation(InsightColors.wealth),
              ),
            ),
          ),
          const SizedBox(height: 7),
          Text(
            '${(progress * 100).toStringAsFixed(1)}% of the way',
            style: const TextStyle(color: RpgColors.textMuted, fontSize: 9),
          ),
        ],
      ),
    );
  }
}
