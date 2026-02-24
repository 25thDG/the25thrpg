import '../../domain/entities/sport_session.dart';
import '../../domain/repositories/sport_repository.dart';
import '../datasources/sport_supabase_datasource.dart';

class SportRepositoryImpl implements SportRepository {
  // Single user UUID hardcoded in repository implementation only.
  static const _userId = '1a67d50e-4263-4923-b4bc-1bfa57426aae';

  final SportSupabaseDatasource _datasource;

  const SportRepositoryImpl(this._datasource);

  @override
  Future<List<SportSession>> getAllActiveSessions() =>
      _datasource.getAllActiveSessions(userId: _userId);

  @override
  Future<List<SportSession>> getTodaySessions() =>
      _datasource.getTodaySessions(userId: _userId);

  @override
  Future<SportSession> addSession({
    required SportCategory category,
    required int minutes,
    required DateTime sessionAt,
  }) => _datasource.addSession(
    userId: _userId,
    category: category,
    minutes: minutes,
    sessionAt: sessionAt,
  );

  @override
  Future<SportSession> updateSession({
    required String id,
    required int minutes,
  }) => _datasource.updateSession(id: id, minutes: minutes);

  @override
  Future<void> softDeleteSession(String id) =>
      _datasource.softDeleteSession(id);
}
