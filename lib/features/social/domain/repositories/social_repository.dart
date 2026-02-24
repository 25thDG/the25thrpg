import '../entities/social_session.dart';

abstract class SocialRepository {
  Future<List<SocialSession>> getAllActiveSessions();
  Future<List<SocialSession>> getTodaySessions();

  Future<SocialSession> addSession({
    required InitiationType initiationType,
    required int minutes,
    required DateTime sessionAt,
  });

  Future<SocialSession> updateSession({
    required String id,
    required int minutes,
  });

  Future<void> softDeleteSession(String id);
}
