import 'dart:math';

import 'package:flutter/material.dart';

import '../../domain/entities/skill_summary.dart';
import 'insight_charts.dart';
import 'rpg_colors.dart';

/// Every insight card opens one of these: the same numbers the card shows, plus
/// the context the card had no room for — the full breakdown, the pace maths and
/// a line of plain-language read-out at the bottom.

// ── Japanese ──────────────────────────────────────────────────────────────────

void showJapaneseInsight(BuildContext context, SkillSummary s) {
  final days = s.dailyMinutesLast7;
  final best = days.isEmpty ? 0 : days.reduce(max);
  final active = days.where((d) => d > 0).length;
  final delta = s.paceDeltaPerDay;
  final need = s.minutesToNextLevel;

  final notes = <String>[];
  if (!s.hasPaceData) {
    notes.add('Nothing logged in the last 30 days. A single session restarts '
        'the pace clock and every number here wakes up.');
  } else if (delta >= 0.5) {
    notes.add('Your last 7 days run ${fmtPerDay(delta)}/day ahead of your '
        'monthly pace. Hold it and Lv ${s.nextLevel} arrives early.');
  } else if (delta <= -0.5) {
    notes.add('You have slowed ${fmtPerDay(delta.abs())}/day against your '
        'monthly pace. One good session puts the week back on top.');
  } else {
    notes.add('Steady — this week is tracking your monthly pace almost exactly.');
  }

  if (active == 7) {
    notes.add('Seven for seven. Consistency is doing more for the level curve '
        'than any single long session.');
  } else if (active > 0) {
    notes.add('$active of the last 7 days had a session, '
        '${7 - active} were blank. Your best day was ${fmtDuration(best)}.');
  }

  if (need != null && need > 0) {
    final date = DateTime.now().add(const Duration(days: 30));
    notes.add('${fmtPerDay(need / 30)}/day from today puts Lv ${s.nextLevel} '
        'on ${fmtDate(date)}.');
  }

  _open(
    context,
    InsightSheet(
      title: 'JAPANESE',
      subtitle: 'LAST 7 DAYS',
      color: InsightColors.jp,
      hero: fmtDuration(s.last7DaysMinutes),
      heroCaption: 'logged this week',
      visual: WeekBars(
        days: days,
        color: InsightColors.jp,
        barHeight: 56,
        barWidth: 18,
        showValues: true,
      ),
      stats: [
        ('7-DAY AVG', '${fmtPerDay(s.avg7PerDay)}/day'),
        ('30-DAY AVG', '${fmtPerDay(s.avg30PerDay)}/day'),
        ('BEST DAY', fmtDuration(best)),
        ('DAYS ACTIVE', '$active / 7'),
        ('LAST 30 DAYS', fmtDuration(s.last30DaysMinutes)),
        ('LIFETIME', fmtDuration(s.lifetimeMinutes)),
        ('LEVEL', 'Lv ${s.level}'),
        // Exact rather than the card's rounded-up figure — the sheet is where
        // the precision belongs.
        ('TO NEXT', need == null ? s.remainingToNextLevel : fmtDuration(need)),
      ],
      notes: notes,
    ),
  );
}

// ── Sobriety ──────────────────────────────────────────────────────────────────

void showSobrietyInsight(BuildContext context, SkillSummary s) {
  final pips = s.last14CleanDays;
  final clean14 = pips.where((d) => d == true).length;
  final slip14 = pips.where((d) => d == false).length;
  final blank14 = pips.length - clean14 - slip14;
  final bonus = s.cleanDayBonus.floor();
  final toBonus = s.cleanDaysToNextBonus;
  final since = s.daysSinceLastCleanLog;

  final notes = <String>[];
  if (s.isCleanLogStale && since != null) {
    notes.add('Nothing logged for $since days. The streak is paused, not '
        'broken — one entry starts it counting again.');
  }
  if (toBonus == null) {
    notes.add('Your discipline bonus is maxed at '
        '+${SkillSummary.maxCleanDayBonus.toInt()} levels. Everything past '
        'this is meditation minutes.');
  } else {
    notes.add('${SkillSummary.cleanDaysPerLevelPoint} clean days buy +1 '
        'Mindfulness level, up to +${SkillSummary.maxCleanDayBonus.toInt()}. '
        '$toBonus more days takes you to +${bonus + 1}.');
  }
  if (s.cleanStreak > 0 && s.cleanStreak >= s.longestCleanStreak) {
    notes.add('This is the longest run you have ever logged. '
        'Every day from here is a new record.');
  } else if (s.longestCleanStreak > 0) {
    notes.add('Your record is ${s.longestCleanStreak} days — '
        '${s.longestCleanStreak - s.cleanStreak} more to beat it.');
  }
  if (s.loggedCleanDays > 0) {
    final perMonth = s.cleanRate * 30;
    notes.add('At your current ${(s.cleanRate * 100).round()}% rate you bank '
        '~${perMonth.round()} clean days a month, worth about '
        '+${(perMonth / SkillSummary.cleanDaysPerLevelPoint).toStringAsFixed(1)} '
        'levels.');
  }

  final lit = s.cleanStreak > 0 && !s.isCleanLogStale;

  _open(
    context,
    InsightSheet(
      title: 'SOBRIETY',
      subtitle: 'LAST 14 DAYS',
      color: lit ? InsightColors.sober : InsightColors.bad,
      hero: s.loggedCleanDays == 0 || s.isCleanLogStale ? '—' : '${s.cleanStreak}',
      heroCaption: s.loggedCleanDays == 0
          ? 'nothing logged yet'
          : (s.isCleanLogStale ? 'streak paused' : 'day streak'),
      heroIcon: lit ? Icons.local_fire_department : Icons.mode_night_outlined,
      visual: pips.isEmpty
          ? null
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DayPips(days: pips, height: 9),
                const SizedBox(height: 10),
                Text(
                  '$clean14 clean · $slip14 slips · $blank14 unlogged',
                  style: const TextStyle(
                    color: RpgColors.textMuted,
                    fontSize: 9,
                    letterSpacing: 0.6,
                  ),
                ),
              ],
            ),
      stats: [
        ('CURRENT STREAK', s.cleanStreak > 0 ? '${s.cleanStreak}d' : '—'),
        ('BEST STREAK', '${s.longestCleanStreak}d'),
        ('CLEAN DAYS', '${s.cleanDays}'),
        ('SLIPS', '${s.relapseDays}'),
        ('CLEAN RATE', '${(s.cleanRate * 100).round()}%'),
        ('DAYS LOGGED', '${s.loggedCleanDays}'),
        ('SKILL BONUS', '+$bonus lv'),
        ('LAST LOG', _lastLog(since)),
      ],
      notes: notes,
    ),
  );
}

String _lastLog(int? days) => switch (days) {
      null => '—',
      0 => 'today',
      1 => 'yesterday',
      _ => '${days}d ago',
    };

// ── Next level ────────────────────────────────────────────────────────────────

void showNextLevelInsight(BuildContext context, SkillSummary s) {
  final need = s.minutesToNextLevel;
  final eta = s.daysToNextLevel;
  final maxed = need == null;
  final arrives =
      eta == null ? null : DateTime.now().add(Duration(days: eta));
  final after = s.nextLevelMilestones(count: 2);

  final notes = <String>[];
  if (maxed) {
    notes.add('Level 100 is behind you. From here the climb is mastery points, '
        'each one a fixed block of practice.');
  } else if (eta == null) {
    notes.add('No 30-day pace to project from yet. Log a session and this '
        'whole card fills in with a real date.');
  } else {
    notes.add('At ${fmtPerDay(s.avg30PerDay)}/day, Lv ${s.nextLevel} lands on '
        '${fmtDate(arrives!)}.');
  }
  if (need != null && need > 0) {
    notes.add('Levels are square-root scaled: Lv ${s.nextLevel} sits at '
        '${fmtDuration(s.lifetimeMinutes + need)} lifetime, and every level '
        'after it costs more than the one before.');
  }
  if (after.length > 1) {
    notes.add('Lv ${s.nextLevel + 1} is a further ${after[1].remaining} '
        'from where you stand today.');
  }

  _open(
    context,
    InsightSheet(
      title: 'NEXT LEVEL',
      subtitle: 'JAPANESE',
      color: InsightColors.level,
      hero: maxed ? 'MAX' : (eta == null ? '—' : fmtEta(eta)),
      heroCaption: maxed ? 'chasing mastery' : 'to Lv ${s.nextLevel}',
      visual: need == null || need <= 0
          ? null
          : _PaceChips(
              remaining: need,
              pace: s.avg30PerDay,
              color: InsightColors.level,
            ),
      stats: [
        ('TARGET', 'Lv ${s.nextLevel}'),
        ('REMAINING', need == null ? '—' : fmtDuration(need)),
        ('CURRENT PACE', '${fmtPerDay(s.avg30PerDay)}/day'),
        ('PROGRESS', '${(s.progressToNextLevel * 100).round()}%'),
        ('ARRIVES', arrives == null ? '—' : fmtDate(arrives)),
        ('LIFETIME NOW', fmtDuration(s.lifetimeMinutes)),
        ('LEVEL SITS AT',
            need == null ? '—' : fmtDuration(s.lifetimeMinutes + need)),
        ('THEN LV ${s.nextLevel + 1}',
            after.length > 1 ? '+${after[1].remaining}' : '—'),
      ],
      notes: notes,
    ),
  );
}

/// Three deadlines and the daily practice each one demands. The fastest one you
/// already cover at your current pace is lit.
class _PaceChips extends StatelessWidget {
  final double remaining;
  final double pace;
  final Color color;

  const _PaceChips({
    required this.remaining,
    required this.pace,
    required this.color,
  });

  static const _horizons = [7, 30, 90];

  @override
  Widget build(BuildContext context) {
    // Index of the tightest deadline the current pace already meets.
    int onTrack = -1;
    for (int i = 0; i < _horizons.length; i++) {
      if (pace > 0 && pace >= remaining / _horizons[i]) {
        onTrack = i;
        break;
      }
    }

    return Row(
      children: [
        for (int i = 0; i < _horizons.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: _Chip(
              label: 'IN ${_horizons[i]} DAYS',
              value: '${fmtPerDay(remaining / _horizons[i])}/day',
              color: color,
              lit: i == onTrack,
            ),
          ),
        ],
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool lit;

  const _Chip({
    required this.label,
    required this.value,
    required this.color,
    required this.lit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: color.withValues(alpha: lit ? 0.14 : 0.04),
        border: Border.all(
          color: color.withValues(alpha: lit ? 0.45 : 0.10),
        ),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              color: RpgColors.textMuted,
              fontSize: 8,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              maxLines: 1,
              style: TextStyle(
                color: lit ? color : RpgColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Wealth ────────────────────────────────────────────────────────────────────

void showWealthInsight(BuildContext context, SkillSummary s) {
  const goal = 1000000.0;
  final nw = s.currentNetWorthEur;
  final growth = s.monthlyGrowthEur;
  final achieved = nw >= goal;
  final progress = (nw / goal).clamp(0.0, 1.0);
  final months =
      (growth == null || growth <= 0 || achieved) ? null : ((goal - nw) / growth).ceil();
  final arrives = months == null
      ? null
      : DateTime(DateTime.now().year, DateTime.now().month + months,
          DateTime.now().day);
  final next = s.nextLevelMilestones(count: 1).first;

  // Sqrt scaling means the level moves much faster than the money early on.
  final doubled = (sqrt(nw * 2 / goal) * 100).floor().clamp(1, 100);

  final notes = <String>[];
  if (achieved) {
    notes.add('Target cleared. Wealth is on the mastery track now — every '
        '€250k past €1M is one more mastery point.');
  } else if (months == null) {
    notes.add('Not enough net-worth snapshots to project a date. Log another '
        'one and this turns into a real countdown.');
  } else {
    notes.add('At ${fmtEur(growth!)}/month you cross €1M in $months months, '
        'around ${fmtDate(arrives!)}.');
  }
  notes.add('Money is square-root scaled: ${fmtEur(nw)} is only '
      '${(progress * 100).toStringAsFixed(1)}% of the goal but already '
      'Lv ${s.level}. Doubling it would take you to about Lv $doubled.');
  if (!achieved) {
    notes.add('Lv ${s.level + 1} unlocks at ${next.target ?? '—'} — '
        '${next.remaining} from here.');
  }

  _open(
    context,
    InsightSheet(
      title: 'WEALTH',
      subtitle: 'TO €1M',
      color: InsightColors.wealth,
      hero: achieved ? 'DONE' : (s.projectedTimeToMillion ?? '—'),
      heroCaption: achieved ? '€1M cleared' : 'at current growth',
      visual: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: progress),
              duration: const Duration(milliseconds: 1100),
              curve: Curves.easeOutCubic,
              builder: (_, v, _) => LinearProgressIndicator(
                value: v,
                minHeight: 8,
                backgroundColor: RpgColors.progressTrack,
                valueColor:
                    const AlwaysStoppedAnimation(InsightColors.wealth),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${(progress * 100).toStringAsFixed(1)}% of €1M',
                style: const TextStyle(
                  color: RpgColors.textMuted,
                  fontSize: 9,
                  letterSpacing: 0.6,
                ),
              ),
              Text(
                fmtEur(nw),
                style: const TextStyle(
                  color: InsightColors.wealth,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
        ],
      ),
      stats: [
        ('NET WORTH', fmtEur(nw)),
        ('MONTHLY GROWTH', growth == null ? '—' : fmtEur(growth)),
        ('REMAINING', achieved ? '—' : fmtEur(goal - nw)),
        ('PROGRESS', '${(progress * 100).toStringAsFixed(1)}%'),
        ('WEALTH LEVEL', 'Lv ${s.level}'),
        ('TO NEXT LEVEL', s.remainingToNextLevel),
        ('LV ${s.level + 1} AT', next.target ?? '—'),
        ('€1M ARRIVES', arrives == null ? '—' : fmtDate(arrives)),
      ],
      notes: notes,
    ),
  );
}

// ── Shell ─────────────────────────────────────────────────────────────────────

void _open(BuildContext context, Widget sheet) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => sheet,
  );
}

/// One layout for every insight detail view: title, one loud number, an optional
/// chart, the full stat breakdown, then the read-out.
class InsightSheet extends StatefulWidget {
  final String title;
  final String subtitle;
  final Color color;
  final String hero;
  final String heroCaption;
  final IconData? heroIcon;
  final Widget? visual;
  final List<(String, String)> stats;
  final List<String> notes;

  const InsightSheet({
    super.key,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.hero,
    required this.heroCaption,
    this.heroIcon,
    this.visual,
    this.stats = const [],
    this.notes = const [],
  });

  @override
  State<InsightSheet> createState() => _InsightSheetState();
}

class _InsightSheetState extends State<InsightSheet>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final List<Animation<double>> _anims;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    );
    // Header, visual, stats, notes — each one slides in behind the last.
    _anims = List.generate(4, (i) {
      final start = i * 0.12;
      return CurvedAnimation(
        parent: _ctrl,
        curve: Interval(start, (start + 0.5).clamp(0.0, 1.0),
            curve: Curves.easeOutCubic),
      );
    });
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Widget _step(int i, Widget child) => FadeTransition(
        opacity: _anims[i],
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.12),
            end: Offset.zero,
          ).animate(_anims[i]),
          child: child,
        ),
      );

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);

    return Container(
      constraints: BoxConstraints(maxHeight: media.size.height * 0.86),
      decoration: BoxDecoration(
        color: RpgColors.panelBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        border: Border.all(color: widget.color.withValues(alpha: 0.14)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 10),
              width: 40,
              height: 3,
              decoration: BoxDecoration(
                color: RpgColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Container(height: 1, color: widget.color.withValues(alpha: 0.28)),
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(22, 22, 22, 24 + media.padding.bottom),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _step(0, _Header(widget: widget)),
                  if (widget.visual != null) ...[
                    const SizedBox(height: 24),
                    _step(1, widget.visual!),
                  ],
                  if (widget.stats.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _step(2, _StatGrid(stats: widget.stats)),
                  ],
                  if (widget.notes.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    _step(
                      3,
                      Column(
                        children: [
                          for (final note in widget.notes)
                            _Note(text: note, color: widget.color),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final InsightSheet widget;

  const _Header({required this.widget});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              widget.title,
              style: TextStyle(
                color: widget.color,
                fontSize: 13,
                fontWeight: FontWeight.w800,
                letterSpacing: 2.4,
              ),
            ),
            const Spacer(),
            Text(
              widget.subtitle,
              style: const TextStyle(
                color: RpgColors.textMuted,
                fontSize: 9,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.6,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (widget.heroIcon != null) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Icon(
                  widget.heroIcon,
                  size: 34,
                  color: widget.color,
                  shadows: [
                    Shadow(
                      color: widget.color.withValues(alpha: 0.6),
                      blurRadius: 16,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
            ],
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.bottomLeft,
                child: Text(
                  widget.hero,
                  maxLines: 1,
                  style: const TextStyle(
                    color: RpgColors.textPrimary,
                    fontSize: 40,
                    fontWeight: FontWeight.w900,
                    height: 1.0,
                    letterSpacing: -1.6,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                widget.heroCaption,
                style: const TextStyle(
                  color: RpgColors.textMuted,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Two-column breakdown, hairline-separated.
class _StatGrid extends StatelessWidget {
  final List<(String, String)> stats;

  const _StatGrid({required this.stats});

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];

    for (int i = 0; i < stats.length; i += 2) {
      if (i > 0) {
        rows.add(const Divider(
          height: 1,
          thickness: 1,
          color: RpgColors.divider,
        ));
      }
      final right = i + 1 < stats.length ? stats[i + 1] : null;
      rows.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _Cell(label: stats[i].$1, value: stats[i].$2)),
              const VerticalDivider(
                width: 1,
                thickness: 1,
                color: RpgColors.divider,
              ),
              Expanded(
                child: right == null
                    ? const SizedBox()
                    : _Cell(label: right.$1, value: right.$2),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: RpgColors.panelBgAlt,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: RpgColors.divider),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: rows),
    );
  }
}

class _Cell extends StatelessWidget {
  final String label;
  final String value;

  const _Cell({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: RpgColors.textMuted,
              fontSize: 8,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              maxLines: 1,
              style: const TextStyle(
                color: RpgColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A line of plain-language read-out — the part a number alone cannot say.
class _Note extends StatelessWidget {
  final String text;
  final Color color;

  const _Note({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(13, 12, 14, 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.12)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color,
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.7),
                    blurRadius: 6,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: RpgColors.textSecondary,
                fontSize: 11.5,
                height: 1.45,
                letterSpacing: 0.1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
