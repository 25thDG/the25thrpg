import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/error/app_exception.dart';
import '../../domain/entities/budget_transaction.dart';
import '../models/budget_category_model.dart';
import '../models/budget_transaction_model.dart';
import '../models/category_rule_model.dart';

const _userId = '1a67d50e-4263-4923-b4bc-1bfa57426aae';

class BudgetSupabaseDatasource {
  final SupabaseClient _client;

  const BudgetSupabaseDatasource(this._client);

  // ── Categories ─────────────────────────────────────────────────────────────

  Future<List<BudgetCategoryModel>> getCategories() async {
    try {
      final rows = await _client
          .from('budget_categories')
          .select()
          .eq('user_id', _userId)
          .isFilter('deleted_at', null)
          .order('created_at', ascending: true);
      return (rows as List).map((r) => BudgetCategoryModel.fromMap(r)).toList();
    } catch (e) {
      throw NetworkException('Failed to fetch categories: $e');
    }
  }

  Future<BudgetCategoryModel> addCategory({
    required String name,
    required String iconKey,
    required int colorIndex,
  }) async {
    try {
      final row = await _client
          .from('budget_categories')
          .insert({
            'user_id': _userId,
            'name': name,
            'icon_key': iconKey,
            'color_index': colorIndex,
          })
          .select()
          .single();
      return BudgetCategoryModel.fromMap(row);
    } catch (e) {
      throw NetworkException('Failed to add category: $e');
    }
  }

  Future<BudgetCategoryModel> updateCategory({
    required String id,
    required String name,
    required String iconKey,
    required int colorIndex,
  }) async {
    try {
      final row = await _client
          .from('budget_categories')
          .update({
            'name': name,
            'icon_key': iconKey,
            'color_index': colorIndex,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', id)
          .select()
          .single();
      return BudgetCategoryModel.fromMap(row);
    } catch (e) {
      throw NetworkException('Failed to update category: $e');
    }
  }

  Future<void> deleteCategory(String id) async {
    try {
      await _client
          .from('budget_categories')
          .update({'deleted_at': DateTime.now().toUtc().toIso8601String()})
          .eq('id', id);
    } catch (e) {
      throw NetworkException('Failed to delete category: $e');
    }
  }

  // ── Transactions ───────────────────────────────────────────────────────────

  Future<List<BudgetTransactionModel>> getTransactionsForMonth(
      DateTime month) async {
    try {
      final start =
          DateTime(month.year, month.month, 1).toUtc().toIso8601String();
      final end =
          DateTime(month.year, month.month + 1, 1).toUtc().toIso8601String();

      final rows = await _client
          .from('budget_transactions')
          .select()
          .eq('user_id', _userId)
          .isFilter('deleted_at', null)
          .gte('spent_at', start)
          .lt('spent_at', end)
          .order('spent_at', ascending: false);

      return (rows as List)
          .map((r) => BudgetTransactionModel.fromMap(r))
          .toList();
    } catch (e) {
      throw NetworkException('Failed to fetch transactions: $e');
    }
  }

  Future<List<BudgetTransactionModel>> getTransactionsInRange({
    required DateTime start,
    required DateTime end,
  }) async {
    try {
      final rows = await _client
          .from('budget_transactions')
          .select()
          .eq('user_id', _userId)
          .isFilter('deleted_at', null)
          .gte('spent_at', start.toUtc().toIso8601String())
          .lt('spent_at', end.toUtc().toIso8601String())
          .order('spent_at', ascending: true);

      return (rows as List)
          .map((r) => BudgetTransactionModel.fromMap(r))
          .toList();
    } catch (e) {
      throw NetworkException('Failed to fetch transactions: $e');
    }
  }

  Future<BudgetTransactionModel> addTransaction({
    required String categoryId,
    required int amountCents,
    String? note,
    required DateTime spentAt,
  }) async {
    try {
      final row = await _client
          .from('budget_transactions')
          .insert({
            'user_id': _userId,
            'category_id': categoryId,
            'amount_cents': amountCents,
            'note': note,
            'spent_at': spentAt.toUtc().toIso8601String(),
          })
          .select()
          .single();
      return BudgetTransactionModel.fromMap(row);
    } catch (e) {
      throw NetworkException('Failed to add transaction: $e');
    }
  }

  Future<BudgetTransactionModel> updateTransaction({
    required String id,
    required String categoryId,
    required int amountCents,
    String? note,
    required DateTime spentAt,
  }) async {
    try {
      final row = await _client
          .from('budget_transactions')
          .update({
            'category_id': categoryId,
            'amount_cents': amountCents,
            'note': note,
            'spent_at': spentAt.toUtc().toIso8601String(),
            'needs_review': false,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', id)
          .select()
          .single();
      return BudgetTransactionModel.fromMap(row);
    } catch (e) {
      throw NetworkException('Failed to update transaction: $e');
    }
  }

  Future<void> deleteTransaction(String id) async {
    try {
      await _client
          .from('budget_transactions')
          .update({'deleted_at': DateTime.now().toUtc().toIso8601String()})
          .eq('id', id);
    } catch (e) {
      throw NetworkException('Failed to delete transaction: $e');
    }
  }

  // ── Statement import ───────────────────────────────────────────────────────

  Future<Set<String>> getBankKeys({
    required DateTime from,
    required DateTime to,
  }) async {
    String ymd(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}'
        '-${d.day.toString().padLeft(2, '0')}';
    try {
      // Bank keys start with the ISO booking date, so a string range on the
      // key is a date range. No deleted_at filter: a deleted import must not
      // come back.
      final rows = await _client
          .from('budget_transactions')
          .select('bank_key')
          .eq('user_id', _userId)
          .gte('bank_key', ymd(from))
          .lt('bank_key', ymd(to.add(const Duration(days: 1))));
      return {for (final r in rows as List) r['bank_key'] as String};
    } catch (e) {
      throw NetworkException('Failed to fetch imported transactions: $e');
    }
  }

  Future<void> addImportedTransactions(List<NewImportedTransaction> rows) async {
    if (rows.isEmpty) return;
    try {
      await _client.from('budget_transactions').insert([
        for (final r in rows)
          {
            'user_id': _userId,
            'category_id': r.categoryId,
            'amount_cents': r.amountCents,
            'kind': r.kind.name,
            'needs_review': true,
            'spent_at': r.spentAt.toUtc().toIso8601String(),
            'bank_key': r.bankKey,
            'bank_description': r.bankDescription,
          },
      ]);
    } catch (e) {
      throw NetworkException('Failed to save imported transactions: $e');
    }
  }

  Future<List<BudgetTransactionModel>> getUnlinkedManualTransactions({
    required DateTime start,
    required DateTime end,
  }) async {
    try {
      final rows = await _client
          .from('budget_transactions')
          .select()
          .eq('user_id', _userId)
          .isFilter('deleted_at', null)
          .isFilter('bank_key', null)
          .eq('kind', 'expense')
          .gte('spent_at', start.toUtc().toIso8601String())
          .lt('spent_at', end.toUtc().toIso8601String())
          .order('spent_at', ascending: true);
      return (rows as List)
          .map((r) => BudgetTransactionModel.fromMap(r))
          .toList();
    } catch (e) {
      throw NetworkException('Failed to fetch manual transactions: $e');
    }
  }

  Future<void> linkTransaction({
    required String id,
    required int amountCents,
    required String bankKey,
    required String bankDescription,
  }) async {
    try {
      await _client
          .from('budget_transactions')
          .update({
            'amount_cents': amountCents,
            'bank_key': bankKey,
            'bank_description': bankDescription,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', id);
    } catch (e) {
      throw NetworkException('Failed to link transaction: $e');
    }
  }

  Future<List<BudgetTransactionModel>> getTransactionsNeedingReview() async {
    try {
      final rows = await _client
          .from('budget_transactions')
          .select()
          .eq('user_id', _userId)
          .isFilter('deleted_at', null)
          .eq('needs_review', true)
          .order('spent_at', ascending: false);
      return (rows as List)
          .map((r) => BudgetTransactionModel.fromMap(r))
          .toList();
    } catch (e) {
      throw NetworkException('Failed to fetch transactions to review: $e');
    }
  }

  Future<void> reviewTransaction({
    required String id,
    required String categoryId,
    String? note,
  }) async {
    try {
      await _client
          .from('budget_transactions')
          .update({
            'category_id': categoryId,
            'note': note,
            'needs_review': false,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', id);
    } catch (e) {
      throw NetworkException('Failed to save review: $e');
    }
  }

  // ── Category rules ─────────────────────────────────────────────────────────

  Future<List<CategoryRuleModel>> getCategoryRules() async {
    try {
      final rows = await _client
          .from('budget_category_rules')
          .select()
          .eq('user_id', _userId)
          .order('priority', ascending: true);
      return (rows as List).map((r) => CategoryRuleModel.fromMap(r)).toList();
    } catch (e) {
      throw NetworkException('Failed to fetch category rules: $e');
    }
  }

  Future<CategoryRuleModel> addCategoryRule({
    required String keyword,
    required String categoryId,
    required int priority,
  }) async {
    try {
      final row = await _client
          .from('budget_category_rules')
          .insert({
            'user_id': _userId,
            'keyword': keyword,
            'category_id': categoryId,
            'priority': priority,
          })
          .select()
          .single();
      return CategoryRuleModel.fromMap(row);
    } catch (e) {
      throw NetworkException('Failed to add category rule: $e');
    }
  }
}
