class CarContract {
  final String id;

  /// Handover day. Contract years run from this date to its anniversaries,
  /// not from January.
  final DateTime startDate;
  final int startOdometerKm;
  final int termYears;
  final int yearlyAllowanceKm;

  /// The yearly figure that must never be crossed.
  final int yearlyHardLimitKm;

  const CarContract({
    required this.id,
    required this.startDate,
    required this.startOdometerKm,
    required this.termYears,
    required this.yearlyAllowanceKm,
    required this.yearlyHardLimitKm,
  });

  int get termAllowanceKm => yearlyAllowanceKm * termYears;
  int get termHardLimitKm => yearlyHardLimitKm * termYears;

  /// First day of contract year [year] (1-based). `termYears + 1` is the day
  /// the contract ends.
  DateTime yearStart(int year) =>
      DateTime(startDate.year + year - 1, startDate.month, startDate.day);

  /// The contract year [day] falls in, held to the last one after the term.
  int yearOf(DateTime day) {
    for (var year = 1; year < termYears; year++) {
      if (day.isBefore(yearStart(year + 1))) return year;
    }
    return termYears;
  }
}
