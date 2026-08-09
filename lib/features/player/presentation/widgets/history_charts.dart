import 'dart:math';

import 'package:flutter/material.dart';

import '../../domain/entities/activity_history.dart';
import 'insight_charts.dart';
import 'rpg_colors.dart';

const _monthNames = [
  'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
  'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC',
];

// ── Monthly totals ────────────────────────────────────────────────────────────

/// One bar per month, so a run of good months and the month it fell apart are
/// both visible at a glance.
class MonthlyBars extends StatelessWidget {
  final List<MonthBucket> months;
  final Color color;
  final bool verdictTrack;

  const MonthlyBars({
    super.key,
    required this.months,
    required this.color,
    this.verdictTrack = false,
  });

  @override
  Widget build(BuildContext context) {
    if (months.isEmpty) return const SizedBox(height: 120);

    final peak = months.fold(
      0,
      (m, b) => max(m, verdictTrack ? b.activeDays : b.minutes),
    );

    return SizedBox(
      height: 128,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final (i, b) in months.indexed) ...[
            if (i > 0) const SizedBox(width: 5),
            Expanded(
              child: _MonthColumn(
                bucket: b,
                peak: peak,
                color: color,
                verdictTrack: verdictTrack,
                isLast: i == months.length - 1,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MonthColumn extends StatelessWidget {
  final MonthBucket bucket;
  final int peak;
  final Color color;
  final bool verdictTrack;
  final bool isLast;

  const _MonthColumn({
    required this.bucket,
    required this.peak,
    required this.color,
    required this.verdictTrack,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final value = verdictTrack ? bucket.activeDays : bucket.minutes;
    final f = peak == 0 ? 0.0 : value / peak;

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        SizedBox(
          height: 15,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value == 0
                  ? '·'
                  : (verdictTrack ? '$value' : fmtDuration(value)),
              maxLines: 1,
              style: TextStyle(
                color: value == 0
                    ? RpgColors.textMuted
                    : color.withValues(alpha: isLast ? 1.0 : 0.85),
                fontSize: 8,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: f),
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeOutCubic,
          builder: (_, v, _) => Container(
            height: 3 + v * 72,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: value == 0
                  ? RpgColors.progressTrack
                  : color.withValues(alpha: isLast ? 1.0 : 0.55),
              boxShadow: value > 0 && isLast
                  ? [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 8)]
                  : null,
            ),
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 12,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              _monthNames[bucket.month.month - 1],
              maxLines: 1,
              style: TextStyle(
                color: isLast
                    ? color.withValues(alpha: 0.9)
                    : RpgColors.textMuted,
                fontSize: 8,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Weekday pattern ───────────────────────────────────────────────────────────

/// Which days of the week you actually show up on. Bar height is the share of
/// that weekday you worked, not the minutes — the point is the habit, not the
/// volume.
class WeekdayBars extends StatelessWidget {
  final List<WeekdayBucket> weekdays;
  final Color color;

  const WeekdayBars({super.key, required this.weekdays, required this.color});

  @override
  Widget build(BuildContext context) {
    final peak = weekdays.fold(0.0, (m, b) => max(m, b.rate));

    return SizedBox(
      height: 116,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final (i, b) in weekdays.indexed) ...[
            if (i > 0) const SizedBox(width: 7),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  SizedBox(
                    height: 14,
                    child: Text(
                      b.totalDays == 0 ? '·' : '${(b.rate * 100).round()}%',
                      style: TextStyle(
                        color: b.rate == peak && peak > 0
                            ? color
                            : RpgColors.textMuted,
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  TweenAnimationBuilder<double>(
                    tween: Tween(
                      begin: 0,
                      end: peak == 0 ? 0.0 : b.rate / peak,
                    ),
                    duration: Duration(milliseconds: 700 + i * 50),
                    curve: Curves.easeOutCubic,
                    builder: (_, v, _) => Container(
                      height: 3 + v * 62,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color: b.activeDays == 0
                            ? RpgColors.progressTrack
                            : color.withValues(
                                alpha: b.rate == peak ? 1.0 : 0.45,
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    b.name[0],
                    style: TextStyle(
                      color: b.rate == peak && peak > 0
                          ? color.withValues(alpha: 0.9)
                          : RpgColors.textMuted,
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Category split ────────────────────────────────────────────────────────────

/// Where the hours actually went, as one stacked bar plus a legend.
class CategorySplit extends StatelessWidget {
  final Map<String, int> minutes;

  const CategorySplit({super.key, required this.minutes});

  /// A distinct hue per logging category, stable regardless of order.
  static const _palette = <String, Color>{
    'vocab': Color(0xFF4FC3F7),
    'passive': Color(0xFF7E77E8),
    'active': Color(0xFF26A69A),
    'output': Color(0xFFF59E0B),
    'reading': Color(0xFF66BB6A),
    'accent': Color(0xFFEF5350),
  };

  static Color colorFor(String key, int index) =>
      _palette[key] ??
      [
        const Color(0xFF4FC3F7),
        const Color(0xFF7E77E8),
        const Color(0xFF26A69A),
        const Color(0xFFF59E0B),
        const Color(0xFF66BB6A),
        const Color(0xFFEF5350),
      ][index % 6];

  @override
  Widget build(BuildContext context) {
    final entries = minutes.entries.where((e) => e.value > 0).toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    if (entries.isEmpty) return const SizedBox.shrink();

    final total = entries.fold(0, (s, e) => s + e.value);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(5),
          child: SizedBox(
            height: 10,
            child: Row(
              children: [
                for (final (i, e) in entries.indexed)
                  Expanded(
                    flex: max(1, e.value),
                    child: Container(color: colorFor(e.key, i)),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        for (final (i, e) in entries.indexed)
          Padding(
            padding: const EdgeInsets.only(bottom: 9),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: colorFor(e.key, i),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    e.key.toUpperCase(),
                    style: const TextStyle(
                      color: RpgColors.textSecondary,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                Text(
                  '${(e.value / total * 100).round()}%',
                  style: const TextStyle(
                    color: RpgColors.textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 62,
                  child: Text(
                    fmtDuration(e.value),
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      color: RpgColors.textPrimary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// ── Records ───────────────────────────────────────────────────────────────────

/// A labelled row of one number and its context.
class RecordRow extends StatelessWidget {
  final String label;
  final String value;
  final String? detail;
  final Color color;

  const RecordRow({
    super.key,
    required this.label,
    required this.value,
    required this.color,
    this.detail,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: RpgColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                  ),
                ),
                if (detail != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    detail!,
                    style: const TextStyle(
                      color: RpgColors.textMuted,
                      fontSize: 9,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 14),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
            ),
          ),
        ],
      ),
    );
  }
}
