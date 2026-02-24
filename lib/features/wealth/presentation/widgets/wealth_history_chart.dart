import 'dart:math' show min, max;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../../domain/entities/wealth_snapshot.dart';
import 'section_card.dart';
import 'wealth_formatters.dart';

class WealthHistoryChart extends StatelessWidget {
  final List<WealthSnapshot> history;

  const WealthHistoryChart({super.key, required this.history});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget content;

    if (history.isEmpty) {
      content = SizedBox(
        height: 120,
        child: Center(
          child: Text(
            'No history yet.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
            ),
          ),
        ),
      );
    } else if (history.length == 1) {
      content = SizedBox(
        height: 120,
        child: Center(
          child: Text(
            '${fmtMonth(history.first.snapshotMonth)} — ${fmtEur(history.first.netWorthEur)}',
            style: theme.textTheme.bodyMedium,
          ),
        ),
      );
    } else {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 140,
            child: CustomPaint(
              painter: _ChartPainter(
                history: history,
                lineColor: theme.colorScheme.primary,
                gridColor:
                    theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
              ),
            ),
          ),
          const SizedBox(height: 6),
          _XLabels(history: history, theme: theme),
        ],
      );
    }

    return SectionCard(title: 'History', child: content);
  }
}

/// Shows first and last month label.
class _XLabels extends StatelessWidget {
  final List<WealthSnapshot> history;
  final ThemeData theme;

  const _XLabels({required this.history, required this.theme});

  @override
  Widget build(BuildContext context) {
    final labelStyle = theme.textTheme.labelSmall?.copyWith(
      color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(fmtMonth(history.first.snapshotMonth), style: labelStyle),
        Text(fmtMonth(history.last.snapshotMonth), style: labelStyle),
      ],
    );
  }
}

class _ChartPainter extends CustomPainter {
  final List<WealthSnapshot> history;
  final Color lineColor;
  final Color gridColor;

  const _ChartPainter({
    required this.history,
    required this.lineColor,
    required this.gridColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const hPad = 8.0;
    const vPad = 8.0;

    final values = history.map((s) => s.netWorthEur).toList();
    final minV = values.reduce(min);
    final maxV = values.reduce(max);
    // Avoid flat line when all values are equal.
    final range = (maxV - minV).abs() < 1e-6 ? 1.0 : maxV - minV;

    // Give a small margin so the topmost/bottommost points aren't clipped.
    final drawMinV = minV - range * 0.08;
    final drawRange = range * 1.16;

    Offset toOffset(int i, double v) {
      final x = history.length == 1
          ? size.width / 2
          : lerpDouble(hPad, size.width - hPad, i / (history.length - 1))!;
      final y = lerpDouble(
        size.height - vPad,
        vPad,
        (v - drawMinV) / drawRange,
      )!;
      return Offset(x, y);
    }

    // Subtle horizontal grid lines (3 evenly spaced).
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    for (int g = 1; g <= 3; g++) {
      final y = vPad + (size.height - vPad * 2) * g / 4;
      canvas.drawLine(Offset(hPad, y), Offset(size.width - hPad, y), gridPaint);
    }

    // Build line path.
    final path = Path();
    for (int i = 0; i < history.length; i++) {
      final o = toOffset(i, history[i].netWorthEur);
      i == 0 ? path.moveTo(o.dx, o.dy) : path.lineTo(o.dx, o.dy);
    }

    // Gradient fill under the line.
    final fillPath = Path()..addPath(path, Offset.zero);
    fillPath.lineTo(toOffset(history.length - 1, history.last.netWorthEur).dx,
        size.height - vPad);
    fillPath.lineTo(hPad, size.height - vPad);
    fillPath.close();

    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            lineColor.withValues(alpha: 0.18),
            lineColor.withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    // Line.
    canvas.drawPath(
      path,
      Paint()
        ..color = lineColor
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // Dots.
    for (int i = 0; i < history.length; i++) {
      final o = toOffset(i, history[i].netWorthEur);
      final isLast = i == history.length - 1;
      // White fill with colored border for the last point.
      if (isLast) {
        canvas.drawCircle(o, 5, Paint()..color = Colors.white);
        canvas.drawCircle(
          o,
          5,
          Paint()
            ..color = lineColor
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
      } else {
        canvas.drawCircle(
          o,
          3,
          Paint()..color = lineColor.withValues(alpha: 0.55),
        );
      }
    }
  }

  @override
  bool shouldRepaint(_ChartPainter old) =>
      old.history != history || old.lineColor != old.lineColor;
}
