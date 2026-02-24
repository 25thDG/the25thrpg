import '../../domain/entities/creation_project.dart';
import '../../domain/entities/creation_session.dart';
import '../../domain/repositories/creation_repository.dart';
import '../datasources/creation_supabase_datasource.dart';

class CreationRepositoryImpl implements CreationRepository {
  final CreationSupabaseDatasource _datasource;
  const CreationRepositoryImpl(this._datasource);

  @override
  Future<List<CreationSession>> getAllActiveSessions() =>
      _datasource.getAllActiveSessions();

  @override
  Future<List<CreationSession>> getTodaySessions() =>
      _datasource.getTodaySessions();

  @override
  Future<List<CreationProject>> getAllActiveProjects() =>
      _datasource.getAllActiveProjects();

  @override
  Future<CreationSession> addGeneralSession({
    required int minutes,
    required DateTime sessionAt,
  }) =>
      _datasource.addGeneralSession(minutes: minutes, sessionAt: sessionAt);

  @override
  Future<CreationSession> addProjectSession({
    required String projectId,
    required int minutes,
    required DateTime sessionAt,
  }) =>
      _datasource.addProjectSession(
        projectId: projectId,
        minutes: minutes,
        sessionAt: sessionAt,
      );

  @override
  Future<CreationSession> updateSession({
    required String id,
    required int minutes,
    required CreationSessionType type,
  }) =>
      _datasource.updateSession(id: id, minutes: minutes, type: type);

  @override
  Future<void> softDeleteSession({
    required String id,
    required CreationSessionType type,
  }) =>
      _datasource.softDeleteSession(id: id, type: type);

  @override
  Future<CreationProject> createProject({required String name}) =>
      _datasource.createProject(name: name);

  @override
  Future<CreationProject> updateProject({
    required String id,
    required String name,
  }) =>
      _datasource.updateProject(id: id, name: name);

  @override
  Future<CreationProject> completeProject(String id) =>
      _datasource.completeProject(id);

  @override
  Future<void> softDeleteProject(String id) =>
      _datasource.softDeleteProject(id);
}
