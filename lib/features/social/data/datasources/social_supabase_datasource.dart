import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/social_session.dart';
import '../models/social_session_model.dart';

// Single user — UUID hardcoded in data layer only.
const _userId = '1a67d50e-4263-4923-b4bc-1bfa57426aae';
// Single skill — UUID hardcoded in data layer only.
const _skillId = 'a3870777-b8a7-433f-aa32-363799edfbd5';

class SocialSupabaseDatasource {
  final SupabaseClient _client;

  SocialSupabaseDatasource(this._client);
   

  (String, String) _todayUtcRange() {
    final now = DateTime.now();
    final localStart = DateTime(now.year, now.month, now.day);
    final localEnd = localStart.add(const Duration(days: 1));
    return (
      localStart.toUtc().toIso8601String(),
      localEnd.toUtc().toIso8601String(),
    );
  }

  Future<List<SocialSession>> getAllActiveSessions() async {
    final res = await _client
        .from('skill_sessions')
        .select()
        .eq('user_id', _userId)
        .eq('skill_id', _skillId)
        .isFilter('deleted_at', null)
        .order('session_at', ascending: true);
    return (res as List)
        .cast<Map<String, dynamic>>()
        .map(SocialSessionModel.fromMap)
        .toList();
  }

  Future<List<SocialSession>> getTodaySessions() async {
    final (start, end) = _todayUtcRange();
    final res = await _client
        .from('skill_sessions')
        .select()
        .eq('user_id', _userId)
        .eq('skill_id', _skillId)
        .isFilter('deleted_at', null)
        .gte('session_at', start)
        .lt('session_at', end)
        .order('session_at', ascending: false);
    return (res as List)
        .cast<Map<String, dynamic>>()
        .map(SocialSessionModel.fromMap)
        .toList();
  }

  Future<SocialSession> addSession({
    required InitiationType initiationType,
    required int minutes,
    required DateTime sessionAt,
  }) async {
    final res = await _client
        .from('skill_sessions')
        .insert({
          'user_id': _userId,
          'skill_id': _skillId,
          'category':
              initiationType == InitiationType.self ? 'self' : 'other',
          'minutes': minutes,
          'session_at': sessionAt.toUtc().toIso8601String(),
        })
        .select()
        .single();
    return SocialSessionModel.fromMap(res);
  }

  Future<SocialSession> updateSession({
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
    return SocialSessionModel.fromMap(res);
  }

  Future<void> softDeleteSession(String id) async {
    await _client
        .from('skill_sessions')
        .update({'deleted_at': DateTime.now().toUtc().toIso8601String()})
        .eq('id', id);
  }
}
