class CarSnapshot {
  final String id;
  final int odometerKm;

  /// Calendar day the odometer was read. At most one per day.
  final DateTime snapshotDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  const CarSnapshot({
    required this.id,
    required this.odometerKm,
    required this.snapshotDate,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  bool get isDeleted => deletedAt != null;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is CarSnapshot && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
