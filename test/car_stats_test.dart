import 'package:flutter_test/flutter_test.dart';
import 'package:the25thrpg/features/car/domain/entities/car_contract.dart';
import 'package:the25thrpg/features/car/domain/entities/car_snapshot.dart';
import 'package:the25thrpg/features/car/domain/entities/car_stats.dart';

CarContract _contract({int startOdometerKm = 23}) => CarContract(
      id: 'c1',
      startDate: DateTime(2026, 10, 1),
      startOdometerKm: startOdometerKm,
      termYears: 3,
      yearlyAllowanceKm: 12500,
      yearlyHardLimitKm: 15000,
    );

CarSnapshot _snap(int year, int month, int day, int km) {
  final date = DateTime(year, month, day);
  return CarSnapshot(
    id: '$year-$month-$day',
    odometerKm: km,
    snapshotDate: date,
    createdAt: date,
    updatedAt: date,
  );
}

/// The readings written down before the app existed.
List<CarSnapshot> _seeded() => [
      _snap(2026, 10, 12, 1489),
      _snap(2026, 10, 13, 1637),
      _snap(2026, 10, 14, 1644),
      _snap(2026, 10, 15, 1679),
      _snap(2026, 10, 17, 1870),
      _snap(2026, 10, 18, 2002),
      _snap(2026, 10, 20, 2070),
      _snap(2026, 10, 23, 2222),
      _snap(2026, 11, 12, 3700),
    ];

CarStats _stats(List<CarSnapshot> snapshots, {CarContract? contract}) =>
    CarStats.compute(contract: contract ?? _contract(), snapshots: snapshots);

void main() {
  group('seeded snapshots', () {
    final s = _stats(_seeded());

    test('everything is measured as of the latest snapshot', () {
      expect(s.asOf, DateTime(2026, 11, 12));
      expect(s.odometerKm, 3700);
    });

    test('sits in the first contract year, handover to anniversary', () {
      expect(s.contractYear, 1);
      expect(s.yearStart, DateTime(2026, 10, 1));
      expect(s.yearEnd, DateTime(2027, 10, 1));
      expect(s.yearDays, 365);
      expect(s.daysElapsed, 42);
      expect(s.daysLeft, 323);
    });

    test('driven km count from the handover odometer, not from zero', () {
      expect(s.drivenKm, 3677);
      expect(s.termKm, 3677);
    });

    test('pace is the year-to-date average and the last 30 days', () {
      expect(s.avgKmPerDay, closeTo(3677 / 42, 1e-9));
      // 13 Oct read 1,637 km.
      expect(s.last30KmPerDay, closeTo((3700 - 1637) / 30, 1e-9));
    });

    test('even pace is the allowance spread over the year', () {
      expect(s.evenPaceKm, closeTo(12500 * 42 / 365, 1e-9));
      expect(s.aheadOfEvenPaceKm, closeTo(3677 - 12500 * 42 / 365, 1e-9));
    });

    test('max km per day spreads what is left over the days left', () {
      expect(s.allowance.remainingKm, 8823);
      expect(s.allowance.maxKmPerDay, closeTo(8823 / 323, 1e-9));
      expect(s.hardLimit.remainingKm, 11323);
      expect(s.hardLimit.maxKmPerDay, closeTo(11323 / 323, 1e-9));
    });

    test('projects the year end and both limit dates at the average pace', () {
      expect(s.projectedYearEndKm, closeTo(3677 + 3677 / 42 * 323, 1e-6));
      // 8,823 km at 87.5 km/day is 100.8 days; 11,323 km is 129.3.
      expect(s.allowance.reachedOn, DateTime(2027, 2, 21));
      expect(s.hardLimit.reachedOn, DateTime(2027, 3, 22));
    });

    test('roughly double the allowed pace reads as over the hard limit', () {
      expect(s.status, CarPaceStatus.overHardLimit);
      expect(s.allowance.isExceeded, isFalse);
      expect(s.hardLimit.isExceeded, isFalse);
    });

    test('history is newest first with the gap to the reading before', () {
      expect(s.history, hasLength(9));

      final newest = s.history.first;
      expect(newest.snapshot.odometerKm, 3700);
      expect(newest.kmSincePrevious, 1478);
      expect(newest.daysSincePrevious, 20);
      expect(newest.kmPerDay, closeTo(73.9, 1e-9));

      // The first snapshot is measured from handover.
      final oldest = s.history.last;
      expect(oldest.snapshot.odometerKm, 1489);
      expect(oldest.kmSincePrevious, 1466);
      expect(oldest.daysSincePrevious, 11);
    });

    test('the year line starts at zero and ends on the latest snapshot', () {
      expect(s.yearPoints, hasLength(10));
      expect(s.yearPoints.first.day, 0);
      expect(s.yearPoints.first.km, 0);
      expect(s.yearPoints.last.day, 42);
      expect(s.yearPoints.last.km, 3677);
    });

    test('snapshots arriving out of order give the same result', () {
      final shuffled = _stats(_seeded().reversed.toList());
      expect(shuffled.asOf, s.asOf);
      expect(shuffled.drivenKm, s.drivenKm);
      expect(shuffled.history.first.kmSincePrevious, 1478);
    });
  });

  group('pace status', () {
    // 9 Jan 2027 is day 100 of the contract year.
    test('a pace that ends under the allowance is on track', () {
      final s = _stats([_snap(2027, 1, 9, 3023)]);
      expect(s.daysElapsed, 100);
      expect(s.projectedYearEndKm, closeTo(10950, 1e-6));
      expect(s.status, CarPaceStatus.onTrack);
      expect(s.allowance.reachedOn, isNull);
      expect(s.hardLimit.reachedOn, isNull);
    });

    test('a pace that ends between the limits is over the allowance only', () {
      final s = _stats([_snap(2027, 1, 9, 3823)]);
      expect(s.projectedYearEndKm, closeTo(13870, 1e-6));
      expect(s.status, CarPaceStatus.overAllowance);
      expect(s.allowance.reachedOn, isNotNull);
      // 15,000 stays out of reach this year.
      expect(s.hardLimit.reachedOn, isNull);
    });
  });

  group('limit already exceeded', () {
    test('over the allowance: nothing left per day, overshoot reported', () {
      final s = _stats(
        [_snap(2027, 6, 1, 13000)],
        contract: _contract(startOdometerKm: 0),
      );

      expect(s.allowance.isExceeded, isTrue);
      expect(s.allowance.overshootKm, 500);
      expect(s.allowance.maxKmPerDay, 0);
      expect(s.allowance.reachedOn, isNull);

      // The hard limit is still ahead: 2,000 km over the 122 days left.
      expect(s.hardLimit.isExceeded, isFalse);
      expect(s.hardLimit.overshootKm, 0);
      expect(s.hardLimit.maxKmPerDay, closeTo(2000 / 122, 1e-9));
      expect(s.hardLimit.reachedOn, DateTime(2027, 7, 9));
      expect(s.status, CarPaceStatus.overHardLimit);
    });

    test('over the hard limit', () {
      final s = _stats(
        [_snap(2027, 8, 1, 15400)],
        contract: _contract(startOdometerKm: 0),
      );

      expect(s.hardLimit.isExceeded, isTrue);
      expect(s.hardLimit.overshootKm, 400);
      expect(s.hardLimit.maxKmPerDay, 0);
      expect(s.status, CarPaceStatus.overHardLimit);
    });

    test('exactly on the limit is not over it, but leaves nothing', () {
      final s = _stats(
        [_snap(2027, 8, 1, 12500)],
        contract: _contract(startOdometerKm: 0),
      );

      expect(s.allowance.isExceeded, isFalse);
      expect(s.allowance.maxKmPerDay, 0);
    });
  });

  group('second contract year', () {
    // No snapshot on the 1 Oct 2027 anniversary: 11,023 km ten days before,
    // 12,023 km ten days after.
    final s = _stats([
      _snap(2027, 9, 21, 11023),
      _snap(2027, 10, 11, 12023),
    ]);

    test('rolls over on the handover anniversary', () {
      expect(s.contractYear, 2);
      expect(s.yearStart, DateTime(2027, 10, 1));
      expect(s.yearEnd, DateTime(2028, 10, 1));
      // 2028 is a leap year.
      expect(s.yearDays, 366);
      expect(s.daysElapsed, 10);
      expect(s.daysLeft, 356);
    });

    test('counts from the odometer interpolated at the anniversary', () {
      // Halfway between the two snapshots: 11,523 km.
      expect(s.drivenKm, closeTo(500, 1e-9));
      expect(s.avgKmPerDay, closeTo(50, 1e-9));
      expect(s.allowance.remainingKm, closeTo(12000, 1e-9));
    });

    test('the year line restarts at zero', () {
      expect(s.yearPoints, hasLength(2));
      expect(s.yearPoints.first.km, 0);
      expect(s.yearPoints.last.day, 10);
      expect(s.yearPoints.last.km, closeTo(500, 1e-9));
    });

    test('the whole term still counts from handover', () {
      expect(s.termKm, 12000);
    });

    test('a snapshot on the anniversary itself is used as it is', () {
      final exact = _stats([
        _snap(2027, 10, 1, 11400),
        _snap(2027, 10, 11, 12023),
      ]);
      expect(exact.drivenKm, 623);
    });
  });

  group('sparse data', () {
    test('no snapshots: only the handover baseline', () {
      final s = _stats([]);

      expect(s.hasSnapshots, isFalse);
      expect(s.asOf, DateTime(2026, 10, 1));
      expect(s.odometerKm, 23);
      expect(s.drivenKm, 0);
      expect(s.daysElapsed, 0);
      expect(s.avgKmPerDay, isNull);
      expect(s.last30KmPerDay, isNull);
      expect(s.projectedYearEndKm, isNull);
      expect(s.status, CarPaceStatus.onTrack);
      expect(s.allowance.maxKmPerDay, closeTo(12500 / 365, 1e-9));
      expect(s.allowance.reachedOn, isNull);
      expect(s.history, isEmpty);
      expect(s.yearPoints, hasLength(1));
    });

    test('one snapshot is enough for a pace, measured from handover', () {
      final s = _stats([_snap(2026, 10, 12, 1489)]);

      expect(s.drivenKm, 1466);
      expect(s.avgKmPerDay, closeTo(1466 / 11, 1e-9));
      // Fewer than 30 days exist, so the window is the 11 there are.
      expect(s.last30KmPerDay, closeTo(1466 / 11, 1e-9));
      expect(s.history.single.kmSincePrevious, 1466);
    });

    test('a snapshot on handover day does not divide by zero', () {
      final s = _stats([_snap(2026, 10, 1, 30)]);

      expect(s.daysElapsed, 0);
      expect(s.drivenKm, 7);
      expect(s.avgKmPerDay, isNull);
      expect(s.projectedYearEndKm, isNull);
      expect(s.history.single.kmPerDay, isNull);
      expect(s.allowance.maxKmPerDay.isFinite, isTrue);
    });
  });

  group('logging', () {
    final s = _stats(_seeded());

    test('finds the snapshot already logged on a day', () {
      expect(s.snapshotOn(DateTime(2026, 11, 12))?.odometerKm, 3700);
      expect(s.snapshotOn(DateTime(2026, 11, 13)), isNull);
    });

    test('a new reading may not be lower than the one before it', () {
      expect(s.odometerFloorOn(DateTime(2026, 11, 13)), 3700);
    });

    test("replacing a day's reading is held to the day before, not itself", () {
      expect(s.odometerFloorOn(DateTime(2026, 11, 12)), 2222);
    });

    test('with nothing logged the floor is the handover odometer', () {
      expect(_stats([]).odometerFloorOn(DateTime(2026, 10, 2)), 23);
    });
  });
}
