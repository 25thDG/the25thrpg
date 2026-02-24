import 'package:flutter/foundation.dart';

import '../../application/use_cases/add_or_update_monthly_snapshot_use_case.dart';
import '../../application/use_cases/delete_wealth_snapshot_use_case.dart';
import '../../application/use_cases/get_wealth_stats_use_case.dart';
import '../state/wealth_state.dart';

class WealthController extends ChangeNotifier {
  final GetWealthStatsUseCase _getStats;
  final AddOrUpdateMonthlySnapshotUseCase _addOrUpdate;
  final DeleteWealthSnapshotUseCase _delete;

  WealthState _state = WealthState.initial();
  WealthState get state => _state;

  WealthController({
    required GetWealthStatsUseCase getStats,
    required AddOrUpdateMonthlySnapshotUseCase addOrUpdate,
    required DeleteWealthSnapshotUseCase delete,
  })  : _getStats = getStats,
        _addOrUpdate = addOrUpdate,
        _delete = delete;

  void _emit(WealthState next) {
    _state = next;
    notifyListeners();
  }

  Future<void> load() async {
    _emit(_state.copyWith(status: WealthLoadStatus.loading, isMutating: false));
    try {
      final stats = await _getStats.execute();
      _emit(_state.copyWith(status: WealthLoadStatus.loaded, stats: stats));
    } catch (e) {
      _emit(_state.copyWith(
        status: WealthLoadStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  /// Returns an error message on failure, null on success.
  Future<String?> saveSnapshot(double netWorthEur) async {
    _emit(_state.copyWith(isMutating: true));
    try {
      await _addOrUpdate.execute(netWorthEur: netWorthEur);
      await load();
      return null;
    } catch (e) {
      _emit(_state.copyWith(isMutating: false, errorMessage: e.toString()));
      return e.toString();
    }
  }

  /// Returns an error message on failure, null on success.
  Future<String?> deleteSnapshot(String id) async {
    _emit(_state.copyWith(isMutating: true));
    try {
      await _delete.execute(id);
      await load();
      return null;
    } catch (e) {
      _emit(_state.copyWith(isMutating: false, errorMessage: e.toString()));
      return e.toString();
    }
  }
}
