import '../../domain/entities/wealth_snapshot.dart';

class WealthSnapshotModel extends WealthSnapshot {
  const WealthSnapshotModel({
    required super.id,
    required super.netWorthEur,
    required super.snapshotMonth,
    required super.createdAt,
    required super.updatedAt,
    super.deletedAt,
  });

  factory WealthSnapshotModel.fromMap(Map<String, dynamic> map) {
    return WealthSnapshotModel(
      id: map['id'] as String,
      // numeric comes back as String or num depending on Supabase version.
      netWorthEur: double.parse(map['net_worth_eur'].toString()),
      // date type — parse as-is, no timezone conversion needed.
      snapshotMonth: DateTime.parse(map['snapshot_month'] as String),
      createdAt: DateTime.parse(map['created_at'] as String).toLocal(),
      updatedAt: DateTime.parse(map['updated_at'] as String).toLocal(),
      deletedAt: map['deleted_at'] != null
          ? DateTime.parse(map['deleted_at'] as String).toLocal()
          : null,
    );
  }
}
