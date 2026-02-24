import '../../domain/entities/mindfulness_session.dart';
import '../../domain/repositories/mindfulness_repository.dart';
import '../datasources/mindfulness_supabase_datasource.dart';

class MindfulnessRepositoryImpl implements MindfulnessRepository {
  final MindfulnessSupabaseDatasource _datasource;

  const MindfulnessRepositoryImpl(this._datasource);

  @override
  Future<List<MindfulnessSession>> getAllActiveSessions() =>
      _datasource.getAllActiveSessions();

  @override
  Future<List<MindfulnessSession>> getTodaySessions() =>
      _datasource.getTodaySessions();

  @override
  Future<MindfulnessSession> addSession({
    required MindfulnessCategory category,
    required int minutes,
    required DateTime sessionAt,
  }) =>
      _datasource.addSession(
        category: category,
        minutes: minutes,
        sessionAt: sessionAt,
      );

  @override
  Future<MindfulnessSession> updateSession({
    required String id,
    required int minutes,
  }) =>
      _datasource.updateSession(id: id, minutes: minutes);

  @override
  Future<void> softDeleteSession(String id) =>
      _datasource.softDeleteSession(id);
}
