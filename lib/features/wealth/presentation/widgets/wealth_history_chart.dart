import 'dart:math' show min, max;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../../domain/entities/wealth_snapshot.dart';
import 'section_card.dart';
import 'wealth_formatters.dart';

class WealthHistoryChart extends StatefulWidget {
  final List<WealthSnapshot> history;

  const WealthHistoryChart({super.key, required this.history});

  @override
  State<WealthHistoryChart> createState() => _WealthHistoryChartState();
}

class _WealthHistoryChartState extends State<WealthHistoryChart> {
  int? _touchedIndex;
  bool _showList = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final history = widget.history;

    Widget chartContent;

    if (history.isEmpty) {
      chartContent = SizedBox(
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
      chartContent = SizedBox(
        height: 120,
        child: Center(
          child: Text(
            '${fmtMonth(history.first.snapshotMonth)} — ${fmtEur(history.first.netWorthEur)}',
            style: theme.textTheme.bodyMedium,
          ),
        ),
      );
    } else {
      chartContent = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LayoutBuilder(
            builder: (_, constraints) => GestureDetector(
              onTapDown: (d) =>
                  _onTouch(d.localPosition.dx, constraints.maxWidth),
              onPanUpdate: (d) =>
                  _onTouch(d.localPosition.dx, constraints.maxWidth),
              onTapUp: (_) => setState(() => _touchedIndex = null),
              onPanEnd: (_) => setState(() => _touchedIndex = null),
              child: SizedBox(
                height: 160,
                child: CustomPaint(
                  painter: _ChartPainter(
                    history: history,
                    touchedIndex: _touchedIndex,
                    lineColor: theme.colorScheme.primary,
                    gridColor: theme.colorScheme.outlineVariant
                        .withValues(alpha: 0.3),
                    tooltipBg: theme.colorScheme.surfaceContainerHighest,
                    tooltipTextColor: theme.colorScheme.onSurface,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          _XLabels(history: history, theme: theme),
          const SizedBox(height: 10),
          InkWell(
            onTap: () => setState(() => _showList = !_showList),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _showList ? 'Hide entries' : 'Show all entries',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  Icon(
                    _showList ? Icons.expand_less : Icons.expand_more,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                ],
              ),
            ),
          ),
          if (_showList) ...[
            const SizedBox(height: 8),
            // Header row
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      'MONTH',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.4),
                        fontSize: 9,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 4,
                    child: Text(
                      'NET WORTH',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.4),
                        fontSize: 9,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      'CHANGE',
                      textAlign: TextAlign.right,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.4),
                        fontSize: 9,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            ...List.generate(history.length, (i) {
              // Newest first
              final snap = history[history.length - 1 - i];
              final prevIdx = history.length - 2 - i;
              final delta = prevIdx >= 0
                  ? snap.netWorthEur - history[prevIdx].netWorthEur
                  : null;
              return _HistoryRow(
                  snapshot: snap, delta: delta, theme: theme);
            }),
          ],
        ],
      );
    }

    return SectionCard(title: 'History', child: chartContent);
  }

  void _onTouch(double dx, double width) {
    const hPad = 8.0;
    final step =
        (width - hPad * 2) / (widget.history.length - 1);
    final idx =
        ((dx - hPad) / step).round().clamp(0, widget.history.length - 1);
    setState(() => _touchedIndex = idx);
  }
}

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

class _HistoryRow extends StatelessWidget {
  final WealthSnapshot snapshot;
  final double? delta;
  final ThemeData theme;

  const _HistoryRow(
      {required this.snapshot, required this.delta, required this.theme});

  @override
  Widget build(BuildContext context) {
    final isPos = (delta ?? 0) >= 0;
    final deltaColor = delta == null
        ? Colors.transparent
        : isPos
            ? Colors.green
            : theme.colorScheme.error;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              fmtMonth(snapshot.snapshotMonth),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ),
          Expanded(
            flex: 4,
            child: Text(
              fmtEur(snapshot.netWorthEur),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: delta == null
                ? const SizedBox()
                : Text(
                    '${isPos ? '+' : ''}${fmtEur(delta!)}',
                    textAlign: TextAlign.right,
                    style: theme.textTheme.labelSmall
                        ?.copyWith(color: deltaColor),
                  ),
          ),
        ],
      ),
    );
  }
}

class _ChartPainter extends CustomPainter {
  final List<WealthSnapshot> history;
  final int? touchedIndex;
  final Color lineColor;
  final Color gridColor;
  final Color tooltipBg;
  final Color tooltipTextColor;

  const _ChartPainter({
    required this.history,
    required this.touchedIndex,
    required this.lineColor,
    required this.gridColor,
    required this.tooltipBg,
    required this.tooltipTextColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const hPad = 8.0;
    const vPad = 8.0;

    final values = history.map((s) => s.netWorthEur).toList();
    final minV = values.reduce(min);
    final maxV = values.reduce(max);
    final range = (maxV - minV).abs() < 1e-6 ? 1.0 : maxV - minV;

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

    // Grid lines
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    for (int g = 1; g <= 3; g++) {
      final y = vPad + (size.height - vPad * 2) * g / 4;
      canvas.drawLine(
          Offset(hPad, y), Offset(size.width - hPad, y), gridPaint);
    }

    // Build line path
    final path = Path();
    for (int i = 0; i < history.length; i++) {
      final o = toOffset(i, history[i].netWorthEur);
      i == 0 ? path.moveTo(o.dx, o.dy) : path.lineTo(o.dx, o.dy);
    }

    // Gradient fill
    final fillPath = Path()..addPath(path, Offset.zero);
    fillPath.lineTo(
        toOffset(history.length - 1, history.last.netWorthEur).dx,
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

    // Line
    canvas.drawPath(
      path,
      Paint()
        ..color = lineColor
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // Dots
    for (int i = 0; i < history.length; i++) {
      final o = toOffset(i, history[i].netWorthEur);
      final isLast = i == history.length - 1;
      final isTouched = i == touchedIndex;

      if (isTouched) {
        canvas.drawCircle(o, 6, Paint()..color = lineColor);
        canvas.drawCircle(
          o,
          6,
          Paint()
            ..color = Colors.white.withValues(alpha: 0.25)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
      } else if (isLast) {
        canvas.drawCircle(o, 5, Paint()..color = const Color(0xFF131318));
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
            o, 3, Paint()..color = lineColor.withValues(alpha: 0.55));
      }
    }

    // Tooltip on touch
    if (touchedIndex != null) {
      final idx = touchedIndex!;
      final o = toOffset(idx, history[idx].netWorthEur);

      // Vertical indicator line
      canvas.drawLine(
        Offset(o.dx, vPad),
        Offset(o.dx, size.height - vPad),
        Paint()
          ..color = lineColor.withValues(alpha: 0.35)
          ..strokeWidth = 1,
      );

      // Tooltip
      const tPad = 6.0;
      final snap = history[idx];
      final label =
          '${fmtMonth(snap.snapshotMonth)}\n${fmtEur(snap.netWorthEur)}';

      final tp = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(
            color: tooltipTextColor,
            fontSize: 10,
            fontWeight: FontWeight.w600,
            height: 1.5,
          ),
        ),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      )..layout();

      final tooltipW = tp.width + tPad * 2;
      final tooltipH = tp.height + tPad * 2;

      // Clamp horizontally so it never goes off-canvas
      double tx = o.dx - tooltipW / 2;
      tx = tx.clamp(0, size.width - tooltipW);

      // Position above the dot, fall back below if too close to top
      double ty = o.dy - tooltipH - 10;
      if (ty < vPad) ty = o.dy + 10;

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(tx, ty, tooltipW, tooltipH),
          const Radius.circular(6),
        ),
        Paint()..color = tooltipBg,
      );

      tp.paint(canvas, Offset(tx + tPad, ty + tPad));
    }
  }

  @override
  bool shouldRepaint(_ChartPainter old) =>
      old.history != history ||
      old.touchedIndex != touchedIndex ||
      old.lineColor != lineColor;
}
