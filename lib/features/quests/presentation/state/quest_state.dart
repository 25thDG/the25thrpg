import '../../domain/entities/quest.dart';

enum QuestLoadStatus { initial, loading, loaded, error }

class QuestState {
  final QuestLoadStatus status;
  final List<Quest> quests;
  final bool isMutating;
  final String? errorMessage;

  /// Open quests by urgency: most overdue first, then the nearest deadline,
  /// then those without one. Ties keep the newest-first order they load in.
  List<Quest> get activeQuests {
    final active = quests.indexed
        .where((e) => e.$2.status == QuestStatus.active)
        .toList()
      ..sort((a, b) {
        final da = a.$2.daysLeft;
        final db = b.$2.daysLeft;
        if (da != db) {
          if (da == null) return 1;
          if (db == null) return -1;
          return da.compareTo(db);
        }
        return a.$1.compareTo(b.$1);
      });
    return [for (final e in active) e.$2];
  }

  List<Quest> get completedQuests =>
      quests.where((q) => q.status == QuestStatus.completed).toList();

  const QuestState({
    this.status = QuestLoadStatus.initial,
    this.quests = const [],
    this.isMutating = false,
    this.errorMessage,
  });

  QuestState copyWith({
    QuestLoadStatus? status,
    List<Quest>? quests,
    bool? isMutating,
    String? errorMessage,
  }) =>
      QuestState(
        status: status ?? this.status,
        quests: quests ?? this.quests,
        isMutating: isMutating ?? this.isMutating,
        errorMessage: errorMessage ?? this.errorMessage,
      );
}
