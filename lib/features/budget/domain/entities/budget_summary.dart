import 'budget_category.dart';
import 'budget_transaction.dart';

/// Fixed monthly budget in cents (€300.00).
const kMonthlyBudgetCents = 30000;

/// Fraction at which a warning is shown (80 %).
const kBudgetWarningFraction = 0.8;

class BudgetSummary {
  final int totalSpentCents;
  final Map<BudgetCategory, int> categoryTotals;
  final List<BudgetTransaction> transactions;
  final List<BudgetCategory> allCategories;

  const BudgetSummary({
    required this.totalSpentCents,
    required this.categoryTotals,
    required this.transactions,
    required this.allCategories,
  });

  double get spentFraction =>
      (totalSpentCents / kMonthlyBudgetCents).clamp(0.0, 1.0);

  int get remainingCents =>
      (kMonthlyBudgetCents - totalSpentCents).clamp(0, kMonthlyBudgetCents);

  double get spentEur => totalSpentCents / 100.0;
  double get remainingEur => remainingCents / 100.0;

  bool get isWarning => totalSpentCents >= kMonthlyBudgetCents * kBudgetWarningFraction;
  bool get isOverBudget => totalSpentCents >= kMonthlyBudgetCents;
  bool get hasTransactions => transactions.isNotEmpty;
}
