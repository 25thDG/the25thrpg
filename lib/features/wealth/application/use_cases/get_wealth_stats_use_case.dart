import 'dart:math' show max;

import '../../domain/entities/wealth_snapshot.dart';
import '../../domain/entities/wealth_stats.dart';
import '../../domain/repositories/wealth_repository.dart';

const _goalEur = 1_000_000.0;

class GetWealthStatsUseCase {
  final WealthRepository _repository;

  const GetWealthStatsUseCase(this._repository);

  Future<WealthStats> execute() async {
    final snapshots = await _repository.getAllActiveSnapshots();
    return _compute(snapshots);
  }

  WealthStats _compute(List<WealthSnapshot> snapshots) {
    if (snapshots.isEmpty) {
      return const WealthStats(
        currentNetWorth: null,
        radarProgress: 0.0,
        highestNetWorthEver: null,
        monthlyHistory: [],
        currentMonthSnapshot: null,
      );
    }

    // snapshots arrive sorted ascending — most recent is last.
    final currentNetWorth = snapshots.last.netWorthEur;

    // Radar: computed dynamically, never stored.
    final radarProgress = (currentNetWorth / _goalEur).clamp(0.0, 1.0);

    // All-time high.
    final highestNetWorthEver =
        snapshots.map((s) => s.netWorthEur).reduce(max);

    // Current month snapshot (for add vs. edit mode in UI).
    final now = DateTime.now();
    final currentMonthSnapshot = snapshots
        .where(
          (s) =>
              s.snapshotMonth.year == now.year &&
              s.snapshotMonth.month == now.month,
        )
        .fold<WealthSnapshot?>(null, (_, s) => s);

    return WealthStats(
      currentNetWorth: currentNetWorth,
      radarProgress: radarProgress,
      highestNetWorthEver: highestNetWorthEver,
      monthlyHistory: snapshots, // already sorted ascending
      currentMonthSnapshot: currentMonthSnapshot,
    );
  }
}
