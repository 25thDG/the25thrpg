import 'package:flutter/foundation.dart';

import '../../../../core/error/app_exception.dart';
import '../../application/use_cases/add_category_rule_use_case.dart';
import '../../application/use_cases/add_category_use_case.dart';
import '../../application/use_cases/add_transaction_use_case.dart';
import '../../application/use_cases/delete_category_use_case.dart';
import '../../application/use_cases/delete_transaction_use_case.dart';
import '../../application/use_cases/export_transactions_use_case.dart';
import '../../application/use_cases/get_budget_summary_use_case.dart';
import '../../application/use_cases/import_statement_use_case.dart';
import '../../application/use_cases/review_transaction_use_case.dart';
import '../../application/use_cases/update_category_use_case.dart';
import '../../application/use_cases/update_transaction_use_case.dart';
import '../state/budget_state.dart';

class BudgetController extends ChangeNotifier {
  final GetBudgetSummaryUseCase _getSummary;
  final AddTransactionUseCase _addTransaction;
  final UpdateTransactionUseCase _updateTransaction;
  final DeleteTransactionUseCase _deleteTransaction;
  final AddCategoryUseCase _addCategory;
  final UpdateCategoryUseCase _updateCategory;
  final DeleteCategoryUseCase _deleteCategory;
  final ExportTransactionsUseCase _exportTransactions;
  final AddCategoryRuleUseCase _addCategoryRule;
  final ImportStatementUseCase _importStatement;
  final ReviewTransactionUseCase _reviewTransaction;

  BudgetState _state = BudgetState.initial();
  BudgetState get state => _state;

  BudgetController({
    required GetBudgetSummaryUseCase getSummary,
    required AddTransactionUseCase addTransaction,
    required UpdateTransactionUseCase updateTransaction,
    required DeleteTransactionUseCase deleteTransaction,
    required AddCategoryUseCase addCategory,
    required UpdateCategoryUseCase updateCategory,
    required DeleteCategoryUseCase deleteCategory,
    required ExportTransactionsUseCase exportTransactions,
    required AddCategoryRuleUseCase addCategoryRule,
    required ImportStatementUseCase importStatement,
    required ReviewTransactionUseCase reviewTransaction,
  })  : _getSummary = getSummary,
        _addTransaction = addTransaction,
        _updateTransaction = updateTransaction,
        _deleteTransaction = deleteTransaction,
        _addCategory = addCategory,
        _updateCategory = updateCategory,
        _deleteCategory = deleteCategory,
        _exportTransactions = exportTransactions,
        _addCategoryRule = addCategoryRule,
        _importStatement = importStatement,
        _reviewTransaction = reviewTransaction;

  void _emit(BudgetState next) {
    _state = next;
    notifyListeners();
  }

  Future<void> load() async {
    _emit(_state.copyWith(status: BudgetLoadStatus.loading));
    try {
      final summary = await _getSummary.execute(_state.selectedMonth);
      _emit(_state.copyWith(status: BudgetLoadStatus.loaded, summary: summary));
    } catch (e) {
      _emit(_state.copyWith(
          status: BudgetLoadStatus.error, errorMessage: e.toString()));
    }
  }

  void previousMonth() {
    final m = _state.selectedMonth;
    _emit(_state.copyWith(
        selectedMonth: DateTime(m.year, m.month - 1, 1)));
    load();
  }

  void nextMonth() {
    final m = _state.selectedMonth;
    final next = DateTime(m.year, m.month + 1, 1);
    if (next.isAfter(DateTime.now())) return;
    _emit(_state.copyWith(selectedMonth: next));
    load();
  }

  bool get canGoNext {
    final m = _state.selectedMonth;
    return DateTime(m.year, m.month + 1, 1).isBefore(DateTime.now());
  }

  // ── Transactions ───────────────────────────────────────────────────────────

  Future<String?> addTransaction({
    required String categoryId,
    required int amountCents,
    String? note,
    required DateTime spentAt,
  }) async {
    try {
      await _addTransaction.execute(
        categoryId: categoryId,
        amountCents: amountCents,
        note: note,
        spentAt: spentAt,
      );
      await load();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> updateTransaction({
    required String id,
    required String categoryId,
    required int amountCents,
    String? note,
    required DateTime spentAt,
  }) async {
    try {
      await _updateTransaction.execute(
        id: id,
        categoryId: categoryId,
        amountCents: amountCents,
        note: note,
        spentAt: spentAt,
      );
      await load();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> deleteTransaction(String id) async {
    try {
      await _deleteTransaction.execute(id);
      await load();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  // ── Categories ─────────────────────────────────────────────────────────────

  Future<String?> addCategory({
    required String name,
    required String iconKey,
    required int colorIndex,
  }) async {
    try {
      await _addCategory.execute(
          name: name, iconKey: iconKey, colorIndex: colorIndex);
      await load();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> updateCategory({
    required String id,
    required String name,
    required String iconKey,
    required int colorIndex,
  }) async {
    try {
      await _updateCategory.execute(
          id: id, name: name, iconKey: iconKey, colorIndex: colorIndex);
      await load();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> deleteCategory(String id) async {
    try {
      await _deleteCategory.execute(id);
      await load();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  // ── Statement import ───────────────────────────────────────────────────────

  /// On failure `error` says why and nothing was imported.
  Future<({ImportResult? result, String? error})> importStatement(
      Uint8List pdfBytes) async {
    try {
      final result = await _importStatement.execute(pdfBytes);
      await load();
      return (result: result, error: null);
    } on AppException catch (e) {
      return (result: null, error: e.message);
    } catch (e) {
      return (result: null, error: e.toString());
    }
  }

  /// Doesn't reload — the review sheet reloads once when it closes.
  Future<String?> reviewTransaction({
    required String id,
    required String categoryId,
    String? note,
  }) async {
    try {
      await _reviewTransaction.execute(
          id: id, categoryId: categoryId, note: note);
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  // ── Category rules ─────────────────────────────────────────────────────────

  Future<String?> addCategoryRule({
    required String keyword,
    required String categoryId,
  }) async {
    try {
      await _addCategoryRule.execute(keyword: keyword, categoryId: categoryId);
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  // ── Export ─────────────────────────────────────────────────────────────────

  Future<ExportBundle> buildExportBundle({
    required DateTime start,
    required DateTime end,
  }) =>
      _exportTransactions.execute(start: start, end: end);
}
