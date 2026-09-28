import 'dart:math';

import '../../../../core/error/app_exception.dart';
import '../../domain/entities/category_rule.dart';
import '../../domain/repositories/budget_repository.dart';

class AddCategoryRuleUseCase {
  final BudgetRepository _repository;

  const AddCategoryRuleUseCase(this._repository);

  /// Saves "always categorize [keyword] as [categoryId]" in front of every
  /// existing rule: a rule you add is more specific than the seeds, and a
  /// newer one replaces an older one for the same merchant.
  Future<CategoryRule> execute({
    required String keyword,
    required String categoryId,
  }) async {
    final k = keyword.trim();
    if (k.isEmpty) {
      throw const ValidationException('Keyword cannot be empty.');
    }
    final rules = await _repository.getCategoryRules();
    final first = rules.isEmpty ? 0 : rules.map((r) => r.priority).reduce(min);
    return _repository.addCategoryRule(
      keyword: k,
      categoryId: categoryId,
      priority: first - 10,
    );
  }
}
