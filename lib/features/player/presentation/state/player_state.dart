import '../../../../core/progression/level_watcher.dart';
import '../../domain/entities/activity_history.dart';
import '../../domain/entities/player_stats.dart';
import '../../domain/entities/weekly_review.dart';

enum PlayerLoadStatus { initial, loading, loaded, error }

class PlayerState {
  final PlayerLoadStatus status;
  final PlayerStats? stats;

  /// Day-by-day activity behind the calendar and the weekly review.
  final ActivityHistory? history;

  final String? errorMessage;

  /// Levels gained since the last load, waiting to be celebrated. Cleared by
  /// the page once it has shown them.
  final List<LevelUpEvent> pendingLevelUps;

  const PlayerState({
    this.status = PlayerLoadStatus.initial,
    this.stats,
    this.history,
    this.errorMessage,
    this.pendingLevelUps = const [],
  });

  bool get isLoading => status == PlayerLoadStatus.loading;

  /// Built on demand — both halves have to be present for a review to mean
  /// anything.
  WeeklyReview? get weeklyReview {
    final h = history;
    if (h == null) return null;
    return WeeklyReview.from(
      history: h,
      streakDays: stats?.streakDays ?? 0,
    );
  }

  PlayerState copyWith({
    PlayerLoadStatus? status,
    PlayerStats? stats,
    ActivityHistory? history,
    String? errorMessage,
    List<LevelUpEvent>? pendingLevelUps,
  }) {
    return PlayerState(
      status: status ?? this.status,
      stats: stats ?? this.stats,
      history: history ?? this.history,
      errorMessage: errorMessage ?? this.errorMessage,
      pendingLevelUps: pendingLevelUps ?? this.pendingLevelUps,
    );
  }
}
