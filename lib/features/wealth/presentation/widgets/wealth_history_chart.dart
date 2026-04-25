import 'dart:math' show min, max;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../../../../core/theme/rpg_colors.dart';
import '../../domain/entities/wealth_snapshot.dart';
import 'wealth_formatters.dart';

const _colorGold = Color(0xFF10B981);

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
    final history = widget.history;

    Widget chartContent;

    if (history.isEmpty) {
      chartContent = const SizedBox(
        height: 120,
        child: Center(
          child: Text(
            'No history yet.',
            style: TextStyle(color: RpgColors.textMuted, fontSize: 13),
          ),
        ),
      );
    } else if (history.length == 1) {
      chartContent = SizedBox(
        height: 120,
        child: Center(
          child: Text(
            '${fmtMonth(history.first.snapshotMonth)} — ${fmtEur(history.first.netWorthEur)}',
            style: const TextStyle(
              color: RpgColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
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
                    lineColor: _colorGold,
                    gridColor: RpgColors.divider,
                    tooltipBg: RpgColors.panelBgAlt,
                    tooltipTextColor: RpgColors.textPrimary,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          _XLabels(history: history),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () => setState(() => _showList = !_showList),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _showList ? 'Hide entries' : 'Show all entries',
                    style: const TextStyle(
                      color: _colorGold,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Icon(
                    _showList ? Icons.expand_less : Icons.expand_more,
                    size: 16,
                    color: _colorGold,
                  ),
                ],
              ),
            ),
          ),
          if (_showList) ...[
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      'MONTH',
                      style: TextStyle(
                        color: RpgColors.textMuted,
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 4,
                    child: Text(
                      'NET WORTH',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: RpgColors.textMuted,
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      'CHANGE',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        color: RpgColors.textMuted,
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: RpgColors.divider),
            ...List.generate(history.length, (i) {
              final snap = history[history.length - 1 - i];
              final prevIdx = history.length - 2 - i;
              final delta = prevIdx >= 0
                  ? snap.netWorthEur - history[prevIdx].netWorthEur
                  : null;
              return _HistoryRow(snapshot: snap, delta: delta);
            }),
          ],
        ],
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: RpgColors.panelBg,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: RpgColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(
              border:
                  Border(bottom: BorderSide(color: RpgColors.divider)),
            ),
            child: const Text(
              'HISTORY',
              style: TextStyle(
                color: RpgColors.textMuted,
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 2.4,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 16, 8, 12),
            child: chartContent,
          ),
        ],
      ),
    );
  }

  void _onTouch(double dx, double width) {
    const hPad = 8.0;
    final step = (width - hPad * 2) / (widget.history.length - 1);
    final idx =
        ((dx - hPad) / step).round().clamp(0, widget.history.length - 1);
    setState(() => _touchedIndex = idx);
  }
}

class _XLabels extends StatelessWidget {
  final List<WealthSnapshot> history;
  const _XLabels({required this.history});

  @override
  Widget build(BuildContext context) {
    const style =
        TextStyle(color: RpgColors.textMuted, fontSize: 9, letterSpacing: 0.3);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(fmtMonth(history.first.snapshotMonth), style: style),
        Text(fmtMonth(history.last.snapshotMonth), style: style),
      ],
    );
  }
}

class _HistoryRow extends StatelessWidget {
  final WealthSnapshot snapshot;
  final double? delta;

  const _HistoryRow({required this.snapshot, required this.delta});

  @override
  Widget build(BuildContext context) {
    final isPos = (delta ?? 0) >= 0;
    final deltaColor = delta == null
        ? Colors.transparent
        : isPos
            ? const Color(0xFF66BB6A)
            : const Color(0xFFEF5350);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              fmtMonth(snapshot.snapshotMonth),
              style: const TextStyle(
                color: RpgColors.textSecondary,
                fontSize: 11,
              ),
            ),
          ),
          Expanded(
            flex: 4,
            child: Text(
              fmtEur(snapshot.netWorthEur),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: RpgColors.textPrimary,
                fontSize: 12,
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
                    style: TextStyle(
                      color: deltaColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
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
        canvas.drawCircle(
            o, 5, Paint()..color = RpgColors.panelBg);
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

      canvas.drawLine(
        Offset(o.dx, vPad),
        Offset(o.dx, size.height - vPad),
        Paint()
          ..color = lineColor.withValues(alpha: 0.35)
          ..strokeWidth = 1,
      );

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

      double tx = o.dx - tooltipW / 2;
      tx = tx.clamp(0, size.width - tooltipW);
      double ty = o.dy - tooltipH - 10;
      if (ty < vPad) ty = o.dy + 10;

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(tx, ty, tooltipW, tooltipH),
          const Radius.circular(4),
        ),
        Paint()..color = tooltipBg,
      );

      tp.paint(canvas, Offset(tx + tPad, ty + tPad));
    }
  }

  @override
  bool shouldRepaint(_ChartPainter old) =>
      old.history != history || old.touchedIndex != touchedIndex;
}
