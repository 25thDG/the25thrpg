import '../../domain/entities/budget_transaction.dart';

class BudgetTransactionModel extends BudgetTransaction {
  const BudgetTransactionModel({
    required super.id,
    required super.userId,
    required super.categoryId,
    required super.amountCents,
    super.note,
    required super.spentAt,
    required super.createdAt,
    required super.updatedAt,
    super.deletedAt,
    super.kind,
    super.needsReview,
    super.bankKey,
    super.bankDescription,
  });

  factory BudgetTransactionModel.fromMap(Map<String, dynamic> map) {
    return BudgetTransactionModel(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      categoryId: map['category_id'] as String,
      amountCents: map['amount_cents'] as int,
      note: map['note'] as String?,
      spentAt: DateTime.parse(map['spent_at'] as String).toLocal(),
      createdAt: DateTime.parse(map['created_at'] as String).toLocal(),
      updatedAt: DateTime.parse(map['updated_at'] as String).toLocal(),
      deletedAt: map['deleted_at'] != null
          ? DateTime.parse(map['deleted_at'] as String).toLocal()
          : null,
      kind: map['kind'] == 'refund'
          ? BudgetTransactionKind.refund
          : BudgetTransactionKind.expense,
      needsReview: map['needs_review'] as bool? ?? false,
      bankKey: map['bank_key'] as String?,
      bankDescription: map['bank_description'] as String?,
    );
  }
}
