import '../entities/sport_session.dart';

abstract class SportRepository {
  Future<List<SportSession>> getAllActiveSessions();
  Future<List<SportSession>> getTodaySessions();

  Future<SportSession> addSession({
    required SportCategory category,
    required int minutes,
    required DateTime sessionAt,
  });

  Future<SportSession> updateSession({
    required String id,
    required int minutes,
  });

  Future<void> softDeleteSession(String id);
}
