import 'package:flutter/material.dart';

import '../../domain/entities/skill_summary.dart';

/// One accent colour per skill, shared by the radar, the skill rows and the
/// milestone sheet so a skill looks the same everywhere.
Color skillColor(SkillId id) {
  switch (id) {
    case SkillId.japanese:
      return const Color(0xFF4FC3F7);
    case SkillId.wealth:
      return const Color(0xFF10B981);
    case SkillId.mindfulness:
      return const Color(0xFF26A69A);
    case SkillId.resolve:
      // Matches the amber used across the Quests tab.
      return const Color(0xFFF59E0B);
  }
}
