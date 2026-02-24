import '../../domain/entities/social_session.dart';
import '../../domain/repositories/social_repository.dart';
import '../datasources/social_supabase_datasource.dart';

class SocialRepositoryImpl implements SocialRepository {
  final SocialSupabaseDatasource _datasource;
  const SocialRepositoryImpl(this._datasource);

  @override
  Future<List<SocialSession>> getAllActiveSessions() =>
      _datasource.getAllActiveSessions();

  @override
  Future<List<SocialSession>> getTodaySessions() =>
      _datasource.getTodaySessions();

  @override
  Future<SocialSession> addSession({
    required InitiationType initiationType,
    required int minutes,
    required DateTime sessionAt,
  }) =>
      _datasource.addSession(
        initiationType: initiationType,
        minutes: minutes,
        sessionAt: sessionAt,
      );

  @override
  Future<SocialSession> updateSession({
    required String id,
    required int minutes,
  }) =>
      _datasource.updateSession(id: id, minutes: minutes);

  @override
  Future<void> softDeleteSession(String id) =>
      _datasource.softDeleteSession(id);
}
