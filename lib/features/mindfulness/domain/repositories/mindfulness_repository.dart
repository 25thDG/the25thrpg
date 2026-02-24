import '../entities/mindfulness_session.dart';

abstract class MindfulnessRepository {
  /// All non-deleted Mindfulness sessions for the app's single user.
  Future<List<MindfulnessSession>> getAllActiveSessions();

  /// Non-deleted Mindfulness sessions created today (local time).
  Future<List<MindfulnessSession>> getTodaySessions();

  Future<MindfulnessSession> addSession({
    required MindfulnessCategory category,
    required int minutes,
    required DateTime sessionAt,
  });

  Future<MindfulnessSession> updateSession({
    required String id,
    required int minutes,
  });

  Future<void> softDeleteSession(String id);
}
