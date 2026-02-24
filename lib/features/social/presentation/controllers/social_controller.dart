import 'package:flutter/foundation.dart';

import '../../application/use_cases/add_social_session_use_case.dart';
import '../../application/use_cases/delete_social_session_use_case.dart';
import '../../application/use_cases/get_social_stats_use_case.dart';
import '../../application/use_cases/get_today_social_sessions_use_case.dart';
import '../../application/use_cases/update_social_session_use_case.dart';
import '../../domain/entities/social_session.dart';
import '../state/social_state.dart';

class SocialController extends ChangeNotifier {
  final GetSocialStatsUseCase _getStats;
  final GetTodaySocialSessionsUseCase _getTodaySessions;
  final AddSocialSessionUseCase _addSession;
  final UpdateSocialSessionUseCase _updateSession;
  final DeleteSocialSessionUseCase _deleteSession;

  SocialState _state = const SocialState();
  SocialState get state => _state;

  SocialController({
    required GetSocialStatsUseCase getStats,
    required GetTodaySocialSessionsUseCase getTodaySessions,
    required AddSocialSessionUseCase addSession,
    required UpdateSocialSessionUseCase updateSession,
    required DeleteSocialSessionUseCase deleteSession,
  })  : _getStats = getStats,
        _getTodaySessions = getTodaySessions,
        _addSession = addSession,
        _updateSession = updateSession,
        _deleteSession = deleteSession;

  void _emit(SocialState s) {
    _state = s;
    notifyListeners();
  }

  Future<void> load() async {
    _emit(_state.copyWith(
      statsStatus: SocialLoadStatus.loading,
      sessionsStatus: SocialLoadStatus.loading,
      isMutating: false,
    ));
    await Future.wait([_loadStats(), _loadTodaySessions()]);
  }

  Future<void> _loadStats() async {
    try {
      final stats = await _getStats();
      _emit(_state.copyWith(
        stats: stats,
        statsStatus: SocialLoadStatus.loaded,
      ));
    } catch (e) {
      _emit(_state.copyWith(
        statsStatus: SocialLoadStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _loadTodaySessions() async {
    try {
      final sessions = await _getTodaySessions();
      _emit(_state.copyWith(
        todaySessions: sessions,
        sessionsStatus: SocialLoadStatus.loaded,
      ));
    } catch (e) {
      _emit(_state.copyWith(sessionsStatus: SocialLoadStatus.error));
    }
  }

  Future<String?> addSession(InitiationType initiationType, int minutes) async {
    _emit(_state.copyWith(isMutating: true));
    try {
      await _addSession(initiationType: initiationType, minutes: minutes);
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
