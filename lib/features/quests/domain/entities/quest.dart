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

/// Marker for "argument not supplied" in [Quest.copyWith], so an explicit
/// `null` can clear a field instead of being treated as "no change".
const Object _unset = Object();

/// Whether a quest with a deadline is keeping up with it.
enum QuestPace {
  /// Milestones are at least as far along as the elapsed time.
  onTrack,

  /// Time is running out faster than milestones are being ticked.
  behind,

  /// Past the target date and still not finished.
  overdue,

  /// No deadline, no milestones, or already finished — nothing to judge.
  unknown,
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

  /// Optional deadline driving [daysLeft] and [pace].
  final DateTime? targetDate;

  /// Real-world prize unlocked on completion, e.g. "New phone".
  final String? rewardText;

  /// Planned cost of that prize, so it can be budgeted for up front instead of
  /// quietly denting net worth (and the spending quest) when claimed.
  final int? rewardCostCents;

  /// When the prize was actually collected.
  final DateTime? rewardClaimedAt;

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
    this.targetDate,
    this.rewardText,
    this.rewardCostCents,
    this.rewardClaimedAt,
  });

  int get completedObjectives => objectives.where((o) => o.completed).length;
  bool get allObjectivesDone =>
      objectives.isNotEmpty && completedObjectives == objectives.length;

  bool get isCompleted => status == QuestStatus.completed;

  // ── Deadline and pace ──────────────────────────────────────────────────────

  /// Whole days until [targetDate]. Negative once overdue, null with no date.
  int? get daysLeft {
    final target = targetDate;
    if (target == null) return null;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return DateTime(target.year, target.month, target.day)
        .difference(today)
        .inDays;
  }

  /// Share of the quest's window already spent (0–1+).
  double? get timeElapsedFraction {
    final target = targetDate;
    if (target == null) return null;
    final total = target.difference(createdAt).inSeconds;
    if (total <= 0) return null;
    final spent = DateTime.now().difference(createdAt).inSeconds;
    return (spent / total).clamp(0.0, 2.0);
  }

  /// Share of milestones ticked (0–1). Null when the quest has none.
  double? get objectiveFraction {
    if (objectives.isEmpty) return null;
    return completedObjectives / objectives.length;
  }

  /// Compares milestone progress against time spent.
  QuestPace get pace {
    if (isCompleted) return QuestPace.unknown;

    final left = daysLeft;
    if (left != null && left < 0) return QuestPace.overdue;

    final elapsed = timeElapsedFraction;
    final done = objectiveFraction;
    if (elapsed == null || done == null) return QuestPace.unknown;

    // A small grace margin keeps the label from flipping to "behind" the day
    // after a quest is created.
    return done >= elapsed - 0.1 ? QuestPace.onTrack : QuestPace.behind;
  }

  // ── Reward ─────────────────────────────────────────────────────────────────

  bool get hasReward => (rewardText ?? '').trim().isNotEmpty;
  bool get isRewardClaimed => rewardClaimedAt != null;

  /// The prize is earned but not yet collected.
  bool get isRewardClaimable => hasReward && isCompleted && !isRewardClaimed;

  /// Nullable fields take [_unset] as their default so that passing an
  /// explicit `null` clears them. With a plain `?? this.field` default there is
  /// no way to reopen a quest or drop a deadline — null just keeps the old
  /// value.
  Quest copyWith({
    String? title,
    Object? description = _unset,
    int? xpReward,
    QuestDifficulty? difficulty,
    QuestStatus? status,
    List<QuestObjective>? objectives,
    Object? completedAt = _unset,
    Object? targetDate = _unset,
    Object? rewardText = _unset,
    Object? rewardCostCents = _unset,
    Object? rewardClaimedAt = _unset,
  }) =>
      Quest(
        id: id,
        title: title ?? this.title,
        description: identical(description, _unset)
            ? this.description
            : description as String?,
        xpReward: xpReward ?? this.xpReward,
        difficulty: difficulty ?? this.difficulty,
        status: status ?? this.status,
        objectives: objectives ?? this.objectives,
        completedAt: identical(completedAt, _unset)
            ? this.completedAt
            : completedAt as DateTime?,
        createdAt: createdAt,
        targetDate: identical(targetDate, _unset)
            ? this.targetDate
            : targetDate as DateTime?,
        rewardText: identical(rewardText, _unset)
            ? this.rewardText
            : rewardText as String?,
        rewardCostCents: identical(rewardCostCents, _unset)
            ? this.rewardCostCents
            : rewardCostCents as int?,
        rewardClaimedAt: identical(rewardClaimedAt, _unset)
            ? this.rewardClaimedAt
            : rewardClaimedAt as DateTime?,
      );
}
