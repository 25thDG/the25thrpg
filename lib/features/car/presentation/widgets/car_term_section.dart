import 'package:flutter/material.dart';

import '../../../../core/theme/rpg_colors.dart';
import '../../domain/entities/car_stats.dart';
import 'car_formatters.dart';
import 'car_limit_gauge.dart';
import 'car_palette.dart';
import 'car_panel.dart';

/// Total km since handover against the limits for the whole contract.
class CarTermSection extends StatelessWidget {
  final CarStats stats;

  const CarTermSection({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final contract = stats.contract;

    // A plain tally: it only takes a warning colour once a term limit is
    // actually crossed. The pace verdict belongs to the contract year above.
    final color = stats.termKm > contract.termHardLimitKm
        ? carOverHardLimit
        : stats.termKm > contract.termAllowanceKm
            ? carOverAllowance
            : RpgColors.textSecondary;

    return CarPanel(
      title: 'WHOLE TERM',
      trailing: 'YEAR ${stats.contractYear} OF ${contract.termYears}',
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  fmtKm(stats.termKm),
                  style: const TextStyle(
                    color: RpgColors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.6,
                    height: 1.0,
                  ),
                ),
                const SizedBox(width: 5),
                const Text(
                  'km since handover',
                  style: TextStyle(
                    color: RpgColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${fmtDay(contract.startDate)} – '
              '${fmtDay(contract.yearStart(contract.termYears + 1))}',
              style: const TextStyle(
                color: RpgColors.textMuted,
                fontSize: 10.5,
              ),
            ),
            const SizedBox(height: 14),
            CarLimitGauge(
              valueKm: stats.termKm.toDouble(),
              allowanceKm: contract.termAllowanceKm,
              hardLimitKm: contract.termHardLimitKm,
              color: color,
            ),
          ],
        ),
      ),
    );
  }
}
