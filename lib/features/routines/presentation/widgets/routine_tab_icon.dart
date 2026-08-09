import 'package:flutter/material.dart';

import '../../../player/presentation/widgets/rpg_colors.dart';
import '../../domain/entities/foundation.dart';
import '../controllers/routine_controller.dart';
import 'foundation_style.dart';

/// What the tab should be shouting, if anything.
enum RoutineBadge {
  /// Nothing to say — every habit kept, or none set up yet.
  none,

  /// Habits still open today.
  pending,

  /// Something breaks tonight.
  atRisk,

  /// Something already has.
  broken,
}

extension on RoutineBadge {
  Color? get color => switch (this) {
        RoutineBadge.none => null,
        RoutineBadge.pending => FoundationColors.solid,
        RoutineBadge.atRisk => FoundationColors.cracked,
        RoutineBadge.broken => FoundationColors.broken,
      };

  /// Only genuine urgency moves. A steady glow for "still to do" keeps the
  /// pulse meaningful when it does appear.
  bool get pulses =>
      this == RoutineBadge.atRisk || this == RoutineBadge.broken;
}

RoutineBadge badgeFor(FoundationState? state) => switch (state) {
      null => RoutineBadge.none,
      FoundationState.solid => RoutineBadge.none,
      FoundationState.open => RoutineBadge.pending,
      FoundationState.cracked => RoutineBadge.atRisk,
      FoundationState.broken => RoutineBadge.broken,
    };

/// The Daily tab's icon, lit while anything is still open.
///
/// Colour escalates with the two-day rule: green while there is simply work
/// left, amber once a habit breaks tonight, red once one already has. When
/// everything is kept the glow goes out entirely — that absence is the reward.
class RoutineTabIcon extends StatefulWidget {
  final RoutineController controller;
  final IconData icon;
  final bool selected;

  const RoutineTabIcon({
    super.key,
    required this.controller,
    required this.icon,
    required this.selected,
  });

  @override
  State<RoutineTabIcon> createState() => _RoutineTabIconState();
}

class _RoutineTabIconState extends State<RoutineTabIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final state = widget.controller.state;
        final badge = badgeFor(state.board.stateOn(state.today));
        final color = badge.color;

        if (color == null) {
          return Icon(
            widget.icon,
            size: 20,
            color: widget.selected
                ? RpgColors.textPrimary
                : RpgColors.textMuted,
          );
        }

        return AnimatedBuilder(
          animation: _pulse,
          builder: (_, _) {
            // Held above zero by construction — a shadow blur may never go
            // negative, and this is computed rather than interpolated so it
            // cannot.
            final t = badge.pulses
                ? Curves.easeInOut.transform(_pulse.value)
                : 0.0;
            final blur = 7.0 + t * 7.0;
            final alpha = (badge.pulses ? 0.55 + t * 0.4 : 0.6).toDouble();

            return Icon(
              widget.icon,
              size: 20,
              color: color,
              shadows: [Shadow(color: color.withValues(alpha: alpha), blurRadius: blur)],
            );
          },
        );
      },
    );
  }
}

/// The label under it, tinted to match so the two never disagree.
class RoutineTabLabel extends StatelessWidget {
  final RoutineController controller;
  final String label;
  final bool selected;

  const RoutineTabLabel({
    super.key,
    required this.controller,
    required this.label,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final state = controller.state;
        final color =
            badgeFor(state.board.stateOn(state.today)).color;

        return Text(
          label,
          style: TextStyle(
            color: color ??
                (selected ? RpgColors.textPrimary : RpgColors.textMuted),
            fontSize: 9,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            letterSpacing: 0.3,
          ),
        );
      },
    );
  }
}
