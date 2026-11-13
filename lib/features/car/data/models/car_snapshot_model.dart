import '../../domain/entities/car_snapshot.dart';

class CarSnapshotModel extends CarSnapshot {
  const CarSnapshotModel({
    required super.id,
    required super.odometerKm,
    required super.snapshotDate,
    required super.createdAt,
    required super.updatedAt,
    super.deletedAt,
  });

  factory CarSnapshotModel.fromMap(Map<String, dynamic> map) {
    return CarSnapshotModel(
      id: map['id'] as String,
      odometerKm: (map['odometer_km'] as num).toInt(),
      // date type — parse as-is, no timezone conversion needed.
      snapshotDate: DateTime.parse(map['snapshot_date'] as String),
      createdAt: DateTime.parse(map['created_at'] as String).toLocal(),
      updatedAt: DateTime.parse(map['updated_at'] as String).toLocal(),
      deletedAt: map['deleted_at'] != null
          ? DateTime.parse(map['deleted_at'] as String).toLocal()
          : null,
    );
  }
}
