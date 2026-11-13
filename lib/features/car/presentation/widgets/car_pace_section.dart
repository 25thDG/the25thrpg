import 'package:flutter/material.dart';

import '../../../../core/theme/rpg_colors.dart';
import '../../domain/entities/car_stats.dart';
import 'car_formatters.dart';
import 'car_palette.dart';
import 'car_panel.dart';

/// Current pace, and where it leads if it holds.
class CarPaceSection extends StatelessWidget {
  final CarStats stats;

  const CarPaceSection({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final avg = stats.avgKmPerDay;
    final last30 = stats.last30KmPerDay;

    return CarPanel(
      title: 'PACE & PROJECTION',
      child: Column(
        children: [
          CarStatRow(
            left: CarStatCell(
              label: 'AVERAGE THIS YEAR',
              value: avg == null ? '—' : fmtRate(avg),
              unit: avg == null ? null : 'km / day',
              note: '${fmtKm(stats.drivenKm)} km in ${stats.daysElapsed} days',
            ),
            right: CarStatCell(
              label: 'LAST 30 DAYS',
              value: last30 == null ? '—' : fmtRate(last30),
              unit: last30 == null ? null : 'km / day',
              note: _trendNote(avg, last30),
            ),
          ),
          const Divider(height: 1, color: RpgColors.divider),
          SizedBox(width: double.infinity, child: _projectionCell()),
          const Divider(height: 1, color: RpgColors.divider),
          CarStatRow(
            left: _reachCell(stats.allowance, carOverAllowance),
            right: _reachCell(stats.hardLimit, carOverHardLimit),
          ),
        ],
      ),
    );
  }

  String? _trendNote(double? avg, double? last30) {
    if (avg == null || last30 == null) return null;
    if ((last30 - avg).abs() < 0.05) return 'same as the average';
    return last30 < avg ? 'slower than the average' : 'faster than the average';
  }

  Widget _projectionCell() {
    final projected = stats.projectedYearEndKm;
    final label = 'PROJECTED BY ${fmtDay(stats.yearEnd).toUpperCase()}';

    if (projected == null) {
      return CarStatCell(
        label: label,
        value: '—',
        note: 'Needs at least a day of driving.',
      );
    }

    final over = projected - stats.contract.yearlyAllowanceKm;
    return CarStatCell(
      label: label,
      value: fmtKm(projected),
      unit: 'km',
      color: carStatusColor(stats.status),
      note: over > 0
          ? '${fmtKm(over)} km over the allowance if the average holds'
          : '${fmtKm(-over)} km under the allowance if the average holds',
    );
  }

  Widget _reachCell(CarLimitOutlook outlook, Color overColor) {
    final label = 'REACH ${fmtKm(outlook.limitKm)}';

    if (outlook.isExceeded) {
      return CarStatCell(
        label: label,
        value: 'Exceeded',
        color: overColor,
        note: '${fmtKm(outlook.overshootKm)} km over',
        noteColor: overColor,
      );
    }

    if (stats.avgKmPerDay == null) {
      return CarStatCell(label: label, value: '—');
    }

    final reachedOn = outlook.reachedOn;
    if (reachedOn == null) {
      return CarStatCell(
        label: label,
        value: 'Not this year',
        color: carOnTrack,
        note: 'at the average pace',
      );
    }

    return CarStatCell(
      label: label,
      value: fmtDay(reachedOn),
      color: overColor,
      note: '${outlook.reachedInDays} days from ${fmtDayShort(stats.asOf)}',
    );
  }
}
