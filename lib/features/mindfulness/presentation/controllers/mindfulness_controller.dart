import 'package:flutter/foundation.dart';

import '../../application/use_cases/add_mindfulness_session_use_case.dart';
import '../../application/use_cases/delete_mindfulness_session_use_case.dart';
import '../../application/use_cases/get_mindfulness_stats_use_case.dart';
import '../../application/use_cases/get_today_mindfulness_sessions_use_case.dart';
import '../../application/use_cases/update_mindfulness_session_use_case.dart';
import '../../domain/entities/mindfulness_session.dart';
import '../state/mindfulness_state.dart';

class MindfulnessController extends ChangeNotifier {
  final GetMindfulnessStatsUseCase _getStats;
  final GetTodayMindfulnessSessionsUseCase _getTodaySessions;
  final AddMindfulnessSessionUseCase _addSession;
  final UpdateMindfulnessSessionUseCase _updateSession;
  final DeleteMindfulnessSessionUseCase _deleteSession;

  MindfulnessState _state = MindfulnessState.initial();
  MindfulnessState get state => _state;

  MindfulnessController({
    required GetMindfulnessStatsUseCase getStats,
    required GetTodayMindfulnessSessionsUseCase getTodaySessions,
    required AddMindfulnessSessionUseCase addSession,
    required UpdateMindfulnessSessionUseCase updateSession,
    required DeleteMindfulnessSessionUseCase deleteSession,
  })  : _getStats = getStats,
        _getTodaySessions = getTodaySessions,
        _addSession = addSession,
        _updateSession = updateSession,
        _deleteSession = deleteSession;

  void _emit(MindfulnessState next) {
    _state = next;
    notifyListeners();
  }

  Future<void> load() async {
    _emit(_state.copyWith(
      statsStatus: MindfulnessLoadStatus.loading,
      sessionsStatus: MindfulnessLoadStatus.loading,
    ));
    await Future.wait([_loadStats(), _loadTodaySessions()]);
  }

  Future<void> _loadStats() async {
    try {
      final stats = await _getStats.execute();
      _emit(_state.copyWith(
        statsStatus: MindfulnessLoadStatus.loaded,
        stats: stats,
      ));
    } catch (e) {
      _emit(_state.copyWith(
        statsStatus: MindfulnessLoadStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _loadTodaySessions() async {
    try {
      final sessions = await _getTodaySessions.execute();
      _emit(_state.copyWith(
        sessionsStatus: MindfulnessLoadStatus.loaded,
        todaySessions: sessions,
      ));
    } catch (e) {
      _emit(_state.copyWith(
        sessionsStatus: MindfulnessLoadStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  /// Returns an error message on failure, null on success.
  Future<String?> addSession({
    required MindfulnessCategory category,
    required int minutes,
  }) async {
    try {
      await _addSession.execute(category: category, minutes: minutes);
      await load();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  /// Returns an error message on failure, null on success.
  Future<String?> updateSession({
    required String sessionId,
    required int minutes,
  }) async {
    try {
      await _updateSession.execute(sessionId: sessionId, minutes: minutes);
      await load();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  /// Returns an error message on failure, null on success.
  Future<String?> deleteSession(String sessionId) async {
    try {
      await _deleteSession.execute(sessionId);
      await load();
      return null;
    } catch (e) {
      return e.toString();
    }
  }
}
