enum SessionCategory {
  vocab,
  reading,
  active,
  passive,
  accent;

  String get displayName {
    switch (this) {
      case SessionCategory.vocab:
        return 'Vocab';
      case SessionCategory.reading:
        return 'Reading';
      case SessionCategory.active:
        return 'Active';
      case SessionCategory.passive:
        return 'Passive';
      case SessionCategory.accent:
        return 'Accent';
    }
  }

  static SessionCategory fromString(String value) {
    return SessionCategory.values.firstWhere(
      (e) => e.name == value,
      orElse: () => throw ArgumentError('Unknown category: $value'),
    );
  }
}

class JapaneseSession {
  final String id;
  final String userId;
  final SessionCategory category;
  final int minutes;
  final DateTime sessionAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  const JapaneseSession({
    required this.id,
    required this.userId,
    required this.category,
    required this.minutes,
    required this.sessionAt,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  bool get isDeleted => deletedAt != null;

  JapaneseSession copyWith({
    String? id,
    String? userId,
    SessionCategory? category,
    int? minutes,
    DateTime? sessionAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return JapaneseSession(
      id: id ?? this.id,
      userId: userId ?? this.userId,
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
      identical(this, other) || other is JapaneseSession && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
