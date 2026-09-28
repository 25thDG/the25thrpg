import '../../domain/entities/category_rule.dart';

class CategoryRuleModel extends CategoryRule {
  const CategoryRuleModel({
    required super.id,
    required super.keyword,
    required super.categoryId,
    required super.priority,
  });

  factory CategoryRuleModel.fromMap(Map<String, dynamic> map) {
    return CategoryRuleModel(
      id: map['id'] as String,
      keyword: map['keyword'] as String,
      categoryId: map['category_id'] as String,
      priority: map['priority'] as int,
    );
  }
}
