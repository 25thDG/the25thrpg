import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/rpg_colors.dart';
import '../../domain/entities/budget_summary.dart';

const _budget = 300.0;
const _safe = Color(0xFF26A69A);
const _warn = Color(0xFFFF7043);
const _over = Color(0xFFEF5350);

class BudgetBurnChart extends StatelessWidget {
  final BudgetSummary summary;
  final DateTime month;

  const BudgetBurnChart({
    super.key,
    required this.summary,
    required this.month,
  });

  @override
  Widget build(BuildContext context) {
    final data = _buildData();
    if (data == null) return const SizedBox.shrink();

    final projectedEur = data.projectedEnd;
    final isProjectedOver = projectedEur > _budget;
    final isCurrentMonth = data.isCurrentMonth;

    final accentColor = projectedEur >= _budget
        ? _over
        : projectedEur >= _budget * 0.8
            ? _warn
            : _safe;

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
          // ── Header ──────────────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: RpgColors.divider)),
            ),
            child: Row(
              children: [
                const Text(
                  'BURN RATE',
                  style: TextStyle(
                    color: RpgColors.textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 2.4,
                  ),
                ),
                const Spacer(),
                if (isCurrentMonth) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(3),
                      border: Border.all(
                          color: accentColor.withValues(alpha: 0.4)),
                    ),
                    child: Text(
                      isProjectedOver
                          ? 'OVERSPEND  €${(projectedEur - _budget).toStringAsFixed(0)}'
                          : '€${(_budget - projectedEur).toStringAsFixed(0)} TO SPARE',
                      style: TextStyle(
                        color: accentColor,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // ── Projection summary row ────────────────────────────────────
          if (isCurrentMonth)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: Row(
                children: [
                  _StatChip(
                    label: 'DAILY RATE',
                    value: '€${data.dailyRate.toStringAsFixed(2)}',
                    color: accentColor,
                  ),
                  const SizedBox(width: 12),
                  _StatChip(
                    label: 'PROJECTED EOMonth',
                    value: '€${projectedEur.toStringAsFixed(2)}',
                    color: accentColor,
                  ),
                  const SizedBox(width: 12),
                  _StatChip(
                    label: 'DAYS LEFT',
                    value: '${data.daysRemaining}d',
                    color: RpgColors.textSecondary,
                  ),
                ],
              ),
            ),

          // ── Chart ─────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 16, 16, 12),
            child: SizedBox(
              height: 180,
              child: LineChart(
                _buildChart(data, accentColor),
                duration: const Duration(milliseconds: 800),
              ),
            ),
          ),
        ],
      ),
    );
  }

  LineChartData _buildChart(_ChartData data, Color accentColor) {
    final daysInMonth = data.daysInMonth.toDouble();

    return LineChartData(
      minX: 0,
      maxX: daysInMonth,
      minY: 0,
      maxY: (data.chartMax * 1.1).ceilToDouble(),
      clipData: const FlClipData.all(),
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: 50,
        getDrawingHorizontalLine: (_) => FlLine(
          color: RpgColors.divider,
          strokeWidth: 0.8,
          dashArray: [4, 4],
        ),
      ),
      borderData: FlBorderData(show: false),
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 38,
            interval: 100,
            getTitlesWidget: (v, _) => Text(
              '€${v.toInt()}',
              style: const TextStyle(
                color: RpgColors.textMuted,
                fontSize: 9,
              ),
            ),
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 22,
            interval: (daysInMonth / 4).roundToDouble(),
            getTitlesWidget: (v, _) {
              if (v == 0) return const SizedBox.shrink();
              return Text(
                '${v.toInt()}',
                style: const TextStyle(
                  color: RpgColors.textMuted,
                  fontSize: 9,
                ),
              );
            },
          ),
        ),
        rightTitles:
            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles:
            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (_) => RpgColors.panelBgAlt,
          tooltipBorder: const BorderSide(color: RpgColors.border),
          getTooltipItems: (spots) => spots.map((s) {
            if (s.barIndex == 2) return null; // hide cap line tooltip
            final label = s.barIndex == 1 ? 'Projected' : 'Spent';
            return LineTooltipItem(
              '$label  €${s.y.toStringAsFixed(2)}',
              TextStyle(
                color: s.barIndex == 1
                    ? accentColor.withValues(alpha: 0.6)
                    : accentColor,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            );
          }).toList(),
        ),
      ),
      lineBarsData: [
        // 1. Actual cumulative spend
        LineChartBarData(
          spots: data.actualSpots,
          isCurved: true,
          curveSmoothness: 0.3,
          color: accentColor,
          barWidth: 2.5,
          dotData: FlDotData(
            show: true,
            checkToShowDot: (spot, _) =>
                spot.x == data.actualSpots.last.x,
            getDotPainter: (_, _, _, _) => FlDotCirclePainter(
              radius: 4,
              color: accentColor,
              strokeWidth: 1.5,
              strokeColor: RpgColors.panelBg,
            ),
          ),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                accentColor.withValues(alpha: 0.18),
                accentColor.withValues(alpha: 0.0),
              ],
            ),
          ),
        ),

        // 2. Projection line (dashed, lighter)
        if (data.projectionSpots.isNotEmpty)
          LineChartBarData(
            spots: data.projectionSpots,
            isCurved: false,
            color: accentColor.withValues(alpha: 0.4),
            barWidth: 1.5,
            dashArray: [6, 4],
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(show: false),
          ),

        // 3. Budget cap line (dashed red)
        LineChartBarData(
          spots: [FlSpot(0, _budget), FlSpot(daysInMonth, _budget)],
          isCurved: false,
          color: _over.withValues(alpha: 0.5),
          barWidth: 1,
          dashArray: [4, 4],
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(show: false),
        ),
      ],
    );
  }

  _ChartData? _buildData() {
    if (summary.transactions.isEmpty) return null;

    final now = DateTime.now();
    final isCurrentMonth =
        month.year == now.year && month.month == now.month;
    final daysInMonth =
        DateUtils.getDaysInMonth(month.year, month.month);
    final daysElapsed = isCurrentMonth ? now.day : daysInMonth;

    // Group spend by day-of-month
    final Map<int, double> dailyMap = {};
    for (final tx in summary.transactions) {
      final day = tx.spentAt.day;
      dailyMap[day] = (dailyMap[day] ?? 0) + tx.amountEur;
    }

    // Build cumulative actual spots
    final actualSpots = <FlSpot>[const FlSpot(0, 0)];
    double cumulative = 0;
    for (int day = 1; day <= daysElapsed; day++) {
      cumulative += dailyMap[day] ?? 0;
      actualSpots.add(FlSpot(day.toDouble(), cumulative));
    }

    // Projection
    final dailyRate = daysElapsed > 0 ? cumulative / daysElapsed : 0.0;
    final projectedEnd = dailyRate * daysInMonth;
    final daysRemaining = daysInMonth - daysElapsed;

    final projectionSpots = <FlSpot>[];
    if (isCurrentMonth && daysElapsed < daysInMonth && cumulative > 0) {
      projectionSpots.add(FlSpot(daysElapsed.toDouble(), cumulative));
      projectionSpots.add(FlSpot(daysInMonth.toDouble(), projectedEnd));
    }

    final chartMax = [cumulative, projectedEnd, _budget].reduce(
        (a, b) => a > b ? a : b);

    return _ChartData(
      actualSpots: actualSpots,
      projectionSpots: projectionSpots,
      projectedEnd: projectedEnd,
      dailyRate: dailyRate,
      daysInMonth: daysInMonth,
      daysElapsed: daysElapsed,
      daysRemaining: daysRemaining,
      isCurrentMonth: isCurrentMonth,
      chartMax: chartMax,
    );
  }
}

class _ChartData {
  final List<FlSpot> actualSpots;
  final List<FlSpot> projectionSpots;
  final double projectedEnd;
  final double dailyRate;
  final int daysInMonth;
  final int daysElapsed;
  final int daysRemaining;
  final bool isCurrentMonth;
  final double chartMax;

  const _ChartData({
    required this.actualSpots,
    required this.projectionSpots,
    required this.projectedEnd,
    required this.dailyRate,
    required this.daysInMonth,
    required this.daysElapsed,
    required this.daysRemaining,
    required this.isCurrentMonth,
    required this.chartMax,
  });
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: RpgColors.textMuted,
            fontSize: 7,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
      ],
    );
  }
}
