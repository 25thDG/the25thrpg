import 'package:flutter/foundation.dart';

import '../../application/use_cases/add_japanese_session_use_case.dart';
import '../../application/use_cases/delete_japanese_session_use_case.dart';
import '../../application/use_cases/get_japanese_stats_use_case.dart';
import '../../application/use_cases/get_today_japanese_sessions_use_case.dart';
import '../../application/use_cases/update_japanese_session_use_case.dart';
import '../../data/datasources/japanese_milestone_prefs.dart';
import '../../domain/entities/japanese_milestone.dart';
import '../../domain/entities/japanese_session.dart';
import '../state/japanese_state.dart';

class JapaneseController extends ChangeNotifier {
  final GetJapaneseStatsUseCase _getStats;
  final GetTodayJapaneseSessionsUseCase _getTodaySessions;
  final AddJapaneseSessionUseCase _addSession;
  final UpdateJapaneseSessionUseCase _updateSession;
  final DeleteJapaneseSessionUseCase _deleteSession;
  final JapaneseMilestonePrefs _milestonePrefs;

  JapaneseState _state = JapaneseState.initial();
  JapaneseState get state => _state;

  JapaneseController({
    required GetJapaneseStatsUseCase getStats,
    required GetTodayJapaneseSessionsUseCase getTodaySessions,
    required AddJapaneseSessionUseCase addSession,
    required UpdateJapaneseSessionUseCase updateSession,
    required DeleteJapaneseSessionUseCase deleteSession,
    JapaneseMilestonePrefs milestonePrefs = const JapaneseMilestonePrefs(),
  })  : _getStats = getStats,
        _getTodaySessions = getTodaySessions,
        _addSession = addSession,
        _updateSession = updateSession,
        _deleteSession = deleteSession,
        _milestonePrefs = milestonePrefs;

  void _emit(JapaneseState next) {
    _state = next;
    notifyListeners();
  }

  Future<void> load() async {
    _emit(_state.copyWith(
      statsStatus: LoadStatus.loading,
      sessionsStatus: LoadStatus.loading,
    ));
    await Future.wait([_loadStats(), _loadTodaySessions(), _loadMilestone()]);
  }

  Future<void> _loadMilestone() async {
    try {
      final milestone = await _milestonePrefs.load();
      // Runs beside the stats load — keep any error it reported.
      _emit(_state.copyWith(
        milestone: milestone,
        errorMessage: _state.errorMessage,
      ));
    } catch (_) {
      // Unreadable prefs leave the default target in place.
    }
  }

  Future<void> setMilestone(JapaneseMilestone milestone) async {
    _emit(_state.copyWith(
      milestone: milestone,
      errorMessage: _state.errorMessage,
    ));
    await _milestonePrefs.save(milestone);
  }

  Future<void> _loadStats() async {
    try {
      final stats = await _getStats.execute();
      _emit(_state.copyWith(statsStatus: LoadStatus.loaded, stats: stats));
    } catch (e) {
      _emit(_state.copyWith(
        statsStatus: LoadStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _loadTodaySessions() async {
    try {
      final sessions = await _getTodaySessions.execute();
      _emit(_state.copyWith(
        sessionsStatus: LoadStatus.loaded,
        todaySessions: sessions,
      ));
    } catch (e) {
      _emit(_state.copyWith(
        sessionsStatus: LoadStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  /// Returns the error message if the operation fails, null on success.
  Future<String?> addSession({
    required SessionCategory category,
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

  /// Returns the error message if the operation fails, null on success.
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

  /// Returns the error message if the operation fails, null on success.
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
