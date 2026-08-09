import 'package:flutter/material.dart';

import '../../domain/entities/activity_history.dart';
import '../widgets/history_charts.dart';
import '../widgets/history_heatmap.dart';
import '../widgets/insight_charts.dart';
import '../widgets/player_card.dart';
import '../widgets/rpg_colors.dart';

const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

String _dateYear(DateTime d) => '${d.day} ${_months[d.month - 1]} ${d.year}';

/// The long view: everything ever logged, analysed.
///
/// The rest of the app answers "how am I doing today". This answers "what has
/// actually happened" — the calendar, the trend by month, the weekday habit,
/// the records, and where the hours went.
class HistoryPage extends StatefulWidget {
  final ActivityHistory history;

  const HistoryPage({super.key, required this.history});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  HistoryTrack _track = HistoryTrack.japanese;
  HistoryRange _range = HistoryRange.months6;

  @override
  Widget build(BuildContext context) {
    final full = widget.history[_track];
    final series = full.lastRange(_range.days).trimmedToFirstEntry();
    final color = trackColor(_track);
    final verdict = _track.isVerdict;

    return Scaffold(
      backgroundColor: RpgColors.pageBg,
      appBar: AppBar(
        backgroundColor: RpgColors.pageBg,
        foregroundColor: RpgColors.textSecondary,
        scrolledUnderElevation: 0,
        elevation: 0,
        title: const Text(
          'ANALYSIS',
          style: TextStyle(
            color: RpgColors.textMuted,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 2.8,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 56),
        children: [
          _Segmented<HistoryTrack>(
            values: HistoryTrack.values,
            selected: _track,
            label: (t) => t.displayName,
            colorOf: trackColor,
            onChanged: (t) => setState(() => _track = t),
          ),
          const SizedBox(height: 10),
          _Segmented<HistoryRange>(
            values: HistoryRange.values,
            selected: _range,
            label: (r) => r.label,
            colorOf: (_) => color,
            compact: true,
            onChanged: (r) => setState(() => _range = r),
          ),
          const SizedBox(height: 18),

          _Headline(series: series, color: color, verdict: verdict),
          const SizedBox(height: 10),

          _Block(
            title: 'CALENDAR',
            trailing: '${series.days.length} DAYS',
            color: color,
            child: HistoryHeatmap(series: series),
          ),

          _Block(
            title: 'BY MONTH',
            trailing: verdict ? 'CLEAN DAYS' : 'TIME LOGGED',
            color: color,
            child: MonthlyBars(
              months: series.byMonth(),
              color: color,
              verdictTrack: verdict,
            ),
          ),

          _Block(
            title: 'WEEKDAY HABIT',
            trailing: 'HOW OFTEN',
            color: color,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                WeekdayBars(weekdays: series.byWeekday(), color: color),
                const SizedBox(height: 14),
                _WeekdayNote(series: series),
              ],
            ),
          ),

          _Block(
            title: 'RECORDS',
            color: color,
            child: _Records(series: series, color: color, verdict: verdict),
          ),

          if (series.categoryMinutes.isNotEmpty)
            _Block(
              title: 'WHERE THE TIME WENT',
              trailing: 'IN RANGE',
              color: color,
              child: CategorySplit(minutes: series.categoryMinutes),
            ),

          if (full.backfillEntries > 0) _BackfillNote(series: full),

          const SizedBox(height: 6),
          _Readout(series: series, verdict: verdict),
        ],
      ),
    );
  }
}

// ── Chrome ────────────────────────────────────────────────────────────────────

class _Segmented<T> extends StatelessWidget {
  final List<T> values;
  final T selected;
  final String Function(T) label;
  final Color Function(T) colorOf;
  final ValueChanged<T> onChanged;
  final bool compact;

  const _Segmented({
    required this.values,
    required this.selected,
    required this.label,
    required this.colorOf,
    required this.onChanged,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final (i, v) in values.indexed) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: _Tab(
              label: label(v),
              color: colorOf(v),
              active: v == selected,
              compact: compact,
              onTap: () => onChanged(v),
            ),
          ),
        ],
      ],
    );
  }
}

class _Tab extends StatelessWidget {
  final String label;
  final Color color;
  final bool active;
  final bool compact;
  final VoidCallback onTap;

  const _Tab({
    required this.label,
    required this.color,
    required this.active,
    required this.compact,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(compact ? 9 : 12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(vertical: compact ? 8 : 11),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(compact ? 9 : 12),
            color: color.withValues(alpha: active ? 0.14 : 0.03),
            border: Border.all(
              color: color.withValues(alpha: active ? 0.5 : 0.10),
            ),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              maxLines: 1,
              style: TextStyle(
                color: active ? color : RpgColors.textMuted,
                fontSize: compact ? 9 : 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A titled section of the analysis.
class _Block extends StatelessWidget {
  final String title;
  final String? trailing;
  final Color color;
  final Widget child;

  const _Block({
    required this.title,
    required this.color,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return PlayerCard(
      accent: color,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CardLabel(title, color: color),
              const Spacer(),
              if (trailing != null)
                Text(
                  trailing!,
                  style: const TextStyle(
                    color: RpgColors.textMuted,
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.4,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }
}

// ── Sections ──────────────────────────────────────────────────────────────────

/// The four numbers that frame everything below.
class _Headline extends StatelessWidget {
  final HistorySeries series;
  final Color color;
  final bool verdict;

  const _Headline({
    required this.series,
    required this.color,
    required this.verdict,
  });

  @override
  Widget build(BuildContext context) {
    final cells = verdict
        ? <(String, String)>[
            ('CLEAN DAYS', '${series.winDays}'),
            ('SLIPS', '${series.loggedDays - series.winDays}'),
            (
              'CLEAN RATE',
              series.loggedDays == 0
                  ? '—'
                  : '${(series.winDays / series.loggedDays * 100).round()}%'
            ),
            ('STREAK', '${series.currentStreak}d'),
          ]
        : <(String, String)>[
            ('TOTAL', fmtDuration(series.totalMinutes)),
            ('DAYS ACTIVE', '${series.winDays}'),
            ('% OF DAYS', '${(series.consistency * 100).round()}%'),
            ('STREAK', '${series.currentStreak}d'),
          ];

    return Row(
      children: [
        for (final (i, (label, value)) in cells.indexed) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: PlayerCard(
              accent: color,
              margin: EdgeInsets.zero,
              padding: const EdgeInsets.fromLTRB(10, 12, 8, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: RpgColors.textMuted,
                      fontSize: 7.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 7),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      value,
                      maxLines: 1,
                      style: TextStyle(
                        color: color,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _Records extends StatelessWidget {
  final HistorySeries series;
  final Color color;
  final bool verdict;

  const _Records({
    required this.series,
    required this.color,
    required this.verdict,
  });

  @override
  Widget build(BuildContext context) {
    final best = series.bestDay;
    final week = series.bestWeek;
    final months = series.byMonth();
    final bestMonth = months.isEmpty
        ? null
        : months.reduce((a, b) =>
            (verdict ? b.activeDays > a.activeDays : b.minutes > a.minutes)
                ? b
                : a);

    return Column(
      children: [
        if (!verdict && best != null && best.minutes > 0)
          RecordRow(
            label: 'Best day',
            detail: _dateYear(best.day),
            value: fmtDuration(best.minutes),
            color: color,
          ),
        if (!verdict && week != null)
          RecordRow(
            label: 'Best week',
            detail: 'from ${_dateYear(week.start)}',
            value: fmtDuration(week.minutes),
            color: color,
          ),
        if (bestMonth != null)
          RecordRow(
            label: 'Best month',
            detail:
                '${_months[bestMonth.month.month - 1]} ${bestMonth.month.year}',
            value: verdict
                ? '${bestMonth.activeDays}d'
                : fmtDuration(bestMonth.minutes),
            color: color,
          ),
        RecordRow(
          label: 'Longest streak',
          detail: 'consecutive days',
          value: '${series.longestStreak}d',
          color: color,
        ),
        RecordRow(
          label: 'Longest gap',
          detail: 'days off in a row',
          value: '${series.longestGap}d',
          color: color,
        ),
        if (!verdict)
          RecordRow(
            label: 'Sessions',
            detail: '${fmtDuration(series.avgSessionMinutes)} average, '
                '${fmtDuration(series.avgPerActiveDay)} per active day',
            value: '${series.sessionCount}',
            color: color,
          ),
      ],
    );
  }
}

class _WeekdayNote extends StatelessWidget {
  final HistorySeries series;

  const _WeekdayNote({required this.series});

  @override
  Widget build(BuildContext context) {
    final ex = series.weekdayExtremes;
    if (ex == null) return const SizedBox.shrink();

    return Text(
      '${ex.best.name} is your strongest day at '
      '${(ex.best.rate * 100).round()}%. '
      '${ex.worst.name} is the one that gets away, at '
      '${(ex.worst.rate * 100).round()}%.',
      style: const TextStyle(
        color: RpgColors.textSecondary,
        fontSize: 11,
        height: 1.5,
      ),
    );
  }
}

/// Explains the hours held out of the day figures, so the totals reconcile.
class _BackfillNote extends StatelessWidget {
  final HistorySeries series;

  const _BackfillNote({required this.series});

  @override
  Widget build(BuildContext context) {
    final plural = series.backfillEntries == 1 ? 'entry' : 'entries';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
      decoration: BoxDecoration(
        color: RpgColors.panelBgAlt,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: RpgColors.divider),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.history_toggle_off,
              size: 15, color: RpgColors.textMuted),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              '${fmtDuration(series.backfillMinutes)} across '
              '${series.backfillEntries} $plural is practice from before the '
              'app, so it sits outside the day-by-day figures above. It still '
              'counts toward your level.',
              style: const TextStyle(
                color: RpgColors.textMuted,
                fontSize: 10.5,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A plain reading of the whole page.
class _Readout extends StatelessWidget {
  final HistorySeries series;
  final bool verdict;

  const _Readout({required this.series, required this.verdict});

  @override
  Widget build(BuildContext context) {
    final lines = <String>[];
    final total = series.days.length;
    final first = series.firstLoggedDay;

    if (series.winDays == 0) {
      lines.add('Nothing logged on this track in this range.');
    } else if (verdict) {
      lines.add('You logged ${series.loggedDays} of $total days and stayed '
          'clean on ${series.winDays}. Your best run was '
          '${series.longestStreak} days; the worst stretch was '
          '${series.longestGap} days off the wagon or unlogged.');
    } else {
      lines.add('${fmtDuration(series.totalMinutes)} across ${series.winDays} '
          'of $total days — ${(series.consistency * 100).round()}% of them, '
          'averaging ${fmtPerDay(series.avgPerDay)} a day overall.');
      lines.add('When you did sit down it was '
          '${fmtDuration(series.avgPerActiveDay)}, over '
          '${series.sessionCount} sessions.');
    }

    if (first != null) {
      lines.add('First entry in this range: ${_dateYear(first)}.');
    }

    final months = series.byMonth();
    if (months.length >= 2 && !verdict && series.winDays > 0) {
      final last = months.last;
      final prev = months[months.length - 2];
      final delta = last.minutes - prev.minutes;
      if (delta.abs() > 30) {
        lines.add(delta > 0
            ? '${_months[last.month.month - 1]} is ahead of '
                '${_months[prev.month.month - 1]} by ${fmtDuration(delta)} '
                'so far.'
            : '${_months[last.month.month - 1]} is behind '
                '${_months[prev.month.month - 1]} by ${fmtDuration(-delta)}.');
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final line in lines)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                line,
                style: const TextStyle(
                  color: RpgColors.textSecondary,
                  fontSize: 12,
                  height: 1.55,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
