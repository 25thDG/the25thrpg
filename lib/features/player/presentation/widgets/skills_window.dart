import 'package:flutter/material.dart';

import '../../domain/entities/skill_summary.dart';
import 'player_section.dart';
import 'skill_milestone_sheet.dart';
import 'skill_row_widget.dart';

/// Skills list — one row per tracked skill, with staggered fade-in.
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
    return PlayerSection(
      title: 'SKILLS',
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: List.generate(widget.skills.length, (i) {
            final skill = widget.skills[i];
            return SkillRowWidget(
              key: ValueKey(skill.skill),
              skill: skill,
              animation: _rowAnimations[i],
              onTap: () => showSkillMilestoneSheet(context, skill),
            );
          }),
        ),
      ),
    );
  }
}
