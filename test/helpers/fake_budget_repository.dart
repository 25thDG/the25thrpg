import 'package:the25thrpg/features/budget/domain/entities/budget_category.dart';
import 'package:the25thrpg/features/budget/domain/entities/budget_transaction.dart';
import 'package:the25thrpg/features/budget/domain/entities/category_rule.dart';
import 'package:the25thrpg/features/budget/domain/repositories/budget_repository.dart';

/// In-memory [BudgetRepository] for use case tests.
class FakeBudgetRepository implements BudgetRepository {
  final categories = <BudgetCategory>[];

  /// All rows, soft-deleted ones included.
  final transactions = <BudgetTransaction>[];
  final rules = <CategoryRule>[];
  var _nextId = 0;

  String _id() => 'id${_nextId++}';

  List<BudgetTransaction> get live =>
      transactions.where((t) => !t.isDeleted).toList();

  BudgetCategory category(String name) =>
      categories.firstWhere((c) => c.name == name);

  BudgetTransaction addManual({
    required String categoryName,
    required int amountCents,
    required DateTime spentAt,
    String? note,
  }) {
    final t = BudgetTransaction(
      id: _id(),
      userId: 'u',
      categoryId: category(categoryName).id,
      amountCents: amountCents,
      note: note,
      spentAt: spentAt,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );
    transactions.add(t);
    return t;
  }

  @override
  Future<List<BudgetCategory>> getCategories() async =>
      categories.where((c) => !c.isDeleted).toList();

  @override
  Future<BudgetCategory> addCategory({
    required String name,
    required String iconKey,
    required int colorIndex,
  }) async {
    final c = BudgetCategory(
      id: _id(),
      userId: 'u',
      name: name,
      iconKey: iconKey,
      colorIndex: colorIndex,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );
    categories.add(c);
    return c;
  }

  @override
  Future<BudgetCategory> updateCategory({
    required String id,
    required String name,
    required String iconKey,
    required int colorIndex,
  }) => throw UnimplementedError();

  @override
  Future<void> deleteCategory(String id) => throw UnimplementedError();

  @override
  Future<List<BudgetTransaction>> getTransactionsForMonth(DateTime month) =>
      throw UnimplementedError();

  @override
  Future<List<BudgetTransaction>> getTransactionsInRange({
    required DateTime start,
    required DateTime end,
  }) => throw UnimplementedError();

  @override
  Future<BudgetTransaction> addTransaction({
    required String categoryId,
    required int amountCents,
    String? note,
    required DateTime spentAt,
  }) => throw UnimplementedError();

  @override
  Future<BudgetTransaction> updateTransaction({
    required String id,
    required String categoryId,
    required int amountCents,
    String? note,
    required DateTime spentAt,
  }) => throw UnimplementedError();

  @override
  Future<void> deleteTransaction(String id) async {
    final i = transactions.indexWhere((t) => t.id == id);
    transactions[i] = transactions[i].copyWith(deletedAt: DateTime(2026));
  }

  @override
  Future<Set<String>> getBankKeys({
    required DateTime from,
    required DateTime to,
  }) async {
    final end = to.add(const Duration(days: 1));
    return {
      for (final t in transactions)
        if (t.bankKey != null) t.bankKey!,
    }.where((k) {
      final d = DateTime.parse(k.split('|').first);
      return !d.isBefore(from) && d.isBefore(end);
    }).toSet();
  }

  @override
  Future<void> addImportedTransactions(
    List<NewImportedTransaction> rows,
  ) async {
    for (final r in rows) {
      transactions.add(
        BudgetTransaction(
          id: _id(),
          userId: 'u',
          categoryId: r.categoryId,
          amountCents: r.amountCents,
          spentAt: r.spentAt,
          createdAt: DateTime(2026),
          updatedAt: DateTime(2026),
          kind: r.kind,
          needsReview: true,
          bankKey: r.bankKey,
          bankDescription: r.bankDescription,
        ),
      );
    }
  }

  @override
  Future<List<BudgetTransaction>> getUnlinkedManualTransactions({
    required DateTime start,
    required DateTime end,
  }) async =>
      live
          .where((t) =>
              t.bankKey == null &&
              !t.isRefund &&
              !t.spentAt.isBefore(start) &&
              t.spentAt.isBefore(end))
          .toList();

  @override
  Future<void> linkTransaction({
    required String id,
    required int amountCents,
    required String bankKey,
    required String bankDescription,
  }) async {
    final i = transactions.indexWhere((t) => t.id == id);
    transactions[i] = transactions[i].copyWith(
      amountCents: amountCents,
      bankKey: bankKey,
      bankDescription: bankDescription,
    );
  }

  @override
  Future<List<BudgetTransaction>> getTransactionsNeedingReview() async =>
      live.where((t) => t.needsReview).toList();

  @override
  Future<void> reviewTransaction({
    required String id,
    required String categoryId,
    String? note,
  }) async {
    final i = transactions.indexWhere((t) => t.id == id);
    transactions[i] = transactions[i].copyWith(
      categoryId: categoryId,
      note: note,
      needsReview: false,
    );
  }

  @override
  Future<List<CategoryRule>> getCategoryRules() async => [...rules];

  @override
  Future<CategoryRule> addCategoryRule({
    required String keyword,
    required String categoryId,
    required int priority,
  }) async {
    final r = CategoryRule(
      id: _id(),
      keyword: keyword,
      categoryId: categoryId,
      priority: priority,
    );
    rules.add(r);
    return r;
  }
}
