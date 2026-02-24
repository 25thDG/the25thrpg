enum InitiationType {
  self,
  other;

  String get displayName => switch (this) {
        InitiationType.self => 'I initiated',
        InitiationType.other => 'They initiated',
      };

  static InitiationType fromString(String value) =>
      value == 'self' ? InitiationType.self : InitiationType.other;
}

class SocialSession {
  final String id;
  final InitiationType initiationType;
  final int minutes;
  final DateTime sessionAt;
  final DateTime? deletedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SocialSession({
    required this.id,
    required this.initiationType,
    required this.minutes,
    required this.sessionAt,
    this.deletedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  SocialSession copyWith({
    String? id,
    InitiationType? initiationType,
    int? minutes,
    DateTime? sessionAt,
    DateTime? deletedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SocialSession(
      id: id ?? this.id,
      initiationType: initiationType ?? this.initiationType,
      minutes: minutes ?? this.minutes,
      sessionAt: sessionAt ?? this.sessionAt,
      deletedAt: deletedAt ?? this.deletedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
