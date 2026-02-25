import 'skill_summary.dart';

/// Aggregate player-level statistics derived from all skills.
///
/// Player Level = ⌊ Σ(effectiveLevel × weight) / Σ(weights) ⌋
///
/// Where effectiveLevel per skill:
///   level < 100  → effectiveLevel = rawLevel (continuous 1–100)
///   level ≥ 100  → effectiveLevel = 100 + mastery × 0.25
///
/// Weights: Japanese 1.2, Wealth 1.2, Creation 1.1, Sport/Mindfulness/Social 1.0
class PlayerStats {
  final List<SkillSummary> skills;

  const PlayerStats({required this.skills});

  double get _playerLevelRaw {
    if (skills.isEmpty) return 1.0;
    final totalWeight =
        skills.fold(0.0, (sum, s) => sum + s.skill.levelWeight);
    final weightedSum = skills.fold(
      0.0,
      (sum, s) => sum + s.effectiveLevel * s.skill.levelWeight,
    );
    return weightedSum / totalWeight;
  }

  int get playerLevel => _playerLevelRaw.floor().clamp(1, 999);

  double get playerProgressToNextLevel {
    final raw = _playerLevelRaw;
    return (raw - raw.floor()).clamp(0.0, 1.0);
  }

  int get activeSkillCount => skills.where((s) => s.isActive).length;

  int get totalMastery => skills.fold(0, (sum, s) => sum + s.mastery);

  SkillSummary? get topSkill {
    if (skills.isEmpty) return null;
    return skills.reduce(
      (a, b) => a.effectiveLevel >= b.effectiveLevel ? a : b,
    );
  }
}
