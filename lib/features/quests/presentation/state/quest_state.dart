import '../../domain/entities/quest.dart';

enum QuestLoadStatus { initial, loading, loaded, error }

class QuestState {
  final QuestLoadStatus status;
  final List<Quest> quests;
  final bool isMutating;
  final String? errorMessage;

  List<Quest> get activeQuests =>
      quests.where((q) => q.status == QuestStatus.active).toList();

  List<Quest> get completedQuests =>
      quests.where((q) => q.status == QuestStatus.completed).toList();

  int get totalXpEarned =>
      completedQuests.fold(0, (sum, q) => sum + q.xpReward);

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
