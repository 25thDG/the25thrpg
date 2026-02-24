enum ProjectStatus { active, completed }

class CreationProject {
  final String id;
  final String userId;
  final String name;
  final DateTime startDate;
  final DateTime? endDate;
  final ProjectStatus status;
  final int totalMinutes; // computed from sessions, not stored
  final DateTime? deletedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CreationProject({
    required this.id,
    required this.userId,
    required this.name,
    required this.startDate,
    this.endDate,
    required this.status,
    this.totalMinutes = 0,
    this.deletedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  CreationProject copyWith({
    String? id,
    String? userId,
    String? name,
    DateTime? startDate,
    DateTime? endDate,
    ProjectStatus? status,
    int? totalMinutes,
    DateTime? deletedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CreationProject(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      status: status ?? this.status,
      totalMinutes: totalMinutes ?? this.totalMinutes,
      deletedAt: deletedAt ?? this.deletedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
