import '../../domain/entities/budget_category.dart';
import '../../domain/entities/budget_transaction.dart';
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
}
