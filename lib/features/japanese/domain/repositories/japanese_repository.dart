import '../entities/japanese_session.dart';

abstract class JapaneseRepository {
  /// All non-deleted sessions for the app's single user.
  Future<List<JapaneseSession>> getAllActiveSessions();

  /// Non-deleted sessions created today (local time) for the app's single user.
  Future<List<JapaneseSession>> getTodaySessions();

  Future<JapaneseSession> addSession({
    required SessionCategory category,
    required int minutes,
    required DateTime sessionAt,
  });

  Future<JapaneseSession> updateSession({
    required String id,
    required int minutes,
  });

  Future<void> softDeleteSession(String id);
}
