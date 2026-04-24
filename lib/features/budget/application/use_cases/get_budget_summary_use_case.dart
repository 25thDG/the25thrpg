import '../../domain/entities/budget_category.dart';
import '../../domain/entities/budget_summary.dart';
import '../../domain/repositories/budget_repository.dart';

class GetBudgetSummaryUseCase {
  final BudgetRepository _repository;

  const GetBudgetSummaryUseCase(this._repository);

  Future<BudgetSummary> execute(DateTime month) async {
    final categories = await _repository.getCategories();
    final transactions = await _repository.getTransactionsForMonth(month);

    final categoryMap = {for (final c in categories) c.id: c};

    // Tally cents per category
    final totals = <String, int>{};
    int grandTotal = 0;
    for (final t in transactions) {
      totals[t.categoryId] = (totals[t.categoryId] ?? 0) + t.amountCents;
      grandTotal += t.amountCents;
    }

    final categoryTotals = <BudgetCategory, int>{};
    for (final entry in totals.entries) {
      final cat = categoryMap[entry.key];
      if (cat != null) categoryTotals[cat] = entry.value;
    }

    return BudgetSummary(
      totalSpentCents: grandTotal,
      categoryTotals: categoryTotals,
      transactions: transactions,
      allCategories: categories,
    );
  }
}
