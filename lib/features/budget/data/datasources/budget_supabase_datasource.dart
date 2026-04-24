import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/error/app_exception.dart';
import '../models/budget_category_model.dart';
import '../models/budget_transaction_model.dart';

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
}
