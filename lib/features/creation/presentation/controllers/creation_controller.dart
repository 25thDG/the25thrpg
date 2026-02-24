import 'package:flutter/foundation.dart';

import '../../application/use_cases/add_general_creation_session_use_case.dart';
import '../../application/use_cases/add_project_creation_session_use_case.dart';
import '../../application/use_cases/complete_project_use_case.dart';
import '../../application/use_cases/create_project_use_case.dart';
import '../../application/use_cases/delete_creation_session_use_case.dart';
import '../../application/use_cases/delete_project_use_case.dart';
import '../../application/use_cases/get_creation_stats_use_case.dart';
import '../../application/use_cases/get_today_creation_sessions_use_case.dart';
import '../../application/use_cases/update_creation_session_use_case.dart';
import '../../application/use_cases/update_project_use_case.dart';
import '../../domain/entities/creation_session.dart';
import '../state/creation_state.dart';

class CreationController extends ChangeNotifier {
  final GetCreationStatsUseCase _getStats;
  final GetTodayCreationSessionsUseCase _getTodaySessions;
  final AddGeneralCreationSessionUseCase _addGeneral;
  final AddProjectCreationSessionUseCase _addProject;
  final UpdateCreationSessionUseCase _updateSession;
  final DeleteCreationSessionUseCase _deleteSession;
  final CreateProjectUseCase _createProject;
  final UpdateProjectUseCase _updateProject;
  final CompleteProjectUseCase _completeProject;
  final DeleteProjectUseCase _deleteProject;

  CreationState _state = const CreationState();
  CreationState get state => _state;

  CreationController({
    required GetCreationStatsUseCase getStats,
    required GetTodayCreationSessionsUseCase getTodaySessions,
    required AddGeneralCreationSessionUseCase addGeneral,
    required AddProjectCreationSessionUseCase addProject,
    required UpdateCreationSessionUseCase updateSession,
    required DeleteCreationSessionUseCase deleteSession,
    required CreateProjectUseCase createProject,
    required UpdateProjectUseCase updateProject,
    required CompleteProjectUseCase completeProject,
    required DeleteProjectUseCase deleteProject,
  })  : _getStats = getStats,
        _getTodaySessions = getTodaySessions,
        _addGeneral = addGeneral,
        _addProject = addProject,
        _updateSession = updateSession,
        _deleteSession = deleteSession,
        _createProject = createProject,
        _updateProject = updateProject,
        _completeProject = completeProject,
        _deleteProject = deleteProject;

  void _emit(CreationState s) {
    _state = s;
    notifyListeners();
  }

  Future<void> load() async {
    _emit(_state.copyWith(
      statsStatus: CreationLoadStatus.loading,
      sessionsStatus: CreationLoadStatus.loading,
      isMutating: false,
    ));
    await Future.wait([_loadStats(), _loadTodaySessions()]);
  }

  Future<void> _loadStats() async {
    try {
      final stats = await _getStats();
      _emit(_state.copyWith(
        stats: stats,
        statsStatus: CreationLoadStatus.loaded,
      ));
    } catch (e) {
      _emit(_state.copyWith(
        statsStatus: CreationLoadStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _loadTodaySessions() async {
    try {
      final sessions = await _getTodaySessions();
      _emit(_state.copyWith(
        todaySessions: sessions,
        sessionsStatus: CreationLoadStatus.loaded,
      ));
    } catch (e) {
      _emit(_state.copyWith(sessionsStatus: CreationLoadStatus.error));
    }
  }

  // ── Session mutations ─────────────────────────────────────────────────────

  Future<String?> addGeneralSession(int minutes) async {
    _emit(_state.copyWith(isMutating: true));
    try {
      await _addGeneral(minutes: minutes);
      await load();
      return null;
    } catch (e) {
      _emit(_state.copyWith(isMutating: false));
      return e.toString();
    }
  }

  Future<String?> addProjectSession(String projectId, int minutes) async {
    _emit(_state.copyWith(isMutating: true));
    try {
      await _addProject(projectId: projectId, minutes: minutes);
      await load();
      return null;
    } catch (e) {
      _emit(_state.copyWith(isMutating: false));
      return e.toString();
    }
  }

  Future<String?> updateSession(
      String id, int minutes, CreationSessionType type) async {
    _emit(_state.copyWith(isMutating: true));
    try {
      await _updateSession(id: id, minutes: minutes, type: type);
      await load();
      return null;
    } catch (e) {
      _emit(_state.copyWith(isMutating: false));
      return e.toString();
    }
  }

  Future<String?> deleteSession(String id, CreationSessionType type) async {
    _emit(_state.copyWith(isMutating: true));
    try {
      await _deleteSession(id: id, type: type);
      await load();
      return null;
    } catch (e) {
      _emit(_state.copyWith(isMutating: false));
      return e.toString();
    }
  }

  // ── Project mutations ─────────────────────────────────────────────────────

  Future<String?> createProject(String name) async {
    _emit(_state.copyWith(isMutating: true));
    try {
      await _createProject(name: name);
      await load();
      return null;
    } catch (e) {
      _emit(_state.copyWith(isMutating: false));
      return e.toString();
    }
  }

  Future<String?> updateProject(String id, String name) async {
    _emit(_state.copyWith(isMutating: true));
    try {
      await _updateProject(id: id, name: name);
      await load();
      return null;
    } catch (e) {
      _emit(_state.copyWith(isMutating: false));
      return e.toString();
    }
  }

  Future<String?> completeProject(String id) async {
    _emit(_state.copyWith(isMutating: true));
    try {
      await _completeProject(id);
      await load();
      return null;
    } catch (e) {
      _emit(_state.copyWith(isMutating: false));
      return e.toString();
    }
  }

  Future<String?> deleteProject(String id) async {
    _emit(_state.copyWith(isMutating: true));
    try {
      await _deleteProject(id);
      await load();
      return null;
    } catch (e) {
      _emit(_state.copyWith(isMutating: false));
      return e.toString();
    }
  }
}
