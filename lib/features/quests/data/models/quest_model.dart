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
    super.targetDate,
    super.rewardText,
    super.rewardCostCents,
    super.rewardClaimedAt,
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
      targetDate: m['target_date'] != null
          ? DateTime.parse(m['target_date'] as String)
          : null,
      rewardText: m['reward_text'] as String?,
      rewardCostCents: m['reward_cost_cents'] as int?,
      rewardClaimedAt: m['reward_claimed_at'] != null
          ? DateTime.parse(m['reward_claimed_at'] as String)
          : null,
    );
  }

  /// `target_date` is a bare date column — send it without a time component.
  static String? _dateOnly(DateTime? d) => d == null
      ? null
      : '${d.year.toString().padLeft(4, '0')}-'
          '${d.month.toString().padLeft(2, '0')}-'
          '${d.day.toString().padLeft(2, '0')}';

  Map<String, dynamic> toInsertMap(String userId) => {
        'user_id': userId,
        'title': title,
        'description': description,
        'xp_reward': xpReward,
        'difficulty': difficulty.dbValue,
        'status': status.dbValue,
        'objectives': objectives.map((o) => o.toMap()).toList(),
        'completed_at': completedAt?.toUtc().toIso8601String(),
        'target_date': _dateOnly(targetDate),
        'reward_text': rewardText,
        'reward_cost_cents': rewardCostCents,
        'reward_claimed_at': rewardClaimedAt?.toUtc().toIso8601String(),
      };

  Map<String, dynamic> toUpdateMap() => {
        'title': title,
        'description': description,
        'xp_reward': xpReward,
        'difficulty': difficulty.dbValue,
        'status': status.dbValue,
        'objectives': objectives.map((o) => o.toMap()).toList(),
        'completed_at': completedAt?.toUtc().toIso8601String(),
        'target_date': _dateOnly(targetDate),
        'reward_text': rewardText,
        'reward_cost_cents': rewardCostCents,
        'reward_claimed_at': rewardClaimedAt?.toUtc().toIso8601String(),
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      };
}
