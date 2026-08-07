import 'package:flutter/material.dart';

import 'rpg_colors.dart';

/// Palette shared by the insight cards and the sheets they open, so a card and
/// its detail view always read as the same object.
abstract final class InsightColors {
  static const jp = Color(0xFF4FC3F7);
  static const level = Color(0xFFFFA726);
  static const wealth = Color(0xFF10B981);
  static const sober = Color(0xFF66BB6A);
  static const bad = Color(0xFFEF5350);
}

// ── Formatters ────────────────────────────────────────────────────────────────

/// "18m", "1h 20m" — a rate, so it always reads per-day in context.
String fmtPerDay(double minPerDay) {
  if (minPerDay <= 0) return '0m';
  if (minPerDay < 60) return '${minPerDay.round()}m';
  final h = (minPerDay / 60).floor();
  final m = (minPerDay % 60).round();
  return m == 0 ? '${h}h' : '${h}h ${m}m';
}

/// "47m", "2h 10m", "214h" — a total.
String fmtDuration(num minutes) {
  final total = minutes.round();
  if (total <= 0) return '0m';
  final h = total ~/ 60;
  final m = total % 60;
  if (h == 0) return '${m}m';
  if (h >= 100) return '${h}h';
  return m == 0 ? '${h}h' : '${h}h ${m}m';
}

String fmtEur(num value) {
  final a = value.abs();
  if (a >= 1000000) return '€${(value / 1000000).toStringAsFixed(2)}M';
  if (a >= 1000) return '€${(value / 1000).toStringAsFixed(1)}k';
  return '€${value.round()}';
}

/// Compact horizon: "TODAY", "23d", "7w", "8mo", "1.4y".
String fmtEta(int days) {
  if (days <= 1) return 'TODAY';
  if (days <= 30) return '${days}d';
  if (days <= 90) return '${(days / 7).round()}w';
  if (days < 365) return '${(days / 30).round()}mo';
  return '${(days / 365).toStringAsFixed(1)}y';
}

const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

String fmtDate(DateTime d) => '${d.day} ${_months[d.month - 1]} ${d.year}';

// ── Week bars ─────────────────────────────────────────────────────────────────

/// One bar per day of the week, scaled to the week's best day. Today is lit.
class WeekBars extends StatelessWidget {
  final List<int> days;
  final Color color;

  /// Height of the filled portion at the week's peak.
  final double barHeight;
  final double barWidth;

  /// Prints the minutes above each bar — used in the detail sheet.
  final bool showValues;

  const WeekBars({
    super.key,
    required this.days,
    required this.color,
    this.barHeight = 38,
    this.barWidth = 13,
    this.showValues = false,
  });

  static const _labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
  static const _valueH = 14.0;
  static const _labelH = 12.0;

  double get _boxHeight =>
      (showValues ? _valueH : 0) + 4 + barHeight + 6 + _labelH;

  @override
  Widget build(BuildContext context) {
    if (days.length != 7) return SizedBox(height: _boxHeight);

    final peak = days.fold(0, (m, v) => v > m ? v : m);
    final today = DateTime.now().weekday; // 1 = Monday

    return SizedBox(
      height: _boxHeight,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (int i = 0; i < 7; i++) ...[
            if (i > 0) const SizedBox(width: 6),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (showValues)
                    SizedBox(
                      height: _valueH,
                      child: Center(
                        child: Text(
                          days[i] == 0 ? '·' : fmtDuration(days[i]),
                          maxLines: 1,
                          style: TextStyle(
                            color: days[i] == 0
                                ? RpgColors.textMuted
                                : color.withValues(alpha: 0.9),
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  TweenAnimationBuilder<double>(
                    tween: Tween(
                      begin: 0,
                      end: peak == 0 ? 0.0 : days[i] / peak,
                    ),
                    duration: Duration(milliseconds: 700 + i * 60),
                    curve: Curves.easeOutCubic,
                    builder: (_, v, _) => Container(
                      // Narrow columns — a full-width bar reads as a block,
                      // not a chart, when only one day has data.
                      width: barWidth,
                      // A floor keeps empty days visible as a track.
                      height: 4 + v * barHeight,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color: days[i] == 0
                            ? RpgColors.progressTrack
                            : color.withValues(alpha: i == 6 ? 1.0 : 0.55),
                        boxShadow: days[i] > 0 && i == 6
                            ? [
                                BoxShadow(
                                  color: color.withValues(alpha: 0.5),
                                  blurRadius: 8,
                                ),
                              ]
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    height: _labelH,
                    child: Text(
                      // days[6] is today, so walk back from today's weekday.
                      _labels[(today - 1 - (6 - i)) % 7],
                      style: TextStyle(
                        color: i == 6
                            ? color.withValues(alpha: 0.9)
                            : RpgColors.textMuted,
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                      ),
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

// ── Day pips ──────────────────────────────────────────────────────────────────

/// One pip per day: green clean, red slip, dark when the day was never logged.
class DayPips extends StatelessWidget {
  final List<bool?> days;
  final double height;

  const DayPips({super.key, required this.days, this.height = 6});

  @override
  Widget build(BuildContext context) {
    if (days.isEmpty) return const SizedBox.shrink();

    return Row(
      children: [
        for (int i = 0; i < days.length; i++) ...[
          if (i > 0) const SizedBox(width: 5),
          Expanded(
            child: Container(
              height: height,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(height / 2),
                color: switch (days[i]) {
                  true => InsightColors.sober,
                  false => InsightColors.bad,
                  null => RpgColors.progressTrack,
                },
                boxShadow: days[i] == true
                    ? [
                        BoxShadow(
                          color: InsightColors.sober.withValues(alpha: 0.4),
                          blurRadius: 5,
                        ),
                      ]
                    : null,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ── Trend pill ────────────────────────────────────────────────────────────────

class TrendPill extends StatelessWidget {
  final bool up;
  final String amount;

  const TrendPill({super.key, required this.up, required this.amount});

  @override
  Widget build(BuildContext context) {
    final color = up ? InsightColors.sober : InsightColors.bad;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            up ? Icons.arrow_upward : Icons.arrow_downward,
            size: 10,
            color: color,
          ),
          const SizedBox(width: 3),
          Text(
            amount,
            style: TextStyle(
              color: color,
              fontSize: 9,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// The "there is more behind this" affordance every insight card carries.
class TapHint extends StatelessWidget {
  final Color color;

  const TapHint({super.key, required this.color});

  @override
  Widget build(BuildContext context) => Icon(
        Icons.chevron_right,
        size: 15,
        color: color.withValues(alpha: 0.45),
      );
}
