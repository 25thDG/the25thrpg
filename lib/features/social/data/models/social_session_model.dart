import '../../domain/entities/social_session.dart';

class SocialSessionModel {
  static SocialSession fromMap(Map<String, dynamic> map) {
    return SocialSession(
      id: map['id'] as String,
      initiationType: InitiationType.fromString(map['category'] as String),
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
