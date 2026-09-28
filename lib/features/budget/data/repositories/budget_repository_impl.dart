import '../../domain/entities/budget_category.dart';
import '../../domain/entities/budget_transaction.dart';
import '../../domain/entities/category_rule.dart';
import '../../domain/repositories/budget_repository.dart';
import '../datasources/budget_supabase_datasource.dart';

class BudgetRepositoryImpl implements BudgetRepository {
  final BudgetSupabaseDatasource _datasource;

  const BudgetRepositoryImpl(this._datasource);

  @override
  Future<List<BudgetCategory>> getCategories() =>
      _datasource.getCategories();

  @override
  Future<BudgetCategory> addCategory({
    required String name,
    required String iconKey,
    required int colorIndex,
  }) =>
      _datasource.addCategory(
          name: name, iconKey: iconKey, colorIndex: colorIndex);

  @override
  Future<BudgetCategory> updateCategory({
    required String id,
    required String name,
    required String iconKey,
    required int colorIndex,
  }) =>
      _datasource.updateCategory(
          id: id, name: name, iconKey: iconKey, colorIndex: colorIndex);

  @override
  Future<void> deleteCategory(String id) => _datasource.deleteCategory(id);

  @override
  Future<List<BudgetTransaction>> getTransactionsForMonth(DateTime month) =>
      _datasource.getTransactionsForMonth(month);

  @override
  Future<List<BudgetTransaction>> getTransactionsInRange({
    required DateTime start,
    required DateTime end,
  }) =>
      _datasource.getTransactionsInRange(start: start, end: end);

  @override
  Future<BudgetTransaction> addTransaction({
    required String categoryId,
    required int amountCents,
    String? note,
    required DateTime spentAt,
  }) =>
      _datasource.addTransaction(
          categoryId: categoryId,
          amountCents: amountCents,
          note: note,
          spentAt: spentAt);

  @override
  Future<BudgetTransaction> updateTransaction({
    required String id,
    required String categoryId,
    required int amountCents,
    String? note,
    required DateTime spentAt,
  }) =>
      _datasource.updateTransaction(
          id: id,
          categoryId: categoryId,
          amountCents: amountCents,
          note: note,
          spentAt: spentAt);

  @override
  Future<void> deleteTransaction(String id) =>
      _datasource.deleteTransaction(id);

  @override
  Future<Set<String>> getBankKeys({
    required DateTime from,
    required DateTime to,
  }) =>
      _datasource.getBankKeys(from: from, to: to);

  @override
  Future<void> addImportedTransactions(List<NewImportedTransaction> rows) =>
      _datasource.addImportedTransactions(rows);

  @override
  Future<List<BudgetTransaction>> getUnlinkedManualTransactions({
    required DateTime start,
    required DateTime end,
  }) =>
      _datasource.getUnlinkedManualTransactions(start: start, end: end);

  @override
  Future<void> linkTransaction({
    required String id,
    required int amountCents,
    required String bankKey,
    required String bankDescription,
  }) =>
      _datasource.linkTransaction(
          id: id,
          amountCents: amountCents,
          bankKey: bankKey,
          bankDescription: bankDescription);

  @override
  Future<List<BudgetTransaction>> getTransactionsNeedingReview() =>
      _datasource.getTransactionsNeedingReview();

  @override
  Future<void> reviewTransaction({
    required String id,
    required String categoryId,
    String? note,
  }) =>
      _datasource.reviewTransaction(
          id: id, categoryId: categoryId, note: note);

  @override
  Future<List<CategoryRule>> getCategoryRules() =>
      _datasource.getCategoryRules();

  @override
  Future<CategoryRule> addCategoryRule({
    required String keyword,
    required String categoryId,
    required int priority,
  }) =>
      _datasource.addCategoryRule(
          keyword: keyword, categoryId: categoryId, priority: priority);
}
