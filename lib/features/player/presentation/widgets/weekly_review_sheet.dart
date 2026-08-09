import 'package:flutter/material.dart';

import '../../domain/entities/activity_history.dart';
import '../../domain/entities/weekly_review.dart';
import 'history_heatmap.dart' show trackColor;
import 'insight_charts.dart';
import 'insight_detail_sheets.dart';
import 'player_card.dart';
import 'rpg_colors.dart';

const _weekAccent = Color(0xFF8B7BE8);

/// Formats a track's week figure — minutes on the time tracks, days on
/// sobriety.
String _value(TrackWeek t, int amount) =>
    t.isVerdictTrack ? '$amount/7' : fmtDuration(amount);

// ── Card ──────────────────────────────────────────────────────────────────────

/// Sits at the top of the insights, so the week is the first thing read.
class WeekInsightCard extends StatelessWidget {
  final WeeklyReview? review;

  const WeekInsightCard({super.key, required this.review});

  @override
  Widget build(BuildContext context) {
    final r = review;

    return PlayerCard(
      accent: _weekAccent,
      onTap: r == null ? null : () => showWeeklyReview(context, r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CardLabel('THIS WEEK', color: _weekAccent),
              const Spacer(),
              if (r != null && r.streakDays > 0)
                Text(
                  '${r.streakDays} DAY STREAK',
                  style: const TextStyle(
                    color: RpgColors.textMuted,
                    fontSize: 8,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                  ),
                ),
              const SizedBox(width: 4),
              const TapHint(color: _weekAccent),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                r == null ? '—' : '${r.daysWorked}',
                style: TextStyle(
                  color: r == null ? RpgColors.textMuted : RpgColors.textPrimary,
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
                  'of 7 days worked',
                  style: TextStyle(color: RpgColors.textMuted, fontSize: 10),
                ),
              ),
            ],
          ),
          if (r != null) ...[
            const SizedBox(height: 14),
            _WeekDots(review: r),
          ],
        ],
      ),
    );
  }
}

/// One pill per track: how it moved against last week.
class _WeekDots extends StatelessWidget {
  final WeeklyReview review;

  const _WeekDots({required this.review});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final (i, t) in review.tracks.indexed) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(child: _TrackPill(week: t)),
        ],
      ],
    );
  }
}

class _TrackPill extends StatelessWidget {
  final TrackWeek week;

  const _TrackPill({required this.week});

  @override
  Widget build(BuildContext context) {
    final color = trackColor(week.track);
    final live = week.verdict != TrendVerdict.idle;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: color.withValues(alpha: live ? 0.10 : 0.04),
        border: Border.all(color: color.withValues(alpha: live ? 0.3 : 0.08)),
      ),
      child: Column(
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              week.track.displayName,
              maxLines: 1,
              style: TextStyle(
                color: live ? color : RpgColors.textMuted,
                fontSize: 7.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
          ),
          const SizedBox(height: 5),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(_icon(week.verdict), size: 10, color: _tint(week.verdict)),
                const SizedBox(width: 3),
                Text(
                  _value(week, week.thisWeek),
                  maxLines: 1,
                  style: TextStyle(
                    color: live ? RpgColors.textPrimary : RpgColors.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static IconData _icon(TrendVerdict v) => switch (v) {
        TrendVerdict.up => Icons.arrow_upward,
        TrendVerdict.down => Icons.arrow_downward,
        TrendVerdict.flat => Icons.remove,
        TrendVerdict.idle => Icons.circle_outlined,
      };

  static Color _tint(TrendVerdict v) => switch (v) {
        TrendVerdict.up => InsightColors.sober,
        TrendVerdict.down => InsightColors.bad,
        _ => RpgColors.textMuted,
      };
}

// ── Sheet ─────────────────────────────────────────────────────────────────────

void showWeeklyReview(BuildContext context, WeeklyReview r) {
  showInsightSheet(
    context,
    InsightSheet(
      title: 'THE WEEK',
      subtitle: '${_date(r.from)} – ${_date(r.to)}',
      color: _weekAccent,
      hero: '${r.daysWorked}/7',
      heroCaption: 'days worked',
      visual: _WeekBreakdown(review: r),
      stats: [
        for (final t in r.tracks) ...[
          ('${t.track.displayName} NOW', _value(t, t.thisWeek)),
          ('${t.track.displayName} BEFORE', _value(t, t.lastWeek)),
        ],
      ],
      notes: weeklyReviewNotes(r),
    ),
  );
}

String _date(DateTime d) {
  const m = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return '${d.day} ${m[d.month - 1]}';
}

/// This week against last week, one bar pair per track.
class _WeekBreakdown extends StatelessWidget {
  final WeeklyReview review;

  const _WeekBreakdown({required this.review});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final (i, t) in review.tracks.indexed) ...[
          if (i > 0) const SizedBox(height: 16),
          _CompareRow(week: t),
        ],
      ],
    );
  }
}

class _CompareRow extends StatelessWidget {
  final TrackWeek week;

  const _CompareRow({required this.week});

  @override
  Widget build(BuildContext context) {
    final color = trackColor(week.track);
    // Both bars share a scale, so the pair is directly comparable.
    final peak = [week.thisWeek, week.lastWeek].reduce((a, b) => a > b ? a : b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              week.track.displayName,
              style: TextStyle(
                color: color,
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
            const Spacer(),
            Text(
              _value(week, week.thisWeek),
              style: const TextStyle(
                color: RpgColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _Bar(value: week.thisWeek, peak: peak, color: color, lit: true),
        const SizedBox(height: 5),
        Row(
          children: [
            Expanded(
              child: _Bar(
                value: week.lastWeek,
                peak: peak,
                color: color,
                lit: false,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'last week ${_value(week, week.lastWeek)}',
              style: const TextStyle(
                color: RpgColors.textMuted,
                fontSize: 9,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Bar extends StatelessWidget {
  final int value;
  final int peak;
  final Color color;
  final bool lit;

  const _Bar({
    required this.value,
    required this.peak,
    required this.color,
    required this.lit,
  });

  @override
  Widget build(BuildContext context) {
    final f = peak == 0 ? 0.0 : value / peak;
    return ClipRRect(
      borderRadius: BorderRadius.circular(3),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: f),
        duration: const Duration(milliseconds: 900),
        curve: Curves.easeOutCubic,
        builder: (_, v, _) => Stack(
          children: [
            Container(height: lit ? 8 : 5, color: RpgColors.progressTrack),
            FractionallySizedBox(
              widthFactor: v.clamp(0.0, 1.0),
              child: Container(
                height: lit ? 8 : 5,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: lit ? 1.0 : 0.35),
                  boxShadow: lit && v > 0
                      ? [
                          BoxShadow(
                            color: color.withValues(alpha: 0.5),
                            blurRadius: 7,
                          ),
                        ]
                      : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Copy ──────────────────────────────────────────────────────────────────────

/// The read-out. Written here rather than in the entity because it is wording,
/// not maths.
List<String> weeklyReviewNotes(WeeklyReview r) {
  final notes = <String>[];

  if (r.isBlank) {
    notes.add('Nothing logged in seven days. One session on any track starts '
        'the week over.');
  } else {
    notes.add('You worked ${r.daysWorked} of the last 7 days.');
  }

  final best = r.bestMove;
  if (best != null) {
    notes.add('Biggest gain: ${best.track.displayName} at '
        '${_value(best, best.thisWeek)}, against '
        '${_value(best, best.lastWeek)} the week before.');
  }

  final focus = r.focus;
  if (focus != null) {
    notes.add(focus.hasStalled
        ? '${focus.track.displayName} went untouched all week. It was '
            '${_value(focus, focus.lastWeek)} the week before.'
        : '${focus.track.displayName} slipped to '
            '${_value(focus, focus.thisWeek)} from '
            '${_value(focus, focus.lastWeek)} — that is the one to pick back up.');
  }

  if (r.streakDays > 0) {
    notes.add('Your ${r.streakDays}-day streak is still alive. Log something '
        'today to keep it.');
  } else {
    notes.add('No streak running. Today would be day one.');
  }

  return notes;
}
