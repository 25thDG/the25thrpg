import 'package:flutter/material.dart';

import '../../../../core/progression/level_watcher.dart';
import 'rpg_colors.dart';
import 'skill_colors.dart';

const _crimsonLight = Color(0xFFE74C3C);

Color _colorFor(LevelUpEvent e) =>
    e.isPlayer ? _crimsonLight : skillColor(e.skill!);

/// The moment a level actually lands.
///
/// Levels are derived from logged time, so without this they simply change one
/// day and nobody notices. Shown over the character sheet the first time the
/// app sees the new number.
class LevelUpOverlay extends StatefulWidget {
  final List<LevelUpEvent> events;

  const LevelUpOverlay({super.key, required this.events});

  static Future<void> show(
    BuildContext context,
    List<LevelUpEvent> events,
  ) {
    if (events.isEmpty) return Future.value();
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Level up',
      barrierColor: const Color(0xF70A0A0D),
      transitionDuration: const Duration(milliseconds: 420),
      pageBuilder: (_, _, _) => LevelUpOverlay(events: events),
      transitionBuilder: (_, animation, _, child) {
        final curved =
            CurvedAnimation(parent: animation, curve: Curves.easeOutBack);
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(scale: Tween(begin: 0.88, end: 1.0).animate(curved), child: child),
        );
      },
    );
  }

  @override
  State<LevelUpOverlay> createState() => _LevelUpOverlayState();
}

class _LevelUpOverlayState extends State<LevelUpOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final headline = widget.events.first;
    final rest = widget.events.skip(1).toList();
    final color = _colorFor(headline);

    return Material(
      type: MaterialType.transparency,
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.events.length > 1 ? 'LEVELS GAINED' : 'LEVEL UP',
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 4.5,
                  ),
                ),
                const SizedBox(height: 26),
                _Headline(event: headline, pulse: _pulse),
                if (rest.isNotEmpty) ...[
                  const SizedBox(height: 26),
                  for (final e in rest) _SecondaryLine(event: e),
                ],
                const SizedBox(height: 34),
                _Dismiss(color: color, onTap: () => Navigator.of(context).pop()),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The skill that rose, its new level counting up, and where it came from.
class _Headline extends StatelessWidget {
  final LevelUpEvent event;
  final Animation<double> pulse;

  const _Headline({required this.event, required this.pulse});

  @override
  Widget build(BuildContext context) {
    final color = _colorFor(event);

    return Column(
      children: [
        Text(
          event.title,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: color,
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 3.0,
          ),
        ),
        const SizedBox(height: 18),
        AnimatedBuilder(
          animation: pulse,
          builder: (_, _) {
            final t = Curves.easeInOut.transform(pulse.value);
            return Container(
              width: 190,
              height: 190,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    color.withValues(alpha: 0.26 + t * 0.12),
                    color.withValues(alpha: 0.07),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.55, 1.0],
                ),
              ),
              child: TweenAnimationBuilder<double>(
                tween: Tween(
                  begin: event.from.toDouble(),
                  end: event.to.toDouble(),
                ),
                duration: const Duration(milliseconds: 1300),
                curve: Curves.easeOutCubic,
                builder: (_, value, _) => Text(
                  '${value.round()}',
                  style: TextStyle(
                    color: const Color(0xFFFDF4F2),
                    fontSize: 88,
                    fontWeight: FontWeight.w900,
                    height: 1.0,
                    letterSpacing: -5,
                    shadows: [
                      Shadow(
                        color: color.withValues(alpha: 0.75),
                        blurRadius: 34,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 14),
        Text(
          event.gained > 1
              ? 'Lv ${event.from}  →  Lv ${event.to}   ·   +${event.gained}'
              : 'Lv ${event.from}  →  Lv ${event.to}',
          style: const TextStyle(
            color: RpgColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.6,
          ),
        ),
      ],
    );
  }
}

/// Any further gains, one quiet line each.
class _SecondaryLine extends StatelessWidget {
  final LevelUpEvent event;

  const _SecondaryLine({required this.event});

  @override
  Widget build(BuildContext context) {
    final color = _colorFor(event);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: color.withValues(alpha: 0.08),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              boxShadow: [
                BoxShadow(color: color.withValues(alpha: 0.6), blurRadius: 7),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            event.title,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.6,
            ),
          ),
          const SizedBox(width: 14),
          Text(
            'Lv ${event.from} → ${event.to}',
            style: const TextStyle(
              color: RpgColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _Dismiss extends StatelessWidget {
  final Color color;
  final VoidCallback onTap;

  const _Dismiss({required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 42, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: color.withValues(alpha: 0.14),
            border: Border.all(color: color.withValues(alpha: 0.45)),
          ),
          child: Text(
            'CONTINUE',
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 2.6,
            ),
          ),
        ),
      ),
    );
  }
}

/// The line the notification carries.
String levelUpNotificationBody(List<LevelUpEvent> events) {
  final first = events.first;
  final more = events.length - 1;
  final head = first.isPlayer
      ? 'You reached level ${first.to}.'
      : '${first.title} reached level ${first.to}.';
  if (more <= 0) return head;
  return '$head And $more more.';
}

/// The title the notification carries.
String levelUpNotificationTitle(List<LevelUpEvent> events) =>
    events.length > 1 ? 'LEVELS GAINED' : 'LEVEL UP';
