enum QuestDifficulty {
  side,
  normal,
  epic,
  legendary;

  String get displayName {
    switch (this) {
      case QuestDifficulty.side:
        return 'Side';
      case QuestDifficulty.normal:
        return 'Normal';
      case QuestDifficulty.epic:
        return 'Epic';
      case QuestDifficulty.legendary:
        return 'Legendary';
    }
  }

  String get dbValue {
    switch (this) {
      case QuestDifficulty.side:
        return 'side';
      case QuestDifficulty.normal:
        return 'normal';
      case QuestDifficulty.epic:
        return 'epic';
      case QuestDifficulty.legendary:
        return 'legendary';
    }
  }

  int get defaultXp {
    switch (this) {
      case QuestDifficulty.side:
        return 50;
      case QuestDifficulty.normal:
        return 150;
      case QuestDifficulty.epic:
        return 400;
      case QuestDifficulty.legendary:
        return 1000;
    }
  }

  static QuestDifficulty fromString(String v) => switch (v) {
        'side' => QuestDifficulty.side,
        'epic' => QuestDifficulty.epic,
        'legendary' => QuestDifficulty.legendary,
        _ => QuestDifficulty.normal,
      };
}

enum QuestStatus {
  active,
  completed;

  String get dbValue => name;

  static QuestStatus fromString(String v) =>
      v == 'completed' ? QuestStatus.completed : QuestStatus.active;
}

class QuestObjective {
  final String id;
  final String text;
  final bool completed;

  const QuestObjective({
    required this.id,
    required this.text,
    required this.completed,
  });

  QuestObjective copyWith({String? id, String? text, bool? completed}) =>
      QuestObjective(
        id: id ?? this.id,
        text: text ?? this.text,
        completed: completed ?? this.completed,
      );

  Map<String, dynamic> toMap() => {'id': id, 'text': text, 'completed': completed};

  factory QuestObjective.fromMap(Map<String, dynamic> m) => QuestObjective(
        id: m['id'] as String,
        text: m['text'] as String,
        completed: m['completed'] as bool? ?? false,
      );
}

class Quest {
  final String id;
  final String title;
  final String? description;
  final int xpReward;
  final QuestDifficulty difficulty;
  final QuestStatus status;
  final List<QuestObjective> objectives;
  final DateTime? completedAt;
  final DateTime createdAt;

  const Quest({
    required this.id,
    required this.title,
    this.description,
    required this.xpReward,
    required this.difficulty,
    required this.status,
    required this.objectives,
    this.completedAt,
    required this.createdAt,
  });

  int get completedObjectives => objectives.where((o) => o.completed).length;
  bool get allObjectivesDone =>
      objectives.isNotEmpty && completedObjectives == objectives.length;

  Quest copyWith({
    String? title,
    String? description,
    int? xpReward,
    QuestDifficulty? difficulty,
    QuestStatus? status,
    List<QuestObjective>? objectives,
    DateTime? completedAt,
  }) =>
      Quest(
        id: id,
        title: title ?? this.title,
        description: description ?? this.description,
        xpReward: xpReward ?? this.xpReward,
        difficulty: difficulty ?? this.difficulty,
        status: status ?? this.status,
        objectives: objectives ?? this.objectives,
        completedAt: completedAt ?? this.completedAt,
        createdAt: createdAt,
      );
}
