import 'package:flutter/foundation.dart';

import '../../../../core/progression/level_watcher.dart';
import '../../application/use_cases/get_activity_history_use_case.dart';
import '../../application/use_cases/get_player_stats_use_case.dart';
import '../state/player_state.dart';

class PlayerController extends ChangeNotifier {
  final GetPlayerStatsUseCase _getPlayerStats;
  final GetActivityHistoryUseCase _getActivityHistory;

  PlayerState _state = const PlayerState();
  PlayerState get state => _state;

  PlayerController({
    required GetPlayerStatsUseCase getPlayerStats,
    required GetActivityHistoryUseCase getActivityHistory,
  })  : _getPlayerStats = getPlayerStats,
        _getActivityHistory = getActivityHistory;

  void _emit(PlayerState s) {
    _state = s;
    notifyListeners();
  }

  Future<void> load() async {
    _emit(_state.copyWith(status: PlayerLoadStatus.loading));
    try {
      final (stats, history) = await (
        _getPlayerStats(),
        _getActivityHistory(),
      ).wait;

      // Compare against the levels last seen before anything is drawn, so a
      // gain is caught the first time the new number reaches the screen.
      final levelUps = await LevelWatcher.instance.check(stats);

      _emit(
        _state.copyWith(
          status: PlayerLoadStatus.loaded,
          stats: stats,
          history: history,
          pendingLevelUps: levelUps,
        ),
      );
    } catch (e) {
      _emit(
        _state.copyWith(
          status: PlayerLoadStatus.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  /// Called once the celebration has been shown, so a rebuild does not repeat
  /// it.
  void clearLevelUps() {
    if (_state.pendingLevelUps.isEmpty) return;
    _emit(_state.copyWith(pendingLevelUps: const []));
  }
}
