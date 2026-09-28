enum BudgetTransactionKind { expense, refund }

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

  /// A refund is stored with a positive [amountCents] and subtracts from
  /// every total — use [signedAmountCents] when summing.
  final BudgetTransactionKind kind;

  /// Imported from a bank statement and not yet looked at.
  final bool needsReview;

  /// Identity of the statement row this came from (see
  /// `BankTransaction.dedupeKey`); null for cash entries.
  final String? bankKey;

  /// Merchant text from the statement.
  final String? bankDescription;

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
    this.kind = BudgetTransactionKind.expense,
    this.needsReview = false,
    this.bankKey,
    this.bankDescription,
  });

  bool get isRefund => kind == BudgetTransactionKind.refund;
  bool get isImported => bankKey != null;
  int get signedAmountCents => isRefund ? -amountCents : amountCents;

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
    BudgetTransactionKind? kind,
    bool? needsReview,
    String? bankKey,
    String? bankDescription,
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
      kind: kind ?? this.kind,
      needsReview: needsReview ?? this.needsReview,
      bankKey: bankKey ?? this.bankKey,
      bankDescription: bankDescription ?? this.bankDescription,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is BudgetTransaction && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// A statement row about to be inserted as a transaction.
class NewImportedTransaction {
  final String categoryId;
  final int amountCents;
  final BudgetTransactionKind kind;
  final DateTime spentAt;
  final String bankKey;
  final String bankDescription;

  const NewImportedTransaction({
    required this.categoryId,
    required this.amountCents,
    required this.kind,
    required this.spentAt,
    required this.bankKey,
    required this.bankDescription,
  });
}
