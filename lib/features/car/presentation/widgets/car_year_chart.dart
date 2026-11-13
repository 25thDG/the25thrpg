import 'dart:math' show max, min;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/rpg_colors.dart';
import '../../domain/entities/car_stats.dart';
import 'car_formatters.dart';
import 'car_palette.dart';
import 'car_panel.dart';

const _axisWidth = 34.0;
const _chartPadLeft = 4.0;
const _chartPadRight = 14.0;

/// Cumulative km across the contract year: what was driven, where the average
/// pace takes it, and the lines it has to stay under.
class CarYearChart extends StatelessWidget {
  final CarStats stats;

  const CarYearChart({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final contract = stats.contract;
    final color = carStatusColor(stats.status);

    return CarPanel(
      title: 'YEAR ${stats.contractYear} OF ${contract.termYears}',
      trailing: 'CUMULATIVE KM',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
                _chartPadLeft, 18, _chartPadRight, 0),
            child: SizedBox(
              height: 190,
              child: LineChart(
                _buildChart(color),
                duration: const Duration(milliseconds: 800),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
                _chartPadLeft + _axisWidth, 6, _chartPadRight, 0),
            child: _MonthAxis(yearStart: stats.yearStart),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Wrap(
              spacing: 14,
              runSpacing: 8,
              children: [
                _LegendItem(color: color, label: 'Driven'),
                _LegendItem(color: color, label: 'Projection', dashed: true),
                const _LegendItem(
                  color: RpgColors.textSecondary,
                  label: 'Even pace',
                  dashed: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  LineChartData _buildChart(Color color) {
    final contract = stats.contract;
    final yearDays = stats.yearDays.toDouble();
    final allowance = contract.yearlyAllowanceKm.toDouble();
    final hardLimit = contract.yearlyHardLimitKm.toDouble();
    final projected = stats.projectedYearEndKm;

    // A runaway projection (one long trip on day two) would squash the limit
    // lines flat, so the axis stops at 2.5× the hard limit and the dashed
    // line simply leaves through the top.
    final top = [
      hardLimit,
      stats.drivenKm,
      min(projected ?? 0, hardLimit * 2.5),
    ].reduce(max);
    final interval = _gridInterval(top * 1.08);
    // Ending on a grid line keeps the top axis label off its neighbour.
    final maxY = (top * 1.08 / interval).ceil() * interval;

    final actual = [
      for (final p in stats.yearPoints) FlSpot(p.day.toDouble(), p.km),
    ];
    // Nothing to draw without a pace, or once the year has run out.
    final projectedEnd =
        projected != null && projected > stats.drivenKm && stats.daysLeft > 0
            ? projected
            : null;

    const actualBar = 1;
    const projectionBar = 2;

    return LineChartData(
      minX: 0,
      maxX: yearDays,
      minY: 0,
      maxY: maxY,
      // Top only, for a projection that outruns the axis. Clipping the sides
      // would cut the year-end dot in half.
      clipData: const FlClipData(
        top: true,
        bottom: false,
        left: false,
        right: false,
      ),
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: interval,
        getDrawingHorizontalLine: (_) => const FlLine(
          color: RpgColors.divider,
          strokeWidth: 0.8,
        ),
      ),
      borderData: FlBorderData(show: false),
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: _axisWidth,
            interval: interval,
            getTitlesWidget: (v, _) => Text(
              fmtKmCompact(v),
              style: const TextStyle(
                color: RpgColors.textMuted,
                fontSize: 9,
              ),
            ),
          ),
        ),
        // Months are drawn by _MonthAxis underneath.
        bottomTitles:
            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles:
            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles:
            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      extraLinesData: ExtraLinesData(
        horizontalLines: [
          // Named on the line itself, at the left where the year's line is
          // still low: one label under its line, one over, so the pair never
          // touch however close the two limits sit on the axis.
          _limitLine(
            allowance,
            carOverAllowance,
            '${fmtKm(allowance)} ALLOWANCE',
            Alignment.bottomLeft,
          ),
          _limitLine(
            hardLimit,
            carOverHardLimit,
            '${fmtKm(hardLimit)} HARD LIMIT',
            Alignment.topLeft,
          ),
        ],
      ),
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (_) => RpgColors.panelBgAlt,
          tooltipBorder: const BorderSide(color: RpgColors.border),
          getTooltipItems: (spots) => spots.map((s) {
            final String label;
            if (s.barIndex == actualBar) {
              final start = stats.yearStart;
              label = fmtDayShort(
                DateTime(start.year, start.month, start.day + s.x.round()),
              );
            } else if (s.barIndex == projectionBar) {
              label = 'Projected';
            } else {
              return null;
            }
            return LineTooltipItem(
              '$label  ${fmtKm(s.y)} km',
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
        // 0. Even pace — the allowance spread evenly over the year
        LineChartBarData(
          spots: [const FlSpot(0, 0), FlSpot(yearDays, allowance)],
          color: RpgColors.textSecondary.withValues(alpha: 0.7),
          barWidth: 1,
          dashArray: [3, 4],
          dotData: const FlDotData(show: false),
        ),

        // 1. Actual cumulative km, one point per snapshot
        LineChartBarData(
          spots: actual,
          color: color,
          barWidth: 2.5,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, _, _, _) {
              final isLatest = spot.x == actual.last.x;
              return FlDotCirclePainter(
                radius: isLatest ? 4 : 1.8,
                color: color,
                strokeWidth: isLatest ? 1.5 : 0,
                strokeColor: RpgColors.panelBg,
              );
            },
          ),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                color.withValues(alpha: 0.22),
                color.withValues(alpha: 0.0),
              ],
            ),
          ),
        ),

        // 2. Projection at the year-to-date average, out to the anniversary
        if (projectedEnd != null)
          LineChartBarData(
            spots: [
              FlSpot(stats.daysElapsed.toDouble(), stats.drivenKm),
              FlSpot(yearDays, projectedEnd),
            ],
            color: color.withValues(alpha: 0.7),
            barWidth: 2,
            dashArray: [8, 5],
            dotData: FlDotData(
              show: true,
              checkToShowDot: (spot, _) => spot.x == yearDays,
              getDotPainter: (_, _, _, _) => FlDotCirclePainter(
                radius: 4,
                color: color,
                strokeWidth: 1.5,
                strokeColor: RpgColors.panelBg,
              ),
            ),
          ),
      ],
    );
  }

  HorizontalLine _limitLine(
    double km,
    Color color,
    String label,
    Alignment labelAlignment,
  ) {
    return HorizontalLine(
      y: km,
      color: color.withValues(alpha: 0.85),
      strokeWidth: 1,
      label: HorizontalLineLabel(
        show: true,
        alignment: labelAlignment,
        padding: const EdgeInsets.fromLTRB(6, 3, 0, 3),
        labelResolver: (_) => label,
        style: TextStyle(
          color: color,
          fontSize: 8,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  /// The smallest round step that leaves five grid lines or fewer.
  double _gridInterval(double top) {
    const steps = [500.0, 1000.0, 2500.0, 5000.0, 10000.0, 25000.0, 50000.0];
    return steps.firstWhere((s) => top / s <= 5, orElse: () => 100000);
  }
}

/// Month labels at each quarter of the contract year, lined up with the plot.
class _MonthAxis extends StatelessWidget {
  final DateTime yearStart;

  const _MonthAxis({required this.yearStart});

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(
      color: RpgColors.textMuted,
      fontSize: 9,
      letterSpacing: 0.6,
      height: 1.2,
    );

    DateTime quarter(int q) =>
        DateTime(yearStart.year, yearStart.month + 3 * q, yearStart.day);
    String withYear(DateTime d) =>
        "${fmtMonthName(d)} '${(d.year % 100).toString().padLeft(2, '0')}";

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        return SizedBox(
          height: 12,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: 0,
                child: Text(withYear(quarter(0)).toUpperCase(), style: style),
              ),
              // Quarters are within a day of evenly spaced.
              for (var q = 1; q <= 3; q++)
                Positioned(
                  left: width * q / 4,
                  child: FractionalTranslation(
                    translation: const Offset(-0.5, 0),
                    child: Text(
                      fmtMonthName(quarter(q)).toUpperCase(),
                      style: style,
                    ),
                  ),
                ),
              Positioned(
                right: 0,
                child: Text(withYear(quarter(4)).toUpperCase(), style: style),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final bool dashed;

  const _LegendItem({
    required this.color,
    required this.label,
    this.dashed = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (dashed)
          for (var i = 0; i < 3; i++)
            Container(
              width: 3,
              height: 2,
              margin: EdgeInsets.only(right: i == 2 ? 0 : 2),
              color: color,
            )
        else
          Container(width: 13, height: 2, color: color),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            color: RpgColors.textSecondary,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}
