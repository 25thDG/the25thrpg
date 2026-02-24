import 'wealth_snapshot.dart';

class WealthStats {
  /// Net worth from the most recent non-deleted snapshot.
  /// Null when no snapshots exist.
  final double? currentNetWorth;

  /// currentNetWorth / 1_000_000, clamped to [0, 1].
  /// Computed dynamically — never stored.
  final double radarProgress;

  /// Highest net worth ever recorded across all snapshots.
  /// Null when no snapshots exist.
  final double? highestNetWorthEver;

  /// All non-deleted snapshots, sorted ascending by snapshot_month.
  final List<WealthSnapshot> monthlyHistory;

  /// The snapshot for the current calendar month, if one exists.
  /// Used by the UI to determine add vs. edit mode.
  final WealthSnapshot? currentMonthSnapshot;

  const WealthStats({
    required this.currentNetWorth,
    required this.radarProgress,
    required this.highestNetWorthEver,
    required this.monthlyHistory,
    required this.currentMonthSnapshot,
  });

  bool get hasData => monthlyHistory.isNotEmpty;
}
