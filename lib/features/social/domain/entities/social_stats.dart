class SocialStats {
  final int lifetimeMinutes;
  final double lifetimeHours;
  final int lifetimeSelfInitiatedMinutes;
  final int lifetimeOtherInitiatedMinutes;
  final double lifetimeSelfInitiatedPercentage;

  final int last30DaysMinutes;
  final int last30DaysSelfInitiatedMinutes;
  final double last30DaysSelfInitiatedPercentage;

  final int best30DayMinutes;

  const SocialStats({
    required this.lifetimeMinutes,
    required this.lifetimeHours,
    required this.lifetimeSelfInitiatedMinutes,
    required this.lifetimeOtherInitiatedMinutes,
    required this.lifetimeSelfInitiatedPercentage,
    required this.last30DaysMinutes,
    required this.last30DaysSelfInitiatedMinutes,
    required this.last30DaysSelfInitiatedPercentage,
    required this.best30DayMinutes,
  });
}
