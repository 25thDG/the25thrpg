import 'package:flutter/material.dart';

import 'rpg_colors.dart';

/// A flat section on the Player screen: a quiet label, an optional trailing
/// note, then content.
///
/// Deliberately has no card background, border or accent bar. The old screen
/// gave five stacked panels identical chrome, so nothing led the eye — here the
/// character is the only loud element and every section below it whispers.
class PlayerSection extends StatelessWidget {
  final String title;
  final String? trailing;
  final Widget child;

  /// Draws a hairline above the label to separate it from the section before.
  final bool showDivider;

  const PlayerSection({
    super.key,
    required this.title,
    required this.child,
    this.trailing,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showDivider)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Divider(height: 1, thickness: 1, color: RpgColors.divider),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Row(
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: RpgColors.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 2.4,
                ),
              ),
              if (trailing != null) ...[
                const Spacer(),
                Text(
                  trailing!,
                  style: const TextStyle(
                    color: RpgColors.textMuted,
                    fontSize: 9,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ],
          ),
        ),
        child,
      ],
    );
  }
}
