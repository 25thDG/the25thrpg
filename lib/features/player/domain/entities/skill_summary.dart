import 'dart:math';

enum SkillId {
  japanese,
  mindfulness,
  creation,
  social,
  sport,
}

extension SkillIdX on SkillId {
  String get displayName {
    switch (this) {
      case SkillId.japanese:
        return 'JAPANESE';
      case SkillId.mindfulness:
        return 'MINDFULNESS';
      case SkillId.creation:
        return 'CREATION';
      case SkillId.social:
        return 'SOCIAL';
      case SkillId.sport:
        return 'SPORT';
    }
  }

  String get descriptor {
    switch (this) {
      case SkillId.japanese:
        return 'Linguistic Mastery';
      case SkillId.mindfulness:
        return 'Inner Discipline';
      case SkillId.creation:
        return 'Artistic Expression';
      case SkillId.social:
        return 'Human Connection';
      case SkillId.sport:
        return 'Physical Mastery';
    }
  }
}

/// Per-skill aggregated view for the player sheet.
///
/// Level formula: level = ⌊√(lifetimeHours / 5)⌋ + 1
///   Level 1 → 0 h   Level 2 → 5 h   Level 3 → 20 h
///   Level 4 → 45 h  Level 5 → 80 h  Level 10 → 405 h
class SkillSummary {
  final SkillId skill;
  final int lifetimeMinutes;
  final int last30DaysMinutes;

  const SkillSummary({
    required this.skill,
    required this.lifetimeMinutes,
    required this.last30DaysMinutes,
  });

  bool get isActive => last30DaysMinutes > 0;

  int get level {
    final hours = lifetimeMinutes / 60.0;
    return (sqrt(hours / 5) + 1).floor().clamp(1, 99);
  }

  /// Minutes required to reach the start of the current level.
  int get _currentLevelFloorMinutes {
    final lvl = level - 1;
    return (lvl * lvl * 5 * 60).round();
  }

  /// Minutes required to reach the next level.
  int get _nextLevelCeilMinutes {
    final lvl = level;
    return (lvl * lvl * 5 * 60).round();
  }

  double get progressToNextLevel {
    final span = _nextLevelCeilMinutes - _currentLevelFloorMinutes;
    if (span <= 0) return 1.0;
    return ((lifetimeMinutes - _currentLevelFloorMinutes) / span)
        .clamp(0.0, 1.0);
  }

  int get minutesToNextLevel =>
      (_nextLevelCeilMinutes - lifetimeMinutes).clamp(0, _nextLevelCeilMinutes);
}
