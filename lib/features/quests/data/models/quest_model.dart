import '../../domain/entities/quest.dart';

class QuestModel extends Quest {
  const QuestModel({
    required super.id,
    required super.title,
    super.description,
    required super.xpReward,
    required super.difficulty,
    required super.status,
    required super.objectives,
    super.completedAt,
    required super.createdAt,
  });

  factory QuestModel.fromMap(Map<String, dynamic> m) {
    final rawObjectives = m['objectives'];
    final objectives = (rawObjectives as List<dynamic>? ?? [])
        .map((o) => QuestObjective.fromMap(o as Map<String, dynamic>))
        .toList();

    return QuestModel(
      id: m['id'] as String,
      title: m['title'] as String,
      description: m['description'] as String?,
      xpReward: m['xp_reward'] as int,
      difficulty: QuestDifficulty.fromString(m['difficulty'] as String),
      status: QuestStatus.fromString(m['status'] as String),
      objectives: objectives,
      completedAt: m['completed_at'] != null
          ? DateTime.parse(m['completed_at'] as String)
          : null,
      createdAt: DateTime.parse(m['created_at'] as String),
    );
  }

  Map<String, dynamic> toInsertMap(String userId) => {
        'user_id': userId,
        'title': title,
        'description': description,
        'xp_reward': xpReward,
        'difficulty': difficulty.dbValue,
        'status': status.dbValue,
        'objectives': objectives.map((o) => o.toMap()).toList(),
        'completed_at': completedAt?.toUtc().toIso8601String(),
      };

  Map<String, dynamic> toUpdateMap() => {
        'title': title,
        'description': description,
        'xp_reward': xpReward,
        'difficulty': difficulty.dbValue,
        'status': status.dbValue,
        'objectives': objectives.map((o) => o.toMap()).toList(),
        'completed_at': completedAt?.toUtc().toIso8601String(),
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      };
}
