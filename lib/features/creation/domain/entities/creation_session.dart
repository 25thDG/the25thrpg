enum CreationSessionType { general, project }

class CreationSession {
  final String id;
  final CreationSessionType type;
  final String? projectId;
  final String? projectName;
  final int minutes;
  final DateTime sessionAt;
  final DateTime? deletedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CreationSession({
    required this.id,
    required this.type,
    this.projectId,
    this.projectName,
    required this.minutes,
    required this.sessionAt,
    this.deletedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  CreationSession copyWith({
    String? id,
    CreationSessionType? type,
    String? projectId,
    String? projectName,
    int? minutes,
    DateTime? sessionAt,
    DateTime? deletedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CreationSession(
      id: id ?? this.id,
      type: type ?? this.type,
      projectId: projectId ?? this.projectId,
      projectName: projectName ?? this.projectName,
      minutes: minutes ?? this.minutes,
      sessionAt: sessionAt ?? this.sessionAt,
      deletedAt: deletedAt ?? this.deletedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
