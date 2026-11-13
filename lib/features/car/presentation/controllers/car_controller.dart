import 'package:flutter/foundation.dart';

import '../../application/use_cases/delete_car_snapshot_use_case.dart';
import '../../application/use_cases/get_car_stats_use_case.dart';
import '../../application/use_cases/save_car_snapshot_use_case.dart';
import '../state/car_state.dart';

class CarController extends ChangeNotifier {
  final GetCarStatsUseCase _getStats;
  final SaveCarSnapshotUseCase _save;
  final DeleteCarSnapshotUseCase _delete;

  CarState _state = CarState.initial();
  CarState get state => _state;

  CarController({
    required GetCarStatsUseCase getStats,
    required SaveCarSnapshotUseCase save,
    required DeleteCarSnapshotUseCase delete,
  })  : _getStats = getStats,
        _save = save,
        _delete = delete;

  void _emit(CarState next) {
    _state = next;
    notifyListeners();
  }

  Future<void> load() async {
    _emit(_state.copyWith(status: CarLoadStatus.loading, isMutating: false));
    try {
      final stats = await _getStats.execute();
      _emit(_state.copyWith(status: CarLoadStatus.loaded, stats: stats));
    } catch (e) {
      _emit(_state.copyWith(
        status: CarLoadStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  /// Returns an error message on failure, null on success.
  Future<String?> saveSnapshot(int odometerKm) async {
    _emit(_state.copyWith(isMutating: true));
    try {
      await _save.execute(odometerKm: odometerKm);
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
