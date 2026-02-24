import 'package:flutter/foundation.dart';

import '../../application/use_cases/get_player_stats_use_case.dart';
import '../state/player_state.dart';

class PlayerController extends ChangeNotifier {
  final GetPlayerStatsUseCase _getPlayerStats;

  PlayerState _state = const PlayerState();
  PlayerState get state => _state;

  PlayerController({required GetPlayerStatsUseCase getPlayerStats})
      : _getPlayerStats = getPlayerStats;

  void _emit(PlayerState s) {
    _state = s;
    notifyListeners();
  }

  Future<void> load() async {
    _emit(_state.copyWith(status: PlayerLoadStatus.loading));
    try {
      final stats = await _getPlayerStats();
      _emit(_state.copyWith(status: PlayerLoadStatus.loaded, stats: stats));
    } catch (e) {
      _emit(
        _state.copyWith(
          status: PlayerLoadStatus.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }
}
