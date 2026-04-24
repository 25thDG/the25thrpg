import '../entities/budget_category.dart';
import '../entities/budget_transaction.dart';

abstract class BudgetRepository {
  // ── Categories ─────────────────────────────────────────────────────────────

  Future<List<BudgetCategory>> getCategories();

  Future<BudgetCategory> addCategory({
    required String name,
    required String iconKey,
    required int colorIndex,
  });

  Future<BudgetCategory> updateCategory({
    required String id,
    required String name,
    required String iconKey,
    required int colorIndex,
  });

  Future<void> deleteCategory(String id);

  // ── Transactions ───────────────────────────────────────────────────────────

  Future<List<BudgetTransaction>> getTransactionsForMonth(DateTime month);

  Future<BudgetTransaction> addTransaction({
    required String categoryId,
    required int amountCents,
    String? note,
    required DateTime spentAt,
  });

  Future<BudgetTransaction> updateTransaction({
    required String id,
    required String categoryId,
    required int amountCents,
    String? note,
    required DateTime spentAt,
  });

  Future<void> deleteTransaction(String id);
}
