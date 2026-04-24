import 'dart:math';

const _masteryWeight = 0.25;

enum SkillId {
  japanese,
  wealth,
  mindfulness,
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
    }
  }

  double get levelWeight {
    switch (this) {
      case SkillId.japanese:
        return 1.2;
      case SkillId.wealth:
        return 1.2;
      case SkillId.mindfulness:
        return 1.0;
    }
  }
}

/// Per-skill aggregated view for the player sheet.
///
/// All time-based skills use [lifetimeMinutes] as primary input.
/// Wealth uses [currentNetWorthEur].
class SkillSummary {
  final SkillId skill;

  // ── Time-based (japanese, mindfulness) ────────────────────────────────────
  final int lifetimeMinutes;
  final int last30DaysMinutes;

  /// Minutes logged since the daily-average tracking start date (2026-04-11).
  /// For mindfulness, addiction sessions are excluded.
  final int minutesSinceTracking;

  // ── Wealth: current net worth (€) ─────────────────────────────────────────
  final double currentNetWorthEur;

  /// Average monthly net-worth growth derived from all wealth snapshots.
  /// Null when fewer than 2 snapshots exist.
  final double? monthlyGrowthEur;

  const SkillSummary({
    required this.skill,
    this.lifetimeMinutes = 0,
    this.last30DaysMinutes = 0,
    this.minutesSinceTracking = 0,
    this.currentNetWorthEur = 0.0,
    this.monthlyGrowthEur,
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
        return sqrt(_hours) / sqrt(2200) * 100;

      case SkillId.wealth:
        // Sqrt. €1M → 100
        if (currentNetWorthEur <= 0) return 0;
        return sqrt(currentNetWorthEur / 1_000_000) * 100;

      case SkillId.mindfulness:
        // Sqrt. 10,000 min (~167h) → 100
        return sqrt(lifetimeMinutes.toDouble()) / sqrt(10_000) * 100;
    }
  }

  // ── Level (1–100) ──────────────────────────────────────────────────────────

  int get level => _rawLevel.floor().clamp(1, 100);

  // ── Mastery (0+, only grows beyond level-100 threshold) ───────────────────

  int get mastery {
    if (_rawLevel < 100) return 0;
    switch (skill) {
      case SkillId.japanese:
        if (_hours <= 2200) return 0;
        return ((_hours - 2200) / 200).floor();

      case SkillId.wealth:
        if (currentNetWorthEur <= 1_000_000) return 0;
        return ((currentNetWorthEur - 1_000_000) / 250_000).floor();

      case SkillId.mindfulness:
        if (lifetimeMinutes <= 10_000) return 0;
        return ((lifetimeMinutes - 10_000) / 1_000).floor();
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
        final needed = pow(targetLevel / 100.0, 2) * 2200;
        return _fmtTime(needed - _hours);

      case SkillId.wealth:
        final needed = pow(targetLevel / 100.0, 2) * 1_000_000;
        final remaining = (needed - currentNetWorthEur).ceil();
        return _fmtEur(remaining);

      case SkillId.mindfulness:
        final neededMin = pow(targetLevel / 100.0, 2) * 10_000;
        return _fmtTime((neededMin - lifetimeMinutes) / 60.0);
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
    }
  }

  // ── Next 5 level milestones ────────────────────────────────────────────────

  /// Returns the next [count] level or mastery milestones from the current
  /// position. Each entry includes the amount remaining from now and, for
  /// wealth only, the absolute target net-worth threshold.
  List<({int level, bool isMastery, String remaining, String? target})>
      nextLevelMilestones({int count = 5}) {
    final raw = _rawLevel;

    if (raw >= 100) {
      return List.generate(count, (i) {
        final targetMastery = mastery + i + 1;
        return (
          level: targetMastery,
          isMastery: true,
          remaining: _remainingForMastery(targetMastery),
          target: _wealthMasteryTarget(targetMastery),
        );
      });
    }

    return List.generate(count, (i) {
      final targetLevel = level + i + 1;
      if (targetLevel <= 100) {
        return (
          level: targetLevel,
          isMastery: false,
          remaining: _remainingForTarget(targetLevel),
          target: _wealthLevelTarget(targetLevel),
        );
      }
      // Overflow into mastery
      final targetMastery = targetLevel - 100;
      return (
        level: targetMastery,
        isMastery: true,
        remaining: _remainingForMastery(targetMastery),
        target: _wealthMasteryTarget(targetMastery),
      );
    });
  }

  /// Absolute net-worth threshold for a regular wealth level (null for non-wealth).
  String? _wealthLevelTarget(int targetLevel) {
    if (skill != SkillId.wealth) return null;
    final thresh = pow(targetLevel / 100.0, 2) * 1_000_000;
    return _fmtEur(thresh.ceil());
  }

  /// Absolute net-worth threshold for a wealth mastery tier (null for non-wealth).
  String? _wealthMasteryTarget(int targetMastery) {
    if (skill != SkillId.wealth) return null;
    final thresh = 1_000_000.0 + targetMastery * 250_000.0;
    return _fmtEur(thresh.ceil());
  }

  String _remainingForMastery(int targetMastery) {
    switch (skill) {
      case SkillId.japanese:
        final needed = 2200.0 + targetMastery * 200.0;
        return _fmtTime(needed - _hours);
      case SkillId.wealth:
        final needed = 1_000_000.0 + targetMastery * 250_000.0;
        return _fmtEur((needed - currentNetWorthEur).ceil());
      case SkillId.mindfulness:
        final needed = 10_000.0 + targetMastery * 1_000.0;
        return _fmtTime((needed - lifetimeMinutes) / 60.0);
    }
  }

  // ── Daily average (time-based skills only) ─────────────────────────────────

  static final _trackingStart = DateTime(2026, 4, 11);

  /// Average minutes per day since tracking start. Returns 0 for wealth.
  double get dailyAverageMinutes {
    if (skill == SkillId.wealth) return 0;
    final days = DateTime.now().difference(_trackingStart).inDays + 1;
    return minutesSinceTracking / days.clamp(1, 9999);
  }

  // ── Wealth projection ──────────────────────────────────────────────────────

  /// Human-readable time until €1M, e.g. "2.3y" or "8mo".
  /// Null if already at/above €1M, no growth data, or negative growth.
  String? get projectedTimeToMillion {
    if (skill != SkillId.wealth) return null;
    if (currentNetWorthEur >= 1_000_000) return null;
    final growth = monthlyGrowthEur;
    if (growth == null || growth <= 0) return null;
    final monthsLeft = ((1_000_000 - currentNetWorthEur) / growth).ceil();
    if (monthsLeft <= 0) return null;
    if (monthsLeft < 12) return '${monthsLeft}mo';
    final years = monthsLeft / 12.0;
    return '${years.toStringAsFixed(1)}y';
  }
}
