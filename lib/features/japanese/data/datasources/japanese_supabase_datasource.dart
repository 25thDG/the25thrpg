import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/error/app_exception.dart';
import '../../domain/entities/japanese_session.dart';
import '../models/japanese_session_model.dart';

// Single hardcoded user for this private app — no auth required.
const _userId = '1a67d50e-4263-4923-b4bc-1bfa57426aae';

class JapaneseSupabaseDatasource {
  final SupabaseClient _client;

  const JapaneseSupabaseDatasource(this._client);

  Future<List<JapaneseSessionModel>> getAllActiveSessions() async {
    try {
      final List<Map<String, dynamic>> rows = await _client
          .from('japanese_sessions')
          .select()
          .eq('user_id', _userId)
          .isFilter('deleted_at', null)
          .order('session_at', ascending: true);

      return rows.map(JapaneseSessionModel.fromMap).toList();
    } catch (e) {
      throw NetworkException('Failed to fetch sessions: $e');
    }
  }

  Future<List<JapaneseSessionModel>> getTodaySessions() async {
    try {
      final now = DateTime.now();
      final startOfDay =
          DateTime(now.year, now.month, now.day).toUtc().toIso8601String();
      final endOfDay =
          DateTime(now.year, now.month, now.day + 1).toUtc().toIso8601String();

      final List<Map<String, dynamic>> rows = await _client
          .from('japanese_sessions')
          .select()
          .eq('user_id', _userId)
          .isFilter('deleted_at', null)
          .gte('session_at', startOfDay)
          .lt('session_at', endOfDay)
          .order('created_at', ascending: false);

      return rows.map(JapaneseSessionModel.fromMap).toList();
    } catch (e) {
      throw NetworkException("Failed to fetch today's sessions: $e");
    }
  }

  Future<JapaneseSessionModel> addSession({
    required SessionCategory category,
    required int minutes,
    required DateTime sessionAt,
  }) async {
    try {
      final Map<String, dynamic> row = await _client
          .from('japanese_sessions')
          .insert({
            'user_id': _userId,
            'category': category.name,
            'minutes': minutes,
            'session_at': sessionAt.toUtc().toIso8601String(),
          })
          .select()
          .single();

      return JapaneseSessionModel.fromMap(row);
    } catch (e) {
      throw NetworkException('Failed to add session: $e');
    }
  }

  Future<JapaneseSessionModel> updateSession({
    required String id,
    required int minutes,
  }) async {
    try {
      final Map<String, dynamic> row = await _client
          .from('japanese_sessions')
          .update({
            'minutes': minutes,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', id)
          .select()
          .single();

      return JapaneseSessionModel.fromMap(row);
    } catch (e) {
      throw NetworkException('Failed to update session: $e');
    }
  }

  Future<void> softDeleteSession(String id) async {
    try {
      await _client
          .from('japanese_sessions')
          .update({'deleted_at': DateTime.now().toUtc().toIso8601String()})
          .eq('id', id);
    } catch (e) {
      throw NetworkException('Failed to delete session: $e');
    }
  }
}
