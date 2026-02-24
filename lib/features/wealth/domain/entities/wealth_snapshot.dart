class WealthSnapshot {
  final String id;
  final double netWorthEur;

  /// Always stored as the first day of the month.
  final DateTime snapshotMonth;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  const WealthSnapshot({
    required this.id,
    required this.netWorthEur,
    required this.snapshotMonth,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  bool get isDeleted => deletedAt != null;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is WealthSnapshot && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
