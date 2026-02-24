import '../../domain/entities/wealth_stats.dart';

enum WealthLoadStatus { initial, loading, loaded, error }

class WealthState {
  final WealthLoadStatus status;
  final WealthStats? stats;
  final bool isMutating;
  final String? errorMessage;

  const WealthState({
    required this.status,
    this.stats,
    this.isMutating = false,
    this.errorMessage,
  });

  factory WealthState.initial() =>
      const WealthState(status: WealthLoadStatus.initial);

  bool get isLoading => status == WealthLoadStatus.loading;
  bool get isBusy => isLoading || isMutating;

  WealthState copyWith({
    WealthLoadStatus? status,
    WealthStats? stats,
    bool? isMutating,
    String? errorMessage,
  }) {
    return WealthState(
      status: status ?? this.status,
      stats: stats ?? this.stats,
      isMutating: isMutating ?? this.isMutating,
      errorMessage: errorMessage,
    );
  }
}
