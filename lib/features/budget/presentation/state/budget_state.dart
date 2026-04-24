import '../../domain/entities/budget_summary.dart';

enum BudgetLoadStatus { initial, loading, loaded, error }

class BudgetState {
  final BudgetLoadStatus status;
  final BudgetSummary? summary;
  final DateTime selectedMonth;
  final String? errorMessage;

  const BudgetState({
    required this.status,
    this.summary,
    required this.selectedMonth,
    this.errorMessage,
  });

  factory BudgetState.initial() => BudgetState(
        status: BudgetLoadStatus.initial,
        selectedMonth: _firstOfMonth(DateTime.now()),
      );

  static DateTime _firstOfMonth(DateTime d) => DateTime(d.year, d.month, 1);

  bool get isLoading => status == BudgetLoadStatus.loading;

  BudgetState copyWith({
    BudgetLoadStatus? status,
    BudgetSummary? summary,
    DateTime? selectedMonth,
    String? errorMessage,
  }) {
    return BudgetState(
      status: status ?? this.status,
      summary: summary ?? this.summary,
      selectedMonth: selectedMonth ?? this.selectedMonth,
      errorMessage: errorMessage,
    );
  }
}
