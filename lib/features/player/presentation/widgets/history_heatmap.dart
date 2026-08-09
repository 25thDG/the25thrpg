import 'dart:math';

import 'package:flutter/material.dart';

import '../../domain/entities/activity_history.dart';
import 'insight_charts.dart';
import 'rpg_colors.dart';

const _gap = 3.0;
const _rows = 7; // Monday → Sunday, top to bottom
const _monthLabelH = 15.0;

const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

/// Accent for a track, matching the colour it already has elsewhere.
Color trackColor(HistoryTrack track) => switch (track) {
      HistoryTrack.japanese => InsightColors.jp,
      HistoryTrack.mindfulness => const Color(0xFF26A69A),
      HistoryTrack.sobriety => InsightColors.sober,
    };

/// Minute thresholds for the four shades of a filled day.
///
/// Deliberately fixed rather than scaled to the busiest day: a single
/// backfilled block of several thousand minutes would otherwise push every
/// ordinary day down to the faintest shade and the calendar would read empty.
List<int> _steps(HistoryTrack track) => switch (track) {
      HistoryTrack.japanese => const [10, 30, 60],
      HistoryTrack.mindfulness => const [3, 6, 15],
      HistoryTrack.sobriety => const [1, 1, 1],
    };

/// A year of days as a grid — one column per week, one square per day.
class HistoryHeatmap extends StatefulWidget {
  final HistorySeries series;

  const HistoryHeatmap({super.key, required this.series});

  @override
  State<HistoryHeatmap> createState() => _HistoryHeatmapState();
}

class _HistoryHeatmapState extends State<HistoryHeatmap> {
  DayCell? _selected;

  @override
  void didUpdateWidget(HistoryHeatmap old) {
    super.didUpdateWidget(old);
    // Switching track invalidates the pinned day.
    if (old.series.track != widget.series.track) _selected = null;
  }

  @override
  Widget build(BuildContext context) {
    final days = widget.series.days;
    if (days.isEmpty) return const SizedBox(height: 120);

    final color = trackColor(widget.series.track);
    final blanks = days.first.day.weekday - 1; // Monday === 0
    final columns = ((blanks + days.length) / _rows).ceil();

    return LayoutBuilder(
      builder: (context, constraints) {
        final cell =
            ((constraints.maxWidth - (columns - 1) * _gap) / columns)
                .clamp(4.0, 20.0);
        final gridH = _rows * cell + (_rows - 1) * _gap;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (d) {
                final col = (d.localPosition.dx / (cell + _gap)).floor();
                final row =
                    ((d.localPosition.dy - _monthLabelH) / (cell + _gap))
                        .floor();
                final index = col * _rows + row - blanks;
                if (index < 0 || index >= days.length) return;
                if (row < 0 || row >= _rows) return;
                setState(() => _selected =
                    _selected?.day == days[index].day ? null : days[index]);
              },
              child: SizedBox(
                width: double.infinity,
                height: gridH + _monthLabelH,
                child: CustomPaint(
                  painter: _HeatmapPainter(
                    days: days,
                    track: widget.series.track,
                    color: color,
                    blanks: blanks,
                    cell: cell,
                    selected: _selected,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            _Legend(
              track: widget.series.track,
              color: color,
              selected: _selected,
            ),
          ],
        );
      },
    );
  }
}

class _HeatmapPainter extends CustomPainter {
  final List<DayCell> days;
  final HistoryTrack track;
  final Color color;
  final int blanks;
  final double cell;
  final DayCell? selected;

  _HeatmapPainter({
    required this.days,
    required this.track,
    required this.color,
    required this.blanks,
    required this.cell,
    required this.selected,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final radius = Radius.circular(max(1.5, cell * 0.22));
    final steps = _steps(track);
    int lastMonth = -1;
    // Right edge of the last month label drawn, so two months starting in
    // adjacent columns cannot print on top of each other.
    double labelRight = -1000;

    for (int i = 0; i < days.length; i++) {
      final d = days[i];
      final slot = i + blanks;
      final col = slot ~/ _rows;
      final row = slot % _rows;
      final x = col * (cell + _gap);
      final y = _monthLabelH + row * (cell + _gap);
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, cell, cell),
        radius,
      );

      canvas.drawRRect(rect, Paint()..color = _fill(d, steps));

      if (selected?.day == d.day) {
        canvas.drawRRect(
          rect.inflate(1.5),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.4
            ..color = Colors.white.withValues(alpha: 0.85),
        );
      }

      // Month label above the first column that starts a new month.
      if (row == 0 || i == 0) {
        if (d.day.month != lastMonth) {
          lastMonth = d.day.month;
          final tp = TextPainter(
            text: TextSpan(
              text: _months[d.day.month - 1].toUpperCase(),
              style: const TextStyle(
                color: RpgColors.textMuted,
                fontSize: 8,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
            textDirection: TextDirection.ltr,
          )..layout();
          // Pull the last month back inside the box rather than dropping it —
          // the current month is the one you most want to find.
          final lx = min(x, size.width - tp.width);
          if (lx >= labelRight + 5) {
            tp.paint(canvas, Offset(lx, 0));
            labelRight = lx + tp.width;
          }
        }
      }
    }
  }

  Color _fill(DayCell d, List<int> steps) {
    if (track.isVerdict) {
      return switch (d.clean) {
        true => InsightColors.sober,
        false => InsightColors.bad,
        null => const Color(0xFF1B1B22),
      };
    }
    if (d.minutes <= 0) return const Color(0xFF1B1B22);
    if (d.minutes < steps[0]) return color.withValues(alpha: 0.28);
    if (d.minutes < steps[1]) return color.withValues(alpha: 0.50);
    if (d.minutes < steps[2]) return color.withValues(alpha: 0.75);
    return color;
  }

  @override
  bool shouldRepaint(covariant _HeatmapPainter old) =>
      old.days != days ||
      old.selected?.day != selected?.day ||
      old.cell != cell ||
      old.track != track;
}

/// Either the shade key, or the day you tapped.
class _Legend extends StatelessWidget {
  final HistoryTrack track;
  final Color color;
  final DayCell? selected;

  const _Legend({
    required this.track,
    required this.color,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    if (selected != null) {
      return Text(
        _describe(selected!),
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      );
    }

    final swatches = track.isVerdict
        ? <(Color, String)>[
            (InsightColors.sober, 'clean'),
            (InsightColors.bad, 'slip'),
            (const Color(0xFF1B1B22), 'not logged'),
          ]
        : <(Color, String)>[
            (const Color(0xFF1B1B22), 'none'),
            (color.withValues(alpha: 0.28), ''),
            (color.withValues(alpha: 0.50), ''),
            (color.withValues(alpha: 0.75), ''),
            (color, 'most'),
          ];

    return Row(
      children: [
        for (final (i, (c, label)) in swatches.indexed) ...[
          if (i > 0) const SizedBox(width: 5),
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(
              color: c,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          if (label.isNotEmpty) ...[
            const SizedBox(width: 5),
            Text(
              label,
              style: const TextStyle(
                color: RpgColors.textMuted,
                fontSize: 9,
              ),
            ),
            const SizedBox(width: 6),
          ],
        ],
        const Spacer(),
        const Text(
          'TAP A DAY',
          style: TextStyle(
            color: RpgColors.textMuted,
            fontSize: 8,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }

  String _describe(DayCell d) {
    final date = '${_weekday(d.day.weekday)} ${d.day.day} '
        '${_months[d.day.month - 1]}';
    if (track.isVerdict) {
      return switch (d.clean) {
        true => '$date · clean',
        false => '$date · slipped',
        null => '$date · not logged',
      };
    }
    return d.minutes == 0
        ? '$date · nothing logged'
        : '$date · ${fmtDuration(d.minutes)}';
  }

  static String _weekday(int w) =>
      const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][w - 1];
}
