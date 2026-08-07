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
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: RpgColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Row(
              children: [
                Container(width: 6, height: 6, color: accentColor),
                const SizedBox(width: 8),
                const Text(
                  'BURN RATE',
                  style: TextStyle(
                    color: RpgColors.textSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2.4,
                  ),
                ),
                const Spacer(),
                if (isCurrentMonth)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: accentColor.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isProjectedOver
                              ? Icons.arrow_upward
                              : Icons.arrow_downward,
                          size: 10,
                          color: accentColor,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          isProjectedOver
                              ? '+€${(projectedEur - _budget).toStringAsFixed(0)} over'
                              : '€${(_budget - projectedEur).toStringAsFixed(0)} to spare',
                          style: TextStyle(
                            color: accentColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // Stats row
          if (isCurrentMonth) ...[
            Container(height: 1, color: RpgColors.divider),
            IntrinsicHeight(
              child: Row(
                children: [
                  Expanded(
                    child: _StatCell(
                      label: 'SPENT SO FAR',
                      value:
                          '€${data.actualSpots.last.y.toStringAsFixed(0)}',
                      color: accentColor,
                    ),
                  ),
                  Container(width: 1, color: RpgColors.divider),
                  Expanded(
                    child: _StatCell(
                      label: 'PROJECTED END',
                      value: '€${projectedEur.toStringAsFixed(0)}',
                      color: isProjectedOver ? _over : accentColor,
                    ),
                  ),
                  Container(width: 1, color: RpgColors.divider),
                  Expanded(
                    child: _StatCell(
                      label: 'DAILY RATE',
                      value:
                          '€${data.dailyRate.toStringAsFixed(2)}',
                      color: RpgColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ],

          Container(height: 1, color: RpgColors.divider),

          // Chart
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 16, 12, 12),
            child: SizedBox(
              height: 170,
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
    final projColor =
        data.projectedEnd >= _budget ? _over : accentColor;

    return LineChartData(
      minX: 0,
      maxX: daysInMonth,
      minY: 0,
      maxY: (data.chartMax * 1.15).ceilToDouble(),
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
            reservedSize: 40,
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
            if (s.barIndex == 2) return null;
            final label = s.barIndex == 1 ? 'Projected' : 'Spent';
            final color =
                s.barIndex == 1 ? projColor : accentColor;
            return LineTooltipItem(
              '$label  €${s.y.toStringAsFixed(2)}',
              TextStyle(
                color: color,
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
                accentColor.withValues(alpha: 0.20),
                accentColor.withValues(alpha: 0.0),
              ],
            ),
          ),
        ),

        // 2. Projection line — prominent dashed, with endpoint dot
        if (data.projectionSpots.isNotEmpty)
          LineChartBarData(
            spots: data.projectionSpots,
            isCurved: false,
            color: projColor.withValues(alpha: 0.7),
            barWidth: 2.0,
            dashArray: [8, 5],
            dotData: FlDotData(
              show: true,
              checkToShowDot: (spot, _) =>
                  spot.x == data.projectionSpots.last.x,
              getDotPainter: (_, _, _, _) => FlDotCirclePainter(
                radius: 5,
                color: projColor,
                strokeWidth: 2,
                strokeColor: RpgColors.panelBg,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  projColor.withValues(alpha: 0.08),
                  projColor.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),

        // 3. Budget cap line
        LineChartBarData(
          spots: [FlSpot(0, _budget), FlSpot(daysInMonth, _budget)],
          isCurved: false,
          color: _over.withValues(alpha: 0.45),
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

    final Map<int, double> dailyMap = {};
    for (final tx in summary.transactions) {
      final day = tx.spentAt.day;
      dailyMap[day] = (dailyMap[day] ?? 0) + tx.amountEur;
    }

    final actualSpots = <FlSpot>[const FlSpot(0, 0)];
    double cumulative = 0;
    for (int day = 1; day <= daysElapsed; day++) {
      cumulative += dailyMap[day] ?? 0;
      actualSpots.add(FlSpot(day.toDouble(), cumulative));
    }

    final dailyRate = daysElapsed > 0 ? cumulative / daysElapsed : 0.0;
    final projectedEnd = dailyRate * daysInMonth;
    final daysRemaining = daysInMonth - daysElapsed;

    final projectionSpots = <FlSpot>[];
    if (isCurrentMonth && daysElapsed < daysInMonth && cumulative > 0) {
      projectionSpots.add(FlSpot(daysElapsed.toDouble(), cumulative));
      projectionSpots.add(FlSpot(daysInMonth.toDouble(), projectedEnd));
    }

    final chartMax = [cumulative, projectedEnd, _budget]
        .reduce((a, b) => a > b ? a : b);

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

class _StatCell extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatCell({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: RpgColors.textMuted,
              fontSize: 8,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}
