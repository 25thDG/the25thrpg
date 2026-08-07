import 'dart:math';

const _masteryWeight = 0.25;

// ── Mindfulness tuning ────────────────────────────────────────────────────────

/// Meditation minutes for level 100. Sessions run ~6 min, so the old 10,000
/// target was unreachable and kept the skill pinned at a low level.
const _mindfulnessTargetMinutes = 2000;

/// Meditation minutes per mastery point beyond the target.
const _mindfulnessMasteryStep = 200;

/// Clean (addiction-free) days needed per level point.
const _cleanDaysPerLevelPoint = 10;

/// Ceiling on the sobriety bonus, so discipline is worth a lot but meditation
/// still carries most of the skill.
const _maxCleanDayBonus = 30.0;

// ── Resolve tuning ────────────────────────────────────────────────────────────

/// Completed-quest XP for level 100. At 1,000 XP for a legendary quest this is
/// roughly twenty of the hardest things you will ever commit to.
const _resolveTargetXp = 20000;

/// Quest XP per mastery point beyond the target.
const _resolveMasteryStep = 2000;

enum SkillId {
  japanese,
  wealth,
  mindfulness,
  resolve,
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
      case SkillId.resolve:
        return 'RESOLVE';
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
      case SkillId.resolve:
        return 'Sworn Oaths';
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
      case SkillId.resolve:
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
  final int last7DaysMinutes;

  /// Minutes per day over the last 7 days, oldest first — the sparkline.
  final List<int> dailyMinutesLast7;

  // ── Mindfulness: sobriety tracking ────────────────────────────────────────

  /// Consecutive clean days ending today (or yesterday if today is unlogged).
  final int cleanStreak;

  /// Longest clean streak ever logged.
  final int longestCleanStreak;

  /// Days logged clean, and days logged as a relapse.
  final int cleanDays;
  final int relapseDays;

  /// Days since the most recent sobriety entry. Null when nothing is logged.
  final int? daysSinceLastCleanLog;

  /// Last 14 days, oldest first: true clean, false relapse, null unlogged.
  final List<bool?> last14CleanDays;

  // ── Resolve: quests ───────────────────────────────────────────────────────

  /// Total XP from completed quests.
  final int questXp;

  /// How many quests are finished and still open, for the skill row subtitle.
  final int questsCompleted;
  final int questsActive;

  // ── Wealth: current net worth (€) ─────────────────────────────────────────
  final double currentNetWorthEur;

  /// Average monthly net-worth growth derived from all wealth snapshots.
  /// Null when fewer than 2 snapshots exist.
  final double? monthlyGrowthEur;

  const SkillSummary({
    required this.skill,
    this.lifetimeMinutes = 0,
    this.last30DaysMinutes = 0,
    this.last7DaysMinutes = 0,
    this.dailyMinutesLast7 = const [],
    this.cleanStreak = 0,
    this.longestCleanStreak = 0,
    this.cleanDays = 0,
    this.relapseDays = 0,
    this.daysSinceLastCleanLog,
    this.last14CleanDays = const [],
    this.questXp = 0,
    this.questsCompleted = 0,
    this.questsActive = 0,
    this.currentNetWorthEur = 0.0,
    this.monthlyGrowthEur,
  });

  double get _hours => lifetimeMinutes / 60.0;

  bool get isActive {
    switch (skill) {
      case SkillId.wealth:
        return currentNetWorthEur > 0;
      case SkillId.resolve:
        return questsActive > 0;
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
        // Sqrt on meditation minutes, plus a bonus for clean days.
        // 2,000 min (~33h) → 100, +1 level per 10 clean days (max +30).
        final base = sqrt(lifetimeMinutes.toDouble()) /
            sqrt(_mindfulnessTargetMinutes) *
            100;
        return base + cleanDayBonus;

      case SkillId.resolve:
        // Sqrt on completed-quest XP. 20,000 XP → 100.
        return sqrt(questXp.toDouble()) / sqrt(_resolveTargetXp) * 100;
    }
  }

  /// Level points earned from staying clean. Mindfulness only.
  double get cleanDayBonus {
    if (skill != SkillId.mindfulness) return 0;
    final bonus = cleanDays / _cleanDaysPerLevelPoint;
    return bonus.clamp(0.0, _maxCleanDayBonus);
  }

  /// Clean days that buy one level point, and the ceiling on that bonus —
  /// exposed so the UI can explain the rule without restating the numbers.
  static const cleanDaysPerLevelPoint = _cleanDaysPerLevelPoint;
  static const maxCleanDayBonus = _maxCleanDayBonus;

  /// Clean days still needed for the next +1 level from discipline.
  /// Null when the bonus is capped or the skill has no sobriety component.
  int? get cleanDaysToNextBonus {
    if (skill != SkillId.mindfulness) return null;
    if (cleanDayBonus >= _maxCleanDayBonus) return null;
    return _cleanDaysPerLevelPoint - (cleanDays % _cleanDaysPerLevelPoint);
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
        // Mastery tracks meditation only — the clean-day bonus does not count.
        if (lifetimeMinutes <= _mindfulnessTargetMinutes) return 0;
        return ((lifetimeMinutes - _mindfulnessTargetMinutes) /
                _mindfulnessMasteryStep)
            .floor();

      case SkillId.resolve:
        if (questXp <= _resolveTargetXp) return 0;
        return ((questXp - _resolveTargetXp) / _resolveMasteryStep).floor();
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
        // Clean days already cover part of the target level.
        final fromMeditation = (targetLevel - cleanDayBonus).clamp(0.0, 100.0);
        final neededMin =
            pow(fromMeditation / 100.0, 2) * _mindfulnessTargetMinutes;
        return _fmtTime((neededMin - lifetimeMinutes) / 60.0);

      case SkillId.resolve:
        final needed = pow(targetLevel / 100.0, 2) * _resolveTargetXp;
        return '${(needed - questXp).ceil()} XP';
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
        final excessMin = lifetimeMinutes - _mindfulnessTargetMinutes;
        return _fmtTime(
          (_mindfulnessMasteryStep - (excessMin % _mindfulnessMasteryStep)) /
              60.0,
        );
      case SkillId.resolve:
        final excessXp = questXp - _resolveTargetXp;
        return '${_resolveMasteryStep - (excessXp % _resolveMasteryStep)} XP';
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
      return '€${(amount / 1_000_000).toStringAsFixed(1)}M';
    }
    if (amount >= 1_000) {
      return '€${(amount / 1_000).toStringAsFixed(1)}k';
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
        if (lifetimeMinutes <= _mindfulnessTargetMinutes) return 0.0;
        return ((lifetimeMinutes - _mindfulnessTargetMinutes) %
                _mindfulnessMasteryStep) /
            _mindfulnessMasteryStep;
      case SkillId.resolve:
        if (questXp <= _resolveTargetXp) return 0.0;
        return ((questXp - _resolveTargetXp) % _resolveMasteryStep) /
            _resolveMasteryStep;
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
        final needed = _mindfulnessTargetMinutes +
            targetMastery * _mindfulnessMasteryStep.toDouble();
        return _fmtTime((needed - lifetimeMinutes) / 60.0);
      case SkillId.resolve:
        final needed = _resolveTargetXp + targetMastery * _resolveMasteryStep;
        return '${needed - questXp} XP';
    }
  }

  // ── Recent pace (time-based skills only) ──────────────────────────────────

  /// Average minutes per day over the last 7 days.
  double get avg7PerDay => last7DaysMinutes / 7.0;

  /// Average minutes per day over the last 30 days.
  double get avg30PerDay => last30DaysMinutes / 30.0;

  /// How much the last week beats (or trails) the last month, in min/day.
  /// Positive = speeding up, negative = slowing down.
  double get paceDeltaPerDay => avg7PerDay - avg30PerDay;

  /// True when there is not enough recent data to call a trend either way.
  bool get hasPaceData => last30DaysMinutes > 0 || last7DaysMinutes > 0;

  // ── Sobriety ──────────────────────────────────────────────────────────────

  /// Days with a sobriety entry (clean or relapse).
  int get loggedCleanDays => cleanDays + relapseDays;

  /// Share of logged days that stayed clean (0–1).
  double get cleanRate =>
      loggedCleanDays == 0 ? 0.0 : cleanDays / loggedCleanDays;

  /// True when logging has lapsed, so a zero streak means "unknown" rather
  /// than "you relapsed".
  bool get isCleanLogStale => (daysSinceLastCleanLog ?? 0) > 1;

  // ── ETA to the next level ─────────────────────────────────────────────────

  /// The level being worked toward. Caps at 101 (first mastery point).
  int get nextLevel => (_rawLevel.floor() + 1).clamp(2, 101);

  /// Practice minutes still needed for [nextLevel].
  /// Null for wealth (measured in €) and once the skill is maxed.
  double? get minutesToNextLevel {
    final raw = _rawLevel;
    if (raw >= 100) return null;
    final target = raw.floor() + 1;

    switch (skill) {
      case SkillId.wealth:
      case SkillId.resolve:
        return null;

      case SkillId.japanese:
        final neededHours = pow(target / 100.0, 2) * 2200;
        return max(0.0, (neededHours - _hours) * 60);

      case SkillId.mindfulness:
        // Clean days already cover part of the target level.
        final fromMeditation = (target - cleanDayBonus).clamp(0.0, 100.0);
        final neededMin =
            pow(fromMeditation / 100.0, 2) * _mindfulnessTargetMinutes;
        return max(0.0, (neededMin - lifetimeMinutes).toDouble());
    }
  }

  /// Days until [nextLevel] at the last-30-day pace.
  /// Null when the skill is maxed, measured in €, or has no recent pace.
  int? get daysToNextLevel {
    final remaining = minutesToNextLevel;
    if (remaining == null || remaining <= 0) return null;
    final pace = avg30PerDay;
    if (pace <= 0) return null;
    return (remaining / pace).ceil();
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
