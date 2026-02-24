import '../../domain/entities/japanese_session.dart';
import '../../domain/repositories/japanese_repository.dart';
import '../datasources/japanese_supabase_datasource.dart';

class JapaneseRepositoryImpl implements JapaneseRepository {
  final JapaneseSupabaseDatasource _datasource;

  const JapaneseRepositoryImpl(this._datasource);

  @override
  Future<List<JapaneseSession>> getAllActiveSessions() =>
      _datasource.getAllActiveSessions();

  @override
  Future<List<JapaneseSession>> getTodaySessions() =>
      _datasource.getTodaySessions();

  @override
  Future<JapaneseSession> addSession({
    required SessionCategory category,
    required int minutes,
    required DateTime sessionAt,
  }) =>
      _datasource.addSession(
        category: category,
        minutes: minutes,
        sessionAt: sessionAt,
      );

  @override
  Future<JapaneseSession> updateSession({
    required String id,
    required int minutes,
  }) =>
      _datasource.updateSession(id: id, minutes: minutes);

  @override
  Future<void> softDeleteSession(String id) =>
      _datasource.softDeleteSession(id);
}
