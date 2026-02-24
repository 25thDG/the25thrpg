import '../../domain/entities/japanese_session.dart';

class JapaneseSessionModel extends JapaneseSession {
  const JapaneseSessionModel({
    required super.id,
    required super.userId,
    required super.category,
    required super.minutes,
    required super.sessionAt,
    required super.createdAt,
    required super.updatedAt,
    super.deletedAt,
  });

  factory JapaneseSessionModel.fromMap(Map<String, dynamic> map) {
    return JapaneseSessionModel(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      category: SessionCategory.fromString(map['category'] as String),
      minutes: map['minutes'] as int,
      sessionAt: DateTime.parse(map['session_at'] as String).toLocal(),
      createdAt: DateTime.parse(map['created_at'] as String).toLocal(),
      updatedAt: DateTime.parse(map['updated_at'] as String).toLocal(),
      deletedAt: map['deleted_at'] != null
          ? DateTime.parse(map['deleted_at'] as String).toLocal()
          : null,
    );
  }

  Map<String, dynamic> toInsertMap() => {
        'user_id': userId,
        'category': category.name,
        'minutes': minutes,
        'session_at': sessionAt.toUtc().toIso8601String(),
      };
}
