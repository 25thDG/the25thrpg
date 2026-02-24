import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/sport_session.dart';
import '../models/sport_session_model.dart';

// Single skill UUID hardcoded in data layer only.
const _skillId = 'e377b7af-d755-4a16-aa7a-d4fdee33b493';

class SportSupabaseDatasource {
  final SupabaseClient _client;

  SportSupabaseDatasource(this._client);

  (String, String) _todayUtcRange() {
    final now = DateTime.now();
    final localStart = DateTime(now.year, now.month, now.day);
    final localEnd = localStart.add(const Duration(days: 1));
    return (
      localStart.toUtc().toIso8601String(),
      localEnd.toUtc().toIso8601String(),
    );
  }

  Future<List<SportSession>> getAllActiveSessions({
    required String userId,
  }) async {
    final res = await _client
        .from('skill_sessions')
        .select()
        .eq('user_id', userId)
        .eq('skill_id', _skillId)
        .isFilter('deleted_at', null)
        .order('session_at', ascending: true);

    return (res as List)
        .cast<Map<String, dynamic>>()
        .map(SportSessionModel.fromMap)
        .toList();
  }

  Future<List<SportSession>> getTodaySessions({required String userId}) async {
    final (start, end) = _todayUtcRange();

    final res = await _client
        .from('skill_sessions')
        .select()
        .eq('user_id', userId)
        .eq('skill_id', _skillId)
        .isFilter('deleted_at', null)
        .gte('session_at', start)
        .lt('session_at', end)
        .order('session_at', ascending: false);

    return (res as List)
        .cast<Map<String, dynamic>>()
        .map(SportSessionModel.fromMap)
        .toList();
  }

  Future<SportSession> addSession({
    required String userId,
    required SportCategory category,
    required int minutes,
    required DateTime sessionAt,
  }) async {
    final res = await _client
        .from('skill_sessions')
        .insert({
          'user_id': userId,
          'skill_id': _skillId,
          'category': category.dbValue,
          'minutes': minutes,
          'session_at': sessionAt.toUtc().toIso8601String(),
        })
        .select()
        .single();

    return SportSessionModel.fromMap(res);
  }

  Future<SportSession> updateSession({
    required String id,
    required int minutes,
  }) async {
    final res = await _client
        .from('skill_sessions')
        .update({
          'minutes': minutes,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', id)
        .select()
        .single();

    return SportSessionModel.fromMap(res);
  }

  Future<void> softDeleteSession(String id) async {
    await _client
        .from('skill_sessions')
        .update({'deleted_at': DateTime.now().toUtc().toIso8601String()})
        .eq('id', id);
  }
}
