enum MindfulnessCategory {
  meditation,
  journaling,
  walking,
  nonfiction;

  String get displayName {
    switch (this) {
      case MindfulnessCategory.meditation:
        return 'Meditation';
      case MindfulnessCategory.journaling:
        return 'Journaling';
      case MindfulnessCategory.walking:
        return 'Walking';
      case MindfulnessCategory.nonfiction:
        return 'Nonfiction';
    }
  }

  static MindfulnessCategory fromString(String value) {
    return MindfulnessCategory.values.firstWhere(
      (e) => e.name == value,
      orElse: () => throw ArgumentError('Unknown mindfulness category: $value'),
    );
  }
}

class MindfulnessSession {
  final String id;
  final String skillId;
  final MindfulnessCategory category;
  final int minutes;
  final DateTime sessionAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  const MindfulnessSession({
    required this.id,
    required this.skillId,
    required this.category,
    required this.minutes,
    required this.sessionAt,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  bool get isDeleted => deletedAt != null;

  MindfulnessSession copyWith({
    String? id,
    String? skillId,
    MindfulnessCategory? category,
    int? minutes,
    DateTime? sessionAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return MindfulnessSession(
      id: id ?? this.id,
      skillId: skillId ?? this.skillId,
      category: category ?? this.category,
      minutes: minutes ?? this.minutes,
      sessionAt: sessionAt ?? this.sessionAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MindfulnessSession && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
