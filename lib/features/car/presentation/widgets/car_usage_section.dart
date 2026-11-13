import 'package:flutter/material.dart';

import '../../../../core/theme/rpg_colors.dart';
import '../../domain/entities/car_stats.dart';
import 'car_formatters.dart';
import 'car_limit_gauge.dart';
import 'car_palette.dart';

/// The headline: km driven this contract year against both limits.
class CarUsageSection extends StatelessWidget {
  final CarStats stats;

  const CarUsageSection({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final contract = stats.contract;
    final color = carStatusColor(stats.status);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: RpgColors.border),
        gradient: RadialGradient(
          center: const Alignment(1.0, -1.0),
          radius: 1.4,
          colors: [
            Color.alphaBlend(color.withValues(alpha: 0.18), RpgColors.panelBg),
            const Color(0xFF101015),
            RpgColors.panelBg,
          ],
          stops: const [0.0, 0.55, 1.0],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
            child: Row(
              children: [
                Container(width: 6, height: 6, color: color),
                const SizedBox(width: 8),
                Text(
                  'CONTRACT YEAR ${stats.contractYear}',
                  style: const TextStyle(
                    color: RpgColors.textSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2.4,
                  ),
                ),
                const Spacer(),
                Text(
                  stats.hasSnapshots
                      ? 'AS OF ${fmtDay(stats.asOf).toUpperCase()}'
                      : 'NO SNAPSHOTS YET',
                  style: const TextStyle(
                    color: RpgColors.textMuted,
                    fontSize: 9,
                    letterSpacing: 1.6,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: stats.drivenKm),
                      duration: const Duration(milliseconds: 1400),
                      curve: Curves.easeOutCubic,
                      builder: (_, v, _) => Text(
                        fmtKm(v),
                        style: TextStyle(
                          color: RpgColors.textPrimary,
                          fontSize: 44,
                          fontWeight: FontWeight.w800,
                          height: 1.0,
                          letterSpacing: -2.0,
                          shadows: [
                            Shadow(
                              color: color.withValues(alpha: 0.4),
                              blurRadius: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'km',
                      style: TextStyle(
                        color: RpgColors.textSecondary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'driven of ${fmtKm(contract.yearlyAllowanceKm)} km allowed '
                  '· ${fmtKm(contract.yearlyHardLimitKm)} km hard limit',
                  style: const TextStyle(
                    color: RpgColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 14),
                _StatusChip(stats: stats, color: color),
                const SizedBox(height: 22),
                CarLimitGauge(
                  valueKm: stats.drivenKm,
                  allowanceKm: contract.yearlyAllowanceKm,
                  hardLimitKm: contract.yearlyHardLimitKm,
                  evenPaceKm: stats.evenPaceKm,
                  color: color,
                ),
                const SizedBox(height: 16),
                Text(
                  _paceLine(),
                  style: TextStyle(
                    color: stats.hasSnapshots ? color : RpgColors.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _paceLine() {
    if (!stats.hasSnapshots) return "Log today's odometer below to start.";

    final ahead = stats.aheadOfEvenPaceKm;
    final even = fmtKm(stats.evenPaceKm);
    return ahead > 0
        ? '${fmtKm(ahead)} km over an even pace ($even km by now)'
        : '${fmtKm(-ahead)} km under an even pace ($even km by now)';
  }
}

class _StatusChip extends StatelessWidget {
  final CarStats stats;
  final Color color;

  const _StatusChip({required this.stats, required this.color});

  @override
  Widget build(BuildContext context) {
    final onTrack = stats.status == CarPaceStatus.onTrack;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            onTrack ? Icons.check : Icons.warning_amber_rounded,
            color: color,
            size: 12,
          ),
          const SizedBox(width: 5),
          Text(
            _label(),
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  String _label() {
    final allowance = fmtKm(stats.contract.yearlyAllowanceKm);
    final hard = fmtKm(stats.contract.yearlyHardLimitKm);

    return switch (stats.status) {
      CarPaceStatus.onTrack => 'On track to stay under $allowance km',
      CarPaceStatus.overAllowance => stats.allowance.isExceeded
          ? 'Over the $allowance km allowance'
          : 'On pace to exceed $allowance km',
      CarPaceStatus.overHardLimit => stats.hardLimit.isExceeded
          ? 'Over the $hard km hard limit'
          : 'On pace to exceed the $hard km hard limit',
    };
  }
}
