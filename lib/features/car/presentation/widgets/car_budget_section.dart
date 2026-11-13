import 'package:flutter/material.dart';

import '../../../../core/theme/rpg_colors.dart';
import '../../domain/entities/car_stats.dart';
import 'car_formatters.dart';
import 'car_palette.dart';
import 'car_panel.dart';

/// How much can still be driven per day to finish the year under each limit.
class CarBudgetSection extends StatelessWidget {
  final CarStats stats;

  const CarBudgetSection({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final days = stats.daysLeft;

    return CarPanel(
      title: 'DAILY BUDGET',
      accent: carStatusColor(stats.status),
      trailing: '$days ${days == 1 ? 'DAY' : 'DAYS'} LEFT',
      child: CarStatRow(
        // A limit turns its colour once the current pace would break it.
        left: _cell(
          stats.allowance,
          stats.status == CarPaceStatus.onTrack ? carOnTrack : carOverAllowance,
        ),
        right: _cell(
          stats.hardLimit,
          stats.status == CarPaceStatus.overHardLimit
              ? carOverHardLimit
              : carOnTrack,
        ),
      ),
    );
  }

  Widget _cell(CarLimitOutlook outlook, Color color) {
    return CarStatCell(
      label: 'TO STAY UNDER ${fmtKm(outlook.limitKm)}',
      value: outlook.isExceeded ? '0' : fmtRate(outlook.maxKmPerDay),
      unit: 'km / day',
      color: color,
      note: outlook.isExceeded
          ? '${fmtKm(outlook.overshootKm)} km over already'
          : '${fmtKm(outlook.remainingKm)} km left',
      noteColor: outlook.isExceeded ? color : RpgColors.textMuted,
    );
  }
}
