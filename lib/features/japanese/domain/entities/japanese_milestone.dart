import 'dart:math';

/// A lifetime-hours target worth counting down to — the next trip, an exam.
class JapaneseMilestone {
  final int targetHours;

  /// What reaching it unlocks, shown on the card.
  final String label;

  const JapaneseMilestone({required this.targetHours, required this.label});

  static const fallback = JapaneseMilestone(targetHours: 700, label: 'Japan');
}

/// How far off a [JapaneseMilestone] is if the last week's pace holds.
class MilestoneForecast {
  final JapaneseMilestone milestone;
  final double lifetimeHours;

  /// Hours logged in the last 7 days, backfill excluded.
  final double hoursPerWeek;

  const MilestoneForecast({
    required this.milestone,
    required this.lifetimeHours,
    required this.hoursPerWeek,
  });

  bool get isReached => lifetimeHours >= milestone.targetHours;

  double get remainingHours =>
      max(0.0, milestone.targetHours - lifetimeHours);

  double get progress =>
      (lifetimeHours / milestone.targetHours).clamp(0.0, 1.0);

  /// Days until the target at the current weekly pace.
  /// Null when nothing was logged this week — there is no pace to project.
  int? get daysLeft {
    if (isReached) return 0;
    if (hoursPerWeek <= 0) return null;
    return (remainingHours / (hoursPerWeek / 7)).ceil();
  }

  /// The day the target lands, counted from [today].
  DateTime? etaFrom(DateTime today) {
    final days = daysLeft;
    if (days == null) return null;
    return DateTime(today.year, today.month, today.day + days);
  }
}
