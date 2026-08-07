import 'package:flutter/material.dart';

import 'rpg_colors.dart';

/// Rounded frosted tile used by every block below the character.
///
/// A soft top-lit gradient plus a hairline highlight along the top edge gives
/// the glass feel without a blur pass — the page behind is flat black, so a
/// real BackdropFilter would cost frames and show nothing.
class PlayerCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final EdgeInsets margin;

  /// Tints the card and its edge — used to give a card its identity colour.
  final Color? accent;

  final VoidCallback? onTap;

  const PlayerCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin = const EdgeInsets.only(bottom: 10),
    this.accent,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tint = accent ?? Colors.white;

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.alphaBlend(tint.withValues(alpha: 0.05), RpgColors.panelBgAlt),
            RpgColors.panelBg,
          ],
        ),
        border: Border.all(color: tint.withValues(alpha: 0.10)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Stack(
            children: [
              // Hairline highlight along the top edge — the "glass" tell.
              Positioned(
                top: 0,
                left: 18,
                right: 18,
                child: Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        tint.withValues(alpha: 0.22),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              Padding(padding: padding, child: child),
            ],
          ),
        ),
      ),
    );
  }
}

/// Small uppercase caption used as a card's title.
class CardLabel extends StatelessWidget {
  final String text;
  final Color? color;

  const CardLabel(this.text, {super.key, this.color});

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: TextStyle(
          color: color ?? RpgColors.textMuted,
          fontSize: 9,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.8,
        ),
      );
}
