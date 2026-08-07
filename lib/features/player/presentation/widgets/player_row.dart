import 'package:flutter/material.dart';

import 'rpg_colors.dart';

/// The one row shape used by every list below the character.
///
/// A small coloured dot (echoing the radar's vertex dots) carries all the
/// identity colour; the text stays neutral. The old rows each had a 3px
/// coloured stripe down their left edge — that was the inner edge of a card,
/// and once the cards were removed it read as an orphaned stripe.
class PlayerRow extends StatelessWidget {
  /// Identity colour, shown only as the leading dot.
  final Color dotColor;

  /// Dims the dot for dormant/idle entries.
  final bool dimDot;

  final String title;
  final String? subtitle;

  /// Right-hand value. Neutral unless [valueColor] says otherwise.
  final String value;
  final Color? valueColor;

  /// Optional element under the value, e.g. a thin progress bar.
  final Widget? valueFooter;

  /// Optional badge under the value, e.g. the pace trend chip.
  final Widget? badge;

  final VoidCallback? onTap;

  const PlayerRow({
    super.key,
    required this.dotColor,
    required this.title,
    required this.value,
    this.subtitle,
    this.valueColor,
    this.valueFooter,
    this.badge,
    this.dimDot = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 7,
              height: 7,
              margin: const EdgeInsets.only(right: 12, top: 2),
              decoration: BoxDecoration(
                color: dimDot ? dotColor.withValues(alpha: 0.3) : dotColor,
                shape: BoxShape.circle,
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: dimDot
                          ? RpgColors.textSecondary
                          : RpgColors.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.4,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      subtitle!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: RpgColors.textMuted,
                        fontSize: 9,
                        height: 1.35,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    color: value == '—'
                        ? RpgColors.textMuted
                        : (valueColor ?? RpgColors.textPrimary),
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
                if (badge != null) ...[
                  const SizedBox(height: 4),
                  badge!,
                ],
                if (valueFooter != null) ...[
                  const SizedBox(height: 6),
                  valueFooter!,
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Hairline between rows, inset to the same gutter as the row text.
class PlayerRowDivider extends StatelessWidget {
  const PlayerRowDivider({super.key});

  @override
  Widget build(BuildContext context) => const Divider(
        height: 1,
        thickness: 1,
        color: RpgColors.divider,
        indent: 20,
        endIndent: 20,
      );
}
