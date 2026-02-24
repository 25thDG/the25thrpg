import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/error/app_exception.dart';
import '../../domain/entities/mindfulness_session.dart';
import '../models/mindfulness_session_model.dart';

const _userId = '1a67d50e-4263-4923-b4bc-1bfa57426aae';
const _skillId = '6e3b1f81-5733-4ada-a65a-d06d923f94ee';

class MindfulnessSupabaseDatasource {
  final SupabaseClient _client;

  const MindfulnessSupabaseDatasource(this._client);

  Future<List<MindfulnessSessionModel>> getAllActiveSessions() async {
    try {
      final List<Map<String, dynamic>> rows = await _client
          .from('skill_sessions')
          .select()
          .eq('user_id', _userId)
          .eq('skill_id', _skillId)
          .isFilter('deleted_at', null)
          .order('session_at', ascending: true);

      return rows.map(MindfulnessSessionModel.fromMap).toList();
    } catch (e) {
      throw NetworkException('Failed to fetch sessions: $e');
    }
  }

  Future<List<MindfulnessSessionModel>> getTodaySessions() async {
    try {
      final now = DateTime.now();
      final startOfDay =
          DateTime(now.year, now.month, now.day).toUtc().toIso8601String();
      final endOfDay =
          DateTime(now.year, now.month, now.day + 1).toUtc().toIso8601String();

      final List<Map<String, dynamic>> rows = await _client
          .from('skill_sessions')
          .select()
          .eq('user_id', _userId)
          .eq('skill_id', _skillId)
          .isFilter('deleted_at', null)
          .gte('session_at', startOfDay)
          .lt('session_at', endOfDay)
          .order('created_at', ascending: false);

      return rows.map(MindfulnessSessionModel.fromMap).toList();
    } catch (e) {
      throw NetworkException("Failed to fetch today's sessions: $e");
    }
  }

  Future<MindfulnessSessionModel> addSession({
    required MindfulnessCategory category,
    required int minutes,
    required DateTime sessionAt,
  }) async {
    try {
      final Map<String, dynamic> row = await _client
          .from('skill_sessions')
          .insert({
            'user_id': _userId,
            'skill_id': _skillId,
            'category': category.name,
            'minutes': minutes,
            'session_at': sessionAt.toUtc().toIso8601String(),
          })
          .select()
          .single();

      return MindfulnessSessionModel.fromMap(row);
    } catch (e) {
      throw NetworkException('Failed to add session: $e');
    }
  }

  Future<MindfulnessSessionModel> updateSession({
    required String id,
    required int minutes,
  }) async {
    try {
      final Map<String, dynamic> row = await _client
          .from('skill_sessions')
          .update({
            'minutes': minutes,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', id)
          .select()
          .single();

      return MindfulnessSessionModel.fromMap(row);
    } catch (e) {
      throw NetworkException('Failed to update session: $e');
    }
  }

  Future<void> softDeleteSession(String id) async {
    try {
      await _client
          .from('skill_sessions')
          .update({'deleted_at': DateTime.now().toUtc().toIso8601String()})
          .eq('id', id);
    } catch (e) {
      throw NetworkException('Failed to delete session: $e');
    }
  }
}
