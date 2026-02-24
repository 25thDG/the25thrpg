import 'package:flutter/foundation.dart';

import '../../application/use_cases/add_sport_session_use_case.dart';
import '../../application/use_cases/delete_sport_session_use_case.dart';
import '../../application/use_cases/get_sport_stats_use_case.dart';
import '../../application/use_cases/get_today_sport_sessions_use_case.dart';
import '../../application/use_cases/update_sport_session_use_case.dart';
import '../../domain/entities/sport_session.dart';
import '../state/sport_state.dart';

class SportController extends ChangeNotifier {
  final GetSportStatsUseCase _getStats;
  final GetTodaySportSessionsUseCase _getTodaySessions;
  final AddSportSessionUseCase _addSession;
  final UpdateSportSessionUseCase _updateSession;
  final DeleteSportSessionUseCase _deleteSession;

  SportState _state = const SportState();
  SportState get state => _state;

  SportController({
    required GetSportStatsUseCase getStats,
    required GetTodaySportSessionsUseCase getTodaySessions,
    required AddSportSessionUseCase addSession,
    required UpdateSportSessionUseCase updateSession,
    required DeleteSportSessionUseCase deleteSession,
  }) : _getStats = getStats,
       _getTodaySessions = getTodaySessions,
       _addSession = addSession,
       _updateSession = updateSession,
       _deleteSession = deleteSession;

  void _emit(SportState s) {
    _state = s;
    notifyListeners();
  }

  Future<void> load() async {
    _emit(
      _state.copyWith(
        statsStatus: SportLoadStatus.loading,
        sessionsStatus: SportLoadStatus.loading,
        isMutating: false,
      ),
    );

    await Future.wait([_loadStats(), _loadTodaySessions()]);
  }

  Future<void> _loadStats() async {
    try {
      final stats = await _getStats();
      _emit(_state.copyWith(stats: stats, statsStatus: SportLoadStatus.loaded));
    } catch (e) {
      _emit(
        _state.copyWith(
          statsStatus: SportLoadStatus.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _loadTodaySessions() async {
    try {
      final sessions = await _getTodaySessions();
      _emit(
        _state.copyWith(
          todaySessions: sessions,
          sessionsStatus: SportLoadStatus.loaded,
        ),
      );
    } catch (_) {
      _emit(_state.copyWith(sessionsStatus: SportLoadStatus.error));
    }
  }

  Future<String?> addSession(SportCategory category, int minutes) async {
    _emit(_state.copyWith(isMutating: true));

    try {
      await _addSession(category: category, minutes: minutes);
      await load();
      return null;
    } catch (e) {
      _emit(_state.copyWith(isMutating: false));
      return e.toString();
    }
  }

  Future<String?> updateSession(String id, int minutes) async {
    _emit(_state.copyWith(isMutating: true));

    try {
      await _updateSession(id: id, minutes: minutes);
      await load();
      return null;
    } catch (e) {
      _emit(_state.copyWith(isMutating: false));
      return e.toString();
    }
  }

  Future<String?> deleteSession(String id) async {
    _emit(_state.copyWith(isMutating: true));

    try {
      await _deleteSession(id);
      await load();
      return null;
    } catch (e) {
      _emit(_state.copyWith(isMutating: false));
      return e.toString();
    }
  }
}
