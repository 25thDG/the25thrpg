import '../../domain/entities/sport_session.dart';

class SportSessionModel {
  static SportSession fromMap(Map<String, dynamic> map) {
    return SportSession(
      id: map['id'] as String,
      category: SportCategory.fromString(map['category'] as String),
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
