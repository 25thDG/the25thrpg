import '../../domain/entities/creation_project.dart';

class CreationProjectModel {
  static CreationProject fromMap(Map<String, dynamic> map) {
    return CreationProject(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      name: map['name'] as String,
      startDate: DateTime.parse(map['start_date'] as String),
      endDate: map['end_date'] != null
          ? DateTime.parse(map['end_date'] as String)
          : null,
      status: map['status'] == 'completed'
          ? ProjectStatus.completed
          : ProjectStatus.active,
      totalMinutes: 0, // filled in by use case
      deletedAt: map['deleted_at'] != null
          ? DateTime.parse(map['deleted_at'] as String).toLocal()
          : null,
      createdAt: DateTime.parse(map['created_at'] as String).toLocal(),
      updatedAt: DateTime.parse(map['updated_at'] as String).toLocal(),
    );
  }
}
