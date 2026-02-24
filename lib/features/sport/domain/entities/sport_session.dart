enum SportCategory {
  strength,
  cardio,
  mobility,
  sportSpecific;

  String get displayName {
    switch (this) {
      case SportCategory.strength:
        return 'Strength';
      case SportCategory.cardio:
        return 'Cardio';
      case SportCategory.mobility:
        return 'Mobility';
      case SportCategory.sportSpecific:
        return 'Sport Specific';
    }
  }

  String get dbValue {
    switch (this) {
      case SportCategory.strength:
        return 'strength';
      case SportCategory.cardio:
        return 'cardio';
      case SportCategory.mobility:
        return 'mobility';
      case SportCategory.sportSpecific:
        return 'sport_specific';
    }
  }

  static SportCategory fromString(String value) {
    return switch (value) {
      'strength' => SportCategory.strength,
      'cardio' => SportCategory.cardio,
      'mobility' => SportCategory.mobility,
      'sport_specific' => SportCategory.sportSpecific,
      _ => throw ArgumentError('Unknown sport category: $value'),
    };
  }
}

class SportSession {
  final String id;
  final SportCategory category;
  final int minutes;
  final DateTime sessionAt;
  final DateTime? deletedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SportSession({
    required this.id,
    required this.category,
    required this.minutes,
    required this.sessionAt,
    this.deletedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  SportSession copyWith({
    String? id,
    SportCategory? category,
    int? minutes,
    DateTime? sessionAt,
    DateTime? deletedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SportSession(
      id: id ?? this.id,
      category: category ?? this.category,
      minutes: minutes ?? this.minutes,
      sessionAt: sessionAt ?? this.sessionAt,
      deletedAt: deletedAt ?? this.deletedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
