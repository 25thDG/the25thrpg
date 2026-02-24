import '../entities/creation_project.dart';
import '../entities/creation_session.dart';

abstract class CreationRepository {
  Future<List<CreationSession>> getAllActiveSessions();
  Future<List<CreationSession>> getTodaySessions();
  Future<List<CreationProject>> getAllActiveProjects();

  Future<CreationSession> addGeneralSession({
    required int minutes,
    required DateTime sessionAt,
  });

  Future<CreationSession> addProjectSession({
    required String projectId,
    required int minutes,
    required DateTime sessionAt,
  });

  Future<CreationSession> updateSession({
    required String id,
    required int minutes,
    required CreationSessionType type,
  });

  Future<void> softDeleteSession({
    required String id,
    required CreationSessionType type,
  });

  Future<CreationProject> createProject({required String name});
  Future<CreationProject> updateProject({required String id, required String name});
  Future<CreationProject> completeProject(String id);
  Future<void> softDeleteProject(String id);
}
