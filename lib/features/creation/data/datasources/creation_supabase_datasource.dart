import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/creation_project.dart';
import '../../domain/entities/creation_session.dart';
import '../models/creation_project_model.dart';
import '../models/creation_session_model.dart';

// Single user — UUID hardcoded in data layer only.
const _userId = '1a67d50e-4263-4923-b4bc-1bfa57426aae';
const _skillId = '1c955a16-ec08-40c4-9855-f3d82b86ea9a';

class CreationSupabaseDatasource {
  final SupabaseClient _client;

  const CreationSupabaseDatasource(this._client);

  // ── Date helpers ─────────────────────────────────────────────────────────

  String _formatDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  (String, String) _todayUtcRange() {
    final now = DateTime.now();
    final localStart = DateTime(now.year, now.month, now.day);
    final localEnd = localStart.add(const Duration(days: 1));
    return (
      localStart.toUtc().toIso8601String(),
      localEnd.toUtc().toIso8601String(),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Future<Map<String, String>> _activeProjectNameMap() async {
    final res = await _client
        .from('creation_projects')
        .select('id, name')
        .eq('user_id', _userId)
        .isFilter('deleted_at', null);
    return {
      for (final p in (res as List).cast<Map<String, dynamic>>())
        p['id'] as String: p['name'] as String,
    };
  }

  // ── Sessions ──────────────────────────────────────────────────────────────

  Future<List<CreationSession>> getAllActiveSessions() async {
    final (generalRes, projectMap) = await (
      _client
          .from('skill_sessions')
          .select()
          .eq('user_id', _userId)
          .eq('skill_id', _skillId)
          .isFilter('deleted_at', null),
      _activeProjectNameMap(),
    ).wait;

    final general = (generalRes as List)
        .cast<Map<String, dynamic>>()
        .map(CreationSessionModel.fromGeneralMap)
        .toList();

    if (projectMap.isEmpty) return general;

    final projectSessionsRes = await _client
        .from('creation_sessions')
        .select('*, creation_projects(id, name)')
        .inFilter('project_id', projectMap.keys.toList())
        .isFilter('deleted_at', null);

    final projectSessions = (projectSessionsRes as List)
        .cast<Map<String, dynamic>>()
        .map(CreationSessionModel.fromProjectMap)
        .toList();

    return [...general, ...projectSessions];
  }

  Future<List<CreationSession>> getTodaySessions() async {
    final (start, end) = _todayUtcRange();

    final (generalRes, projectMap) = await (
      _client
          .from('skill_sessions')
          .select()
          .eq('user_id', _userId)
          .eq('skill_id', _skillId)
          .isFilter('deleted_at', null)
          .gte('session_at', start)
          .lt('session_at', end),
      _activeProjectNameMap(),
    ).wait;

    final general = (generalRes as List)
        .cast<Map<String, dynamic>>()
        .map(CreationSessionModel.fromGeneralMap)
        .toList();

    if (projectMap.isEmpty) return general;

    final projectSessionsRes = await _client
        .from('creation_sessions')
        .select('*, creation_projects(id, name)')
        .inFilter('project_id', projectMap.keys.toList())
        .isFilter('deleted_at', null)
        .gte('session_at', start)
        .lt('session_at', end);

    final projectSessions = (projectSessionsRes as List)
        .cast<Map<String, dynamic>>()
        .map(CreationSessionModel.fromProjectMap)
        .toList();

    final all = [...general, ...projectSessions]
      ..sort((a, b) => b.sessionAt.compareTo(a.sessionAt));
    return all;
  }

  Future<CreationSession> addGeneralSession({
    required int minutes,
    required DateTime sessionAt,
  }) async {
    final res = await _client
        .from('skill_sessions')
        .insert({
          'user_id': _userId,
          'skill_id': _skillId,
          'category': 'general',
          'minutes': minutes,
          'session_at': sessionAt.toUtc().toIso8601String(),
        })
        .select()
        .single();
    return CreationSessionModel.fromGeneralMap(res);
  }

  Future<CreationSession> addProjectSession({
    required String projectId,
    required int minutes,
    required DateTime sessionAt,
  }) async {
    final res = await _client
        .from('creation_sessions')
        .insert({
          'project_id': projectId,
          'minutes': minutes,
          'session_at': sessionAt.toUtc().toIso8601String(),
        })
        .select('*, creation_projects(id, name)')
        .single();
    return CreationSessionModel.fromProjectMap(res);
  }

  Future<CreationSession> updateSession({
    required String id,
    required int minutes,
    required CreationSessionType type,
  }) async {
    final now = DateTime.now().toUtc().toIso8601String();
    if (type == CreationSessionType.general) {
      final res = await _client
          .from('skill_sessions')
          .update({'minutes': minutes, 'updated_at': now})
          .eq('id', id)
          .select()
          .single();
      return CreationSessionModel.fromGeneralMap(res);
    } else {
      final res = await _client
          .from('creation_sessions')
          .update({'minutes': minutes, 'updated_at': now})
          .eq('id', id)
          .select('*, creation_projects(id, name)')
          .single();
      return CreationSessionModel.fromProjectMap(res);
    }
  }

  Future<void> softDeleteSession({
    required String id,
    required CreationSessionType type,
  }) async {
    final now = DateTime.now().toUtc().toIso8601String();
    if (type == CreationSessionType.general) {
      await _client
          .from('skill_sessions')
          .update({'deleted_at': now})
          .eq('id', id);
    } else {
      await _client
          .from('creation_sessions')
          .update({'deleted_at': now})
          .eq('id', id);
    }
  }

  // ── Projects ──────────────────────────────────────────────────────────────

  Future<List<CreationProject>> getAllActiveProjects() async {
    final res = await _client
        .from('creation_projects')
        .select()
        .eq('user_id', _userId)
        .isFilter('deleted_at', null)
        .order('created_at', ascending: true);
    return res.map(CreationProjectModel.fromMap).toList();
  }

  Future<CreationProject> createProject({required String name}) async {
    final res = await _client
        .from('creation_projects')
        .insert({
          'user_id': _userId,
          'name': name,
          'start_date': _formatDate(DateTime.now()),
          'status': 'active',
        })
        .select()
        .single();
    return CreationProjectModel.fromMap(res);
  }

  Future<CreationProject> updateProject({
    required String id,
    required String name,
  }) async {
    final res = await _client
        .from('creation_projects')
        .update({
          'name': name,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', id)
        .select()
        .single();
    return CreationProjectModel.fromMap(res);
  }

  Future<CreationProject> completeProject(String id) async {
    final res = await _client
        .from('creation_projects')
        .update({
          'status': 'completed',
          'end_date': _formatDate(DateTime.now()),
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', id)
        .select()
        .single();
    return CreationProjectModel.fromMap(res);
  }

  Future<void> softDeleteProject(String id) async {
    await _client
        .from('creation_projects')
        .update({'deleted_at': DateTime.now().toUtc().toIso8601String()})
        .eq('id', id);
  }
}
