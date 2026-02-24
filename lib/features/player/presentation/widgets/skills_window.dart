import 'package:flutter/material.dart';

import '../../domain/entities/skill_summary.dart';
import 'rpg_colors.dart';
import 'skill_row_widget.dart';

/// The full-width framed Skills table — lists all tracked skills
/// with staggered fade-in animations.
class SkillsWindow extends StatefulWidget {
  final List<SkillSummary> skills;

  const SkillsWindow({super.key, required this.skills});

  @override
  State<SkillsWindow> createState() => _SkillsWindowState();
}

class _SkillsWindowState extends State<SkillsWindow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<Animation<double>> _rowAnimations;

  @override
  void initState() {
    super.initState();

    final count = widget.skills.length;
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 400 + count * 120),
    );

    // Stagger: each row starts 80 ms after the previous one.
    _rowAnimations = List.generate(count, (i) {
      final start = i / (count + 1) * 0.65;
      final end = (start + 0.35).clamp(0.0, 1.0);
      return CurvedAnimation(
        parent: _controller,
        curve: Interval(start, end, curve: Curves.easeOutCubic),
      );
    });

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: RpgColors.panelBg,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: RpgColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _WindowHeader(),
          ...List.generate(widget.skills.length, (i) {
            final skill = widget.skills[i];
            final isLast = i == widget.skills.length - 1;
            return Column(
              children: [
                SkillRowWidget(
                  key: ValueKey(skill.skill),
                  skill: skill,
                  animation: _rowAnimations[i],
                ),
                if (!isLast)
                  const Divider(
                    height: 1,
                    thickness: 1,
                    color: RpgColors.divider,
                    indent: 20,
                    endIndent: 20,
                  ),
              ],
            );
          }),
        ],
      ),
    );
  }
}

class _WindowHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: RpgColors.divider)),
      ),
      child: const Text(
        'SKILLS',
        style: TextStyle(
          color: RpgColors.textMuted,
          fontSize: 10,
          fontWeight: FontWeight.w600,
          letterSpacing: 2.4,
        ),
      ),
    );
  }
}
