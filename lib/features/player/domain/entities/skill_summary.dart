import 'dart:math';

const _masteryWeight = 0.25;

enum SkillId {
  japanese,
  wealth,
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
      case SkillId.wealth:
        return 'WEALTH';
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
      case SkillId.wealth:
        return 'Financial Power';
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

  double get levelWeight {
    switch (this) {
      case SkillId.japanese:
        return 1.2;
      case SkillId.wealth:
        return 1.2;
      case SkillId.creation:
        return 1.1;
      case SkillId.sport:
        return 1.0;
      case SkillId.mindfulness:
        return 1.0;
      case SkillId.social:
        return 1.0;
    }
  }
}

/// Per-skill aggregated view for the player sheet.
///
/// All time-based skills use [lifetimeMinutes] as primary input.
/// Wealth uses [currentNetWorthEur].
/// Creation additionally uses [weightedPoints] (project difficulty bonus).
/// Sport additionally uses [trainedDaysLast30] (consistency bonus).
class SkillSummary {
  final SkillId skill;

  // ── Time-based (all skills except wealth) ─────────────────────────────────
  final int lifetimeMinutes;
  final int last30DaysMinutes;

  // ── Sport: distinct training days in last 30 ───────────────────────────────
  final int trainedDaysLast30;

  // ── Creation: project difficulty bonus ─────────────────────────────────────
  final double weightedPoints;

  // ── Wealth: current net worth (€) ─────────────────────────────────────────
  final double currentNetWorthEur;

  const SkillSummary({
    required this.skill,
    this.lifetimeMinutes = 0,
    this.last30DaysMinutes = 0,
    this.trainedDaysLast30 = 0,
    this.weightedPoints = 0.0,
    this.currentNetWorthEur = 0.0,
  });

  double get _hours => lifetimeMinutes / 60.0;

  bool get isActive {
    switch (skill) {
      case SkillId.wealth:
        return currentNetWorthEur > 0;
      default:
        return last30DaysMinutes > 0;
    }
  }

  // ── Continuous raw level value (can exceed 100) ────────────────────────────

  double get _rawLevel {
    switch (skill) {
      case SkillId.japanese:
        // Sqrt. 2,200 hours → 100
        // Lv2 = ~1h, Lv10 = 22h, Lv50 = 550h, Lv100 = 2200h
        return sqrt(_hours) / sqrt(2200) * 100;

      case SkillId.wealth:
        // Sqrt. €1M → 100
        if (currentNetWorthEur <= 0) return 0;
        return sqrt(currentNetWorthEur / 1_000_000) * 100;

      case SkillId.mindfulness:
        // Sqrt. 10,000 min (~167h) → 100
        return sqrt(lifetimeMinutes.toDouble()) / sqrt(10_000) * 100;

      case SkillId.sport:
        // Sqrt volume + consistency bonus (up to +10)
        // 2,000 hours base → 100
        final volumeLevel = sqrt(_hours) / sqrt(2000) * 100;
        final consistencyBonus = 10.0 * (trainedDaysLast30 / 30.0);
        return volumeLevel + consistencyBonus;

      case SkillId.social:
        // Sqrt. 750 hours → 100
        return sqrt(_hours) / sqrt(750) * 100;

      case SkillId.creation:
        // Sqrt hours + project bonus
        // 1,000 hours base → ~90, projects fill the rest
        // Each project difficulty point → +2 levels
        final hoursLevel = sqrt(_hours) / sqrt(1000) * 100;
        final projectBonus = weightedPoints * 2;
        return hoursLevel + projectBonus;
    }
  }

  // ── Level (1–100) ──────────────────────────────────────────────────────────

  int get level => _rawLevel.floor().clamp(1, 100);

  // ── Mastery (0+, only grows beyond level-100 threshold) ───────────────────

  int get mastery {
    if (_rawLevel < 100) return 0;
    switch (skill) {
      case SkillId.japanese:
        // Every 200 hours beyond 2,200h = +1 mastery
        if (_hours <= 2200) return 0;
        return ((_hours - 2200) / 200).floor();

      case SkillId.wealth:
        if (currentNetWorthEur <= 1_000_000) return 0;
        return ((currentNetWorthEur - 1_000_000) / 250_000).floor();

      case SkillId.mindfulness:
        if (lifetimeMinutes <= 10_000) return 0;
        return ((lifetimeMinutes - 10_000) / 1_000).floor();

      case SkillId.sport:
        if (_hours <= 2000) return 0;
        return ((_hours - 2000) / 150).floor();

      case SkillId.social:
        if (_hours <= 750) return 0;
        return ((_hours - 750) / 100).floor();

      case SkillId.creation:
        if (_hours <= 1000) return 0;
        return ((_hours - 1000) / 100).floor();
    }
  }

  // ── Effective level for Player Level weighted average ──────────────────────

  double get effectiveLevel {
    final raw = _rawLevel;
    if (raw < 100) return raw.clamp(1.0, 100.0);
    return 100.0 + mastery * _masteryWeight;
  }

  // ── Remaining to next level — always in hours (except wealth → EUR) ───────

  String get remainingToNextLevel {
    final raw = _rawLevel;
    if (raw >= 100) return _remainingToNextMastery;
    final nextLevel = raw.floor() + 1;
    return _remainingForTarget(nextLevel);
  }

  String _remainingForTarget(int targetLevel) {
    switch (skill) {
      case SkillId.japanese:
        // level = sqrt(h)/sqrt(2200)*100 → h = (level/100)^2 * 2200
        final needed = pow(targetLevel / 100.0, 2) * 2200;
        return _fmtTime(needed - _hours);

      case SkillId.wealth:
        // level = sqrt(w/1M)*100 → w = (level/100)^2 * 1M
        final needed = pow(targetLevel / 100.0, 2) * 1_000_000;
        final remaining = (needed - currentNetWorthEur).ceil();
        return _fmtEur(remaining);

      case SkillId.mindfulness:
        // level = sqrt(m)/100*100 → m = (level/100)^2 * 10000
        final neededMin = pow(targetLevel / 100.0, 2) * 10_000;
        return _fmtTime((neededMin - lifetimeMinutes) / 60.0);

      case SkillId.sport:
        final bonus = 10.0 * (trainedDaysLast30 / 30.0);
        final neededVolume = targetLevel - bonus;
        final volumeRaw = sqrt(_hours) / sqrt(2000) * 100;
        if (neededVolume <= volumeRaw) return '0h';
        final neededHours = pow(neededVolume / 100.0, 2) * 2000;
        return _fmtTime(neededHours - _hours);

      case SkillId.social:
        // level = sqrt(h)/sqrt(750)*100 → h = (level/100)^2 * 750
        final needed = pow(targetLevel / 100.0, 2) * 750;
        return _fmtTime(needed - _hours);

      case SkillId.creation:
        // level = sqrt(h)/sqrt(1000)*100 + points*2
        final bonus = weightedPoints * 2;
        final neededHoursLevel = targetLevel - bonus;
        final hoursRaw = sqrt(_hours) / sqrt(1000) * 100;
        if (neededHoursLevel <= hoursRaw) return '0h';
        final neededHours = pow(neededHoursLevel / 100.0, 2) * 1000;
        return _fmtTime(neededHours - _hours);
    }
  }

  String get _remainingToNextMastery {
    switch (skill) {
      case SkillId.japanese:
        final excess = _hours - 2200;
        return _fmtTime(200 - (excess % 200));
      case SkillId.wealth:
        final excess = currentNetWorthEur - 1_000_000;
        return _fmtEur((250_000 - (excess % 250_000)).ceil());
      case SkillId.mindfulness:
        final excessMin = lifetimeMinutes - 10_000;
        return _fmtTime((1_000 - (excessMin % 1_000)) / 60.0);
      case SkillId.sport:
        final excess = _hours - 2000;
        return _fmtTime(150 - (excess % 150));
      case SkillId.social:
        final excess = _hours - 750;
        return _fmtTime(100 - (excess % 100));
      case SkillId.creation:
        final excess = _hours - 1000;
        return _fmtTime(100 - (excess % 100));
    }
  }

  static String _fmtTime(double hours) {
    if (hours <= 0) return '0m';
    if (hours < 1) {
      final m = (hours * 60).ceil();
      return '${m}m';
    }
    final h = hours.ceil();
    if (h >= 1000) return '${(h / 1000).toStringAsFixed(1)}kh';
    return '${h}h';
  }

  static String _fmtEur(int amount) {
    if (amount >= 1_000_000) {
      return '${(amount / 1_000_000).toStringAsFixed(1)}M';
    }
    if (amount >= 1_000) {
      return '${(amount / 1_000).toStringAsFixed(1)}k';
    }
    return '€$amount';
  }

  // ── Progress bar (0–1) ─────────────────────────────────────────────────────

  double get progressToNextLevel {
    final raw = _rawLevel;
    if (raw < 100) {
      return (raw - raw.floor()).clamp(0.0, 1.0);
    }
    switch (skill) {
      case SkillId.japanese:
        if (_hours <= 2200) return 0.0;
        return ((_hours - 2200) % 200) / 200.0;
      case SkillId.wealth:
        if (currentNetWorthEur < 1_000_000) return 0.0;
        return ((currentNetWorthEur - 1_000_000) % 250_000) / 250_000.0;
      case SkillId.mindfulness:
        if (lifetimeMinutes <= 10_000) return 0.0;
        return ((lifetimeMinutes - 10_000) % 1_000) / 1_000.0;
      case SkillId.sport:
        if (_hours <= 2000) return 0.0;
        return ((_hours - 2000) % 150) / 150.0;
      case SkillId.social:
        if (_hours <= 750) return 0.0;
        return ((_hours - 750) % 100) / 100.0;
      case SkillId.creation:
        if (_hours <= 1000) return 0.0;
        return ((_hours - 1000) % 100) / 100.0;
    }
  }
}
