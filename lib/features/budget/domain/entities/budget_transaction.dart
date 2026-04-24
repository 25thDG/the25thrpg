class BudgetTransaction {
  final String id;
  final String userId;
  final String categoryId;
  final int amountCents;
  final String? note;
  final DateTime spentAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  const BudgetTransaction({
    required this.id,
    required this.userId,
    required this.categoryId,
    required this.amountCents,
    this.note,
    required this.spentAt,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  double get amountEur => amountCents / 100.0;
  bool get isDeleted => deletedAt != null;

  BudgetTransaction copyWith({
    String? id,
    String? userId,
    String? categoryId,
    int? amountCents,
    String? note,
    DateTime? spentAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return BudgetTransaction(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      categoryId: categoryId ?? this.categoryId,
      amountCents: amountCents ?? this.amountCents,
      note: note ?? this.note,
      spentAt: spentAt ?? this.spentAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is BudgetTransaction && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
