import 'package:flutter/material.dart';

import 'rpg_colors.dart';

/// One cell of a [PlayerStatGrid].
class PlayerStatCell {
  final String label;
  final String value;

  /// Only set when the colour means something (a state, not decoration).
  final Color? valueColor;

  /// Widens this cell relative to its neighbours — for long values like
  /// "MINDFULNESS" sitting next to "3/4".
  final int flex;

  const PlayerStatCell({
    required this.label,
    required this.value,
    this.valueColor,
    this.flex = 3,
  });
}

/// A left-aligned row of small label/value pairs.
///
/// Both the character's summary stats and today's check-in use this, so the two
/// blocks read as the same kind of thing instead of one being a left-aligned
/// table and the other a row of centred icons.
class PlayerStatGrid extends StatelessWidget {
  final List<PlayerStatCell> cells;
  final EdgeInsets padding;

  const PlayerStatGrid({
    super.key,
    required this.cells,
    this.padding = const EdgeInsets.fromLTRB(20, 0, 20, 4),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final (i, cell) in cells.indexed)
            Expanded(
              flex: cell.flex,
              child: Padding(
                // A gutter between cells — without it a value scaled to fill
                // its column butts straight into the next one.
                padding:
                    EdgeInsets.only(right: i == cells.length - 1 ? 0 : 12),
                child: _Cell(cell: cell),
              ),
            ),
        ],
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  final PlayerStatCell cell;

  const _Cell({required this.cell});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          cell.label,
          style: const TextStyle(
            color: RpgColors.textMuted,
            fontSize: 8,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.4,
          ),
        ),
        const SizedBox(height: 5),
        // Long values like "MINDFULNESS" shrink to fit rather than ellipsising,
        // so a cell never loses its meaning.
        Align(
          alignment: Alignment.centerLeft,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              cell.value,
              maxLines: 1,
              style: TextStyle(
                color: cell.value == '—'
                    ? RpgColors.textMuted
                    : (cell.valueColor ?? RpgColors.textPrimary),
                fontSize: 15,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
