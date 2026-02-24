import '../../domain/entities/creation_session.dart';

class CreationSessionModel {
  /// From a skill_sessions row (general creation time).
  static CreationSession fromGeneralMap(Map<String, dynamic> map) {
    return CreationSession(
      id: map['id'] as String,
      type: CreationSessionType.general,
      projectId: null,
      projectName: null,
      minutes: (map['minutes'] as num).toInt(),
      sessionAt: DateTime.parse(map['session_at'] as String).toLocal(),
      deletedAt: map['deleted_at'] != null
          ? DateTime.parse(map['deleted_at'] as String).toLocal()
          : null,
      createdAt: DateTime.parse(map['created_at'] as String).toLocal(),
      updatedAt: DateTime.parse(map['updated_at'] as String).toLocal(),
    );
  }

  /// From a creation_sessions row that includes nested creation_projects data.
  static CreationSession fromProjectMap(Map<String, dynamic> map) {
    final projectData = map['creation_projects'] as Map<String, dynamic>?;
    return CreationSession(
      id: map['id'] as String,
      type: CreationSessionType.project,
      projectId: map['project_id'] as String?,
      projectName: projectData?['name'] as String?,
      minutes: (map['minutes'] as num).toInt(),
      sessionAt: DateTime.parse(map['session_at'] as String).toLocal(),
      deletedAt: map['deleted_at'] != null
          ? DateTime.parse(map['deleted_at'] as String).toLocal()
          : null,
      createdAt: DateTime.parse(map['created_at'] as String).toLocal(),
      updatedAt: DateTime.parse(map['updated_at'] as String).toLocal(),
    );
  }
}
