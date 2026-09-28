import '../entities/budget_category.dart';
import '../entities/budget_transaction.dart';
import '../entities/category_rule.dart';

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

  Future<List<BudgetTransaction>> getTransactionsInRange({
    required DateTime start,
    required DateTime end,
  });

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

  // ── Statement import ───────────────────────────────────────────────────────

  /// Bank keys already stored for rows booked between [from] and [to]
  /// (inclusive), soft-deleted rows included.
  Future<Set<String>> getBankKeys({
    required DateTime from,
    required DateTime to,
  });

  Future<void> addImportedTransactions(List<NewImportedTransaction> rows);

  /// Live manual expenses in [start, end) not yet linked to a bank row.
  Future<List<BudgetTransaction>> getUnlinkedManualTransactions({
    required DateTime start,
    required DateTime end,
  });

  /// Links a manual entry to its statement row. The bank amount wins; the
  /// entry's category, note and date stay.
  Future<void> linkTransaction({
    required String id,
    required int amountCents,
    required String bankKey,
    required String bankDescription,
  });

  /// Imported rows not yet reviewed, any month.
  Future<List<BudgetTransaction>> getTransactionsNeedingReview();

  /// Sets category and note and clears needs review.
  Future<void> reviewTransaction({
    required String id,
    required String categoryId,
    String? note,
  });

  // ── Category rules ─────────────────────────────────────────────────────────

  Future<List<CategoryRule>> getCategoryRules();

  Future<CategoryRule> addCategoryRule({
    required String keyword,
    required String categoryId,
    required int priority,
  });
}
