import 'dart:math' show max, min;

import 'car_contract.dart';
import 'car_snapshot.dart';

/// How the current contract year is heading, mildest first.
enum CarPaceStatus {
  /// The year-to-date pace finishes the year inside the allowance.
  onTrack,

  /// On pace to finish over the allowance, or already over it.
  overAllowance,

  /// On pace to finish over the hard limit, or already over it.
  overHardLimit,
}

/// Where one yearly limit stands as of the latest snapshot.
class CarLimitOutlook {
  final int limitKm;

  /// Negative once the limit is crossed.
  final double remainingKm;

  /// The most that can be driven per day from here and still finish the
  /// contract year under the limit. Zero once it is crossed.
  final double maxKmPerDay;

  /// The day the limit is reached at the year-to-date pace. Null when that
  /// pace keeps it out of this contract year, and when it is already crossed.
  final DateTime? reachedOn;

  /// Days from the latest snapshot to [reachedOn].
  final int? reachedInDays;

  const CarLimitOutlook({
    required this.limitKm,
    required this.remainingKm,
    required this.maxKmPerDay,
    required this.reachedOn,
    required this.reachedInDays,
  });

  bool get isExceeded => remainingKm < 0;
  double get overshootKm => isExceeded ? -remainingKm : 0;
}

class CarHistoryEntry {
  final CarSnapshot snapshot;

  /// Measured from the snapshot before it, or from handover for the first.
  final int kmSincePrevious;
  final int daysSincePrevious;

  const CarHistoryEntry({
    required this.snapshot,
    required this.kmSincePrevious,
    required this.daysSincePrevious,
  });

  /// Null when both readings are from the same day.
  double? get kmPerDay =>
      daysSincePrevious > 0 ? kmSincePrevious / daysSincePrevious : null;
}

/// One point on the current contract year's cumulative line.
class CarYearPoint {
  /// Days since the contract year began.
  final int day;

  /// Km driven in the contract year by then.
  final double km;

  const CarYearPoint({required this.day, required this.km});
}

/// Everything the Car tab shows, derived from the contract and the snapshots.
///
/// Every figure is measured as of the latest snapshot's date, not today —
/// otherwise days without a snapshot would count as days without driving.
class CarStats {
  final CarContract contract;

  /// Active snapshots, oldest first.
  final List<CarSnapshot> snapshots;

  /// Date of the latest snapshot; handover day while nothing is logged.
  final DateTime asOf;
  final int odometerKm;

  // ── Current contract year ────────────────────────────────────────────────

  /// 1-based.
  final int contractYear;
  final DateTime yearStart;
  final DateTime yearEnd;
  final int yearDays;
  final int daysElapsed;
  final int daysLeft;
  final double drivenKm;

  /// Where an even run at the allowance would stand on [asOf].
  final double evenPaceKm;

  /// Null until at least one day of the contract year has passed.
  final double? avgKmPerDay;

  /// Over the 30 days up to [asOf], or since handover if that is shorter.
  final double? last30KmPerDay;

  /// Year-end total if the year-to-date average holds.
  final double? projectedYearEndKm;

  final CarLimitOutlook allowance;
  final CarLimitOutlook hardLimit;
  final CarPaceStatus status;

  /// Starts at day 0 / 0 km, then one point per snapshot in this year.
  final List<CarYearPoint> yearPoints;

  // ── Whole term ───────────────────────────────────────────────────────────

  /// Km since handover.
  final int termKm;

  /// Newest first.
  final List<CarHistoryEntry> history;

  const CarStats._({
    required this.contract,
    required this.snapshots,
    required this.asOf,
    required this.odometerKm,
    required this.contractYear,
    required this.yearStart,
    required this.yearEnd,
    required this.yearDays,
    required this.daysElapsed,
    required this.daysLeft,
    required this.drivenKm,
    required this.evenPaceKm,
    required this.avgKmPerDay,
    required this.last30KmPerDay,
    required this.projectedYearEndKm,
    required this.allowance,
    required this.hardLimit,
    required this.status,
    required this.yearPoints,
    required this.termKm,
    required this.history,
  });

  factory CarStats.compute({
    required CarContract contract,
    required List<CarSnapshot> snapshots,
  }) {
    final sorted = [...snapshots]
      ..sort((a, b) => a.snapshotDate.compareTo(b.snapshotDate));

    // Handover is the zeroth reading, so one snapshot already gives a pace.
    final readings = [
      _Reading(contract.startDate, contract.startOdometerKm),
      for (final s in sorted) _Reading(s.snapshotDate, s.odometerKm, s),
    ];
    final latest = readings.last;
    final asOf = latest.date;

    final year = contract.yearOf(asOf);
    final yearStart = contract.yearStart(year);
    final yearEnd = contract.yearStart(year + 1);
    final yearDays = _daysBetween(yearStart, yearEnd);
    final daysElapsed = _daysBetween(yearStart, asOf);
    // Zero only once the term has run out.
    final daysLeft = max(0, _daysBetween(asOf, yearEnd));

    // Years 2 and 3 count from the odometer on the anniversary, which is
    // rarely a day with a snapshot — read it off the line between the two
    // snapshots around it.
    final yearStartKm = _odometerAt(readings, yearStart);
    final driven = latest.km - yearStartKm;

    final avg = daysElapsed > 0 ? driven / daysElapsed : null;

    final windowStart = _later(
      DateTime(asOf.year, asOf.month, asOf.day - 30),
      contract.startDate,
    );
    final windowDays = _daysBetween(windowStart, asOf);
    final last30 = windowDays > 0
        ? (latest.km - _odometerAt(readings, windowStart)) / windowDays
        : null;

    final projected = avg == null ? null : driven + avg * daysLeft;

    CarLimitOutlook outlook(int limitKm) {
      final remaining = limitKm - driven;
      final reaches = remaining > 0 &&
          avg != null &&
          avg > 0 &&
          driven + avg * daysLeft > limitKm;
      final inDays = reaches ? (remaining / avg).ceil() : null;
      return CarLimitOutlook(
        limitKm: limitKm,
        remainingKm: remaining,
        maxKmPerDay: remaining <= 0 || daysLeft == 0 ? 0 : remaining / daysLeft,
        reachedOn: inDays == null
            ? null
            : DateTime(asOf.year, asOf.month, asOf.day + inDays),
        reachedInDays: inDays,
      );
    }

    // Already-driven km can only push the outlook up, so this also covers a
    // limit that is crossed outright.
    final outlookKm = projected ?? driven;
    final status = outlookKm > contract.yearlyHardLimitKm
        ? CarPaceStatus.overHardLimit
        : outlookKm > contract.yearlyAllowanceKm
            ? CarPaceStatus.overAllowance
            : CarPaceStatus.onTrack;

    return CarStats._(
      contract: contract,
      snapshots: sorted,
      asOf: asOf,
      odometerKm: latest.km,
      contractYear: year,
      yearStart: yearStart,
      yearEnd: yearEnd,
      yearDays: yearDays,
      daysElapsed: daysElapsed,
      daysLeft: daysLeft,
      drivenKm: driven,
      evenPaceKm:
          contract.yearlyAllowanceKm * min(daysElapsed, yearDays) / yearDays,
      avgKmPerDay: avg,
      last30KmPerDay: last30,
      projectedYearEndKm: projected,
      allowance: outlook(contract.yearlyAllowanceKm),
      hardLimit: outlook(contract.yearlyHardLimitKm),
      status: status,
      yearPoints: [
        const CarYearPoint(day: 0, km: 0),
        for (final r in readings)
          if (r.date.isAfter(yearStart))
            CarYearPoint(
              day: _daysBetween(yearStart, r.date),
              km: r.km - yearStartKm,
            ),
      ],
      termKm: latest.km - contract.startOdometerKm,
      history: [
        for (var i = readings.length - 1; i >= 1; i--)
          CarHistoryEntry(
            snapshot: readings[i].snapshot!,
            kmSincePrevious: readings[i].km - readings[i - 1].km,
            daysSincePrevious:
                _daysBetween(readings[i - 1].date, readings[i].date),
          ),
      ],
    );
  }

  bool get hasSnapshots => snapshots.isNotEmpty;

  /// Positive when more has been driven than an even pace allows.
  double get aheadOfEvenPaceKm => drivenKm - evenPaceKm;

  /// The snapshot logged on [day], if there is one.
  CarSnapshot? snapshotOn(DateTime day) {
    for (final s in snapshots) {
      if (_daysBetween(s.snapshotDate, day) == 0) return s;
    }
    return null;
  }

  /// The lowest value a snapshot on [day] may carry: the reading just before
  /// it. An odometer only goes up, so anything lower is a typo.
  int odometerFloorOn(DateTime day) {
    var floor = contract.startOdometerKm;
    for (final s in snapshots) {
      if (_daysBetween(s.snapshotDate, day) > 0) floor = s.odometerKm;
    }
    return floor;
  }
}

class _Reading {
  final DateTime date;
  final int km;

  /// Null for the handover reading.
  final CarSnapshot? snapshot;

  const _Reading(this.date, this.km, [this.snapshot]);
}

/// Whole calendar days from [from] to [to]. Counted in UTC so a daylight
/// saving switch in between cannot drop or add a day.
int _daysBetween(DateTime from, DateTime to) => DateTime.utc(to.year, to.month, to.day)
    .difference(DateTime.utc(from.year, from.month, from.day))
    .inDays;

DateTime _later(DateTime a, DateTime b) => a.isAfter(b) ? a : b;

/// Odometer on [day], linear between the readings either side of it.
/// [readings] is sorted oldest first.
double _odometerAt(List<_Reading> readings, DateTime day) {
  if (!day.isAfter(readings.first.date)) return readings.first.km.toDouble();

  for (var i = 1; i < readings.length; i++) {
    final after = readings[i];
    if (after.date.isBefore(day)) continue;

    final before = readings[i - 1];
    final span = _daysBetween(before.date, after.date);
    if (span == 0) return after.km.toDouble();
    return before.km +
        (after.km - before.km) * _daysBetween(before.date, day) / span;
  }
  return readings.last.km.toDouble();
}
