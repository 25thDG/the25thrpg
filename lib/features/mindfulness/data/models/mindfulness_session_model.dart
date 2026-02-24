import '../../domain/entities/mindfulness_session.dart';

class MindfulnessSessionModel extends MindfulnessSession {
  const MindfulnessSessionModel({
    required super.id,
    required super.skillId,
    required super.category,
    required super.minutes,
    required super.sessionAt,
    required super.createdAt,
    required super.updatedAt,
    super.deletedAt,
  });

  factory MindfulnessSessionModel.fromMap(Map<String, dynamic> map) {
    return MindfulnessSessionModel(
      id: map['id'] as String,
      skillId: map['skill_id'] as String,
      category: MindfulnessCategory.fromString(map['category'] as String),
      minutes: map['minutes'] as int,
      sessionAt: DateTime.parse(map['session_at'] as String).toLocal(),
      createdAt: DateTime.parse(map['created_at'] as String).toLocal(),
      updatedAt: DateTime.parse(map['updated_at'] as String).toLocal(),
      deletedAt: map['deleted_at'] != null
          ? DateTime.parse(map['deleted_at'] as String).toLocal()
          : null,
    );
  }
}
