import 'dart:math' show max;

import 'package:flutter/material.dart';

import '../../../../core/theme/rpg_colors.dart';
import 'car_formatters.dart';
import 'car_palette.dart';

const _barHeight = 10.0;
const _tickLabelWidth = 40.0;
const _paceLabelWidth = 62.0;

/// A horizontal bar of km driven with the allowance and the hard limit marked
/// on it, and optionally where an even pace would stand — so being ahead or
/// behind shows as the fill running past or stopping short of the marker.
class CarLimitGauge extends StatelessWidget {
  final double valueKm;
  final int allowanceKm;
  final int hardLimitKm;
  final Color color;

  /// No marker when null.
  final double? evenPaceKm;

  const CarLimitGauge({
    super.key,
    required this.valueKm,
    required this.allowanceKm,
    required this.hardLimitKm,
    required this.color,
    this.evenPaceKm,
  });

  @override
  Widget build(BuildContext context) {
    final barTop = evenPaceKm != null ? 22.0 : 4.0;
    final labelTop = barTop + _barHeight + 8;

    // A little room past the hard limit, so going over it stays visible.
    final scaleMax = max(hardLimitKm * 1.08, valueKm * 1.04);

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        double x(num km) => (km / scaleMax * width).clamp(0.0, width);

        final allowanceX = x(allowanceKm);
        final hardX = x(hardLimitKm);

        return SizedBox(
          height: labelTop + 12,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: 0,
                right: 0,
                top: barTop,
                height: _barHeight,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: Stack(
                    children: [
                      const Positioned.fill(
                        child: ColoredBox(color: RpgColors.progressTrack),
                      ),
                      // The stretch between the limits, and the one past both.
                      Positioned(
                        left: allowanceX,
                        width: hardX - allowanceX,
                        top: 0,
                        bottom: 0,
                        child: ColoredBox(
                          color: carOverAllowance.withValues(alpha: 0.16),
                        ),
                      ),
                      Positioned(
                        left: hardX,
                        right: 0,
                        top: 0,
                        bottom: 0,
                        child: ColoredBox(
                          color: carOverHardLimit.withValues(alpha: 0.22),
                        ),
                      ),
                      Positioned(
                        left: 0,
                        width: x(valueKm),
                        top: 0,
                        bottom: 0,
                        child: ColoredBox(color: color),
                      ),
                    ],
                  ),
                ),
              ),
              _tick(allowanceX, barTop, carOverAllowance),
              _tick(hardX, barTop, carOverHardLimit),
              _tickLabel(allowanceX, labelTop, width, allowanceKm,
                  carOverAllowance),
              _tickLabel(hardX, labelTop, width, hardLimitKm, carOverHardLimit),
              if (evenPaceKm != null) ..._evenPaceMarker(x(evenPaceKm!), barTop, width),
            ],
          ),
        );
      },
    );
  }

  Widget _tick(double x, double barTop, Color color) {
    return Positioned(
      left: x - 0.75,
      top: barTop - 4,
      width: 1.5,
      height: _barHeight + 8,
      child: ColoredBox(color: color),
    );
  }

  Widget _tickLabel(
    double x,
    double top,
    double width,
    int km,
    Color color,
  ) {
    return Positioned(
      left: (x - _tickLabelWidth / 2).clamp(0.0, width - _tickLabelWidth),
      top: top,
      width: _tickLabelWidth,
      child: Text(
        fmtKmCompact(km),
        textAlign: TextAlign.center,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
          height: 1.2,
        ),
      ),
    );
  }

  List<Widget> _evenPaceMarker(double x, double barTop, double width) {
    return [
      Positioned(
        left: (x - _paceLabelWidth / 2).clamp(0.0, width - _paceLabelWidth),
        top: 0,
        width: _paceLabelWidth,
        child: const Text(
          'EVEN PACE',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: RpgColors.textSecondary,
            fontSize: 8,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
            height: 1.2,
          ),
        ),
      ),
      Positioned(
        left: x - 1,
        top: barTop - 8,
        width: 2,
        height: _barHeight + 16,
        child: const ColoredBox(color: RpgColors.textPrimary),
      ),
    ];
  }
}
