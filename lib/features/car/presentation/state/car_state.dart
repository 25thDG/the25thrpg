import '../../domain/entities/car_stats.dart';

enum CarLoadStatus { initial, loading, loaded, error }

class CarState {
  final CarLoadStatus status;
  final CarStats? stats;
  final bool isMutating;
  final String? errorMessage;

  const CarState({
    required this.status,
    this.stats,
    this.isMutating = false,
    this.errorMessage,
  });

  factory CarState.initial() => const CarState(status: CarLoadStatus.initial);

  bool get isLoading => status == CarLoadStatus.loading;
  bool get isBusy => isLoading || isMutating;

  CarState copyWith({
    CarLoadStatus? status,
    CarStats? stats,
    bool? isMutating,
    String? errorMessage,
  }) {
    return CarState(
      status: status ?? this.status,
      stats: stats ?? this.stats,
      isMutating: isMutating ?? this.isMutating,
      errorMessage: errorMessage,
    );
  }
}
