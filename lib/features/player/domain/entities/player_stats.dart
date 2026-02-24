import 'dart:math';

import 'skill_summary.dart';

/// Aggregate player-level statistics derived from all skills.
///
/// Player level formula: level = ⌊√(totalLifetimeHours / 20)⌋ + 1
///   Level 1 → 0 h   Level 2 → 20 h   Level 3 → 80 h
///   Level 4 → 180 h Level 5 → 320 h  Level 10 → 1,820 h
class PlayerStats {
  final List<SkillSummary> skills;

  const PlayerStats({required this.skills});

  int get totalLifetimeMinutes =>
      skills.fold(0, (sum, s) => sum + s.lifetimeMinutes);

  double get totalLifetimeHours => totalLifetimeMinutes / 60.0;

  int get playerLevel {
    final hours = totalLifetimeHours;
    return (sqrt(hours / 20) + 1).floor().clamp(1, 99);
  }

  int get _currentLevelFloorMinutes {
    final lvl = playerLevel - 1;
    return (lvl * lvl * 20 * 60).round();
  }

  int get _nextLevelCeilMinutes {
    final lvl = playerLevel;
    return (lvl * lvl * 20 * 60).round();
  }

  double get playerProgressToNextLevel {
    final span = _nextLevelCeilMinutes - _currentLevelFloorMinutes;
    if (span <= 0) return 1.0;
    return ((totalLifetimeMinutes - _currentLevelFloorMinutes) / span)
        .clamp(0.0, 1.0);
  }

  int get activeSkillCount => skills.where((s) => s.isActive).length;

  SkillSummary? get currentFocus {
    if (skills.isEmpty) return null;
    final active = skills.where((s) => s.isActive).toList();
    if (active.isEmpty) return null;
    return active.reduce(
      (a, b) => a.last30DaysMinutes >= b.last30DaysMinutes ? a : b,
    );
  }
}
