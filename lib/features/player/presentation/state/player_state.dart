import '../../domain/entities/player_stats.dart';

enum PlayerLoadStatus { initial, loading, loaded, error }

class PlayerState {
  final PlayerLoadStatus status;
  final PlayerStats? stats;
  final String? errorMessage;

  const PlayerState({
    this.status = PlayerLoadStatus.initial,
    this.stats,
    this.errorMessage,
  });

  bool get isLoading => status == PlayerLoadStatus.loading;

  PlayerState copyWith({
    PlayerLoadStatus? status,
    PlayerStats? stats,
    String? errorMessage,
  }) {
    return PlayerState(
      status: status ?? this.status,
      stats: stats ?? this.stats,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
