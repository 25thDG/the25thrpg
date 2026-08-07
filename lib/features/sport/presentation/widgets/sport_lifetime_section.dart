import 'package:flutter/material.dart';

import '../../../../core/theme/rpg_colors.dart';
import '../../domain/entities/sport_stats.dart';

const _colorSport = Color(0xFFFF7043);
const _colorSportLight = Color(0xFFFFAB91);

class SportLifetimeSection extends StatelessWidget {
  final SportStats stats;

  const SportLifetimeSection({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final hours = stats.lifetimeHours;
    final displayHours = hours >= 1000
        ? '${(hours / 1000).toStringAsFixed(1)}k'
        : hours.toStringAsFixed(1);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: RpgColors.border),
        gradient: const RadialGradient(
          center: Alignment(0.9, -0.9),
          radius: 1.2,
          colors: [Color(0xFF2A1208), RpgColors.panelBg],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 3,
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
              gradient: LinearGradient(
                  colors: [_colorSport, Color(0xFFFF8A65)]),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'LIFETIME',
                  style: TextStyle(
                    color: RpgColors.textMuted,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 2.4,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _AnimatedCounter(
                      value: hours,
                      displayText: displayHours,
                    ),
                    const SizedBox(width: 8),
                    const Padding(
                      padding: EdgeInsets.only(bottom: 6),
                      child: Text(
                        'hrs',
                        style: TextStyle(
                          color: RpgColors.textMuted,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${stats.lifetimeMinutes} min total',
                  style: const TextStyle(
                    color: RpgColors.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Container(height: 1, color: RpgColors.divider),
          IntrinsicHeight(
            child: Row(
              children: [
                Expanded(
                  child: _RollingStat(
                    label: 'LAST 30 DAYS',
                    minutes: stats.last30DaysMinutes,
                  ),
                ),
                Container(width: 1, color: RpgColors.divider),
                Expanded(
                  child: _RollingStat(
                    label: 'BEST 30-DAY',
                    minutes: stats.best30DayMinutes,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedCounter extends StatefulWidget {
  final double value;
  final String displayText;

  const _AnimatedCounter({required this.value, required this.displayText});

  @override
  State<_AnimatedCounter> createState() => _AnimatedCounterState();
}

class _AnimatedCounterState extends State<_AnimatedCounter>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, _) => Text(
        widget.displayText,
        style: const TextStyle(
          color: Color(0xFFFFEDE8),
          fontSize: 52,
          fontWeight: FontWeight.w800,
          letterSpacing: -2,
          height: 1.0,
          shadows: [
            Shadow(
              color: Color(0x77FF7043),
              blurRadius: 24,
            ),
          ],
        ),
      ),
    );
  }
}

class _RollingStat extends StatelessWidget {
  final String label;
  final int minutes;

  const _RollingStat({required this.label, required this.minutes});

  @override
  Widget build(BuildContext context) {
    final hrs = (minutes / 60).toStringAsFixed(1);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                hrs,
                style: const TextStyle(
                  color: _colorSportLight,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                  height: 1.0,
                ),
              ),
              const SizedBox(width: 4),
              const Text(
                'hrs',
                style: TextStyle(
                  color: RpgColors.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 1),
          Text(
            '$minutes min',
            style: const TextStyle(
              color: RpgColors.textMuted,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
