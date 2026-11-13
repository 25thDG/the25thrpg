import 'package:flutter/material.dart';

import '../../../../core/theme/rpg_colors.dart';

/// The bordered card every Car section sits in: a title row, then [child].
class CarPanel extends StatelessWidget {
  final String title;

  /// Small right-aligned note in the title row.
  final String? trailing;

  /// Tints the square in front of the title.
  final Color? accent;
  final Widget child;

  const CarPanel({
    super.key,
    required this.title,
    required this.child,
    this.trailing,
    this.accent,
  });

  @override
  Widget build(BuildContext context) {
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
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: RpgColors.divider)),
            ),
            child: Row(
              children: [
                if (accent != null) ...[
                  Container(width: 6, height: 6, color: accent),
                  const SizedBox(width: 8),
                ],
                Text(
                  title,
                  style: const TextStyle(
                    color: RpgColors.textSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2.4,
                  ),
                ),
                const Spacer(),
                if (trailing != null)
                  Text(
                    trailing!,
                    style: const TextStyle(
                      color: RpgColors.textMuted,
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.6,
                    ),
                  ),
              ],
            ),
          ),
          child,
        ],
      ),
    );
  }
}

/// A labelled figure inside a [CarPanel]: small caps label, bold value,
/// optional muted line underneath.
class CarStatCell extends StatelessWidget {
  final String label;
  final String value;

  /// Rendered small after [value], e.g. "km/day".
  final String? unit;
  final String? note;
  final Color color;
  final Color? noteColor;

  const CarStatCell({
    super.key,
    required this.label,
    required this.value,
    this.unit,
    this.note,
    this.color = RpgColors.textPrimary,
    this.noteColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
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
          const SizedBox(height: 6),
          // Scales down rather than overflowing on a narrow phone.
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    color: color,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    height: 1.0,
                  ),
                ),
                if (unit != null) ...[
                  const SizedBox(width: 4),
                  Text(
                    unit!,
                    style: const TextStyle(
                      color: RpgColors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (note != null) ...[
            const SizedBox(height: 5),
            Text(
              note!,
              style: TextStyle(
                color: noteColor ?? RpgColors.textMuted,
                fontSize: 10.5,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Two [CarStatCell]s side by side with a hairline between them.
class CarStatRow extends StatelessWidget {
  final Widget left;
  final Widget right;

  const CarStatRow({super.key, required this.left, required this.right});

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: left),
          Container(width: 1, color: RpgColors.divider),
          Expanded(child: right),
        ],
      ),
    );
  }
}
