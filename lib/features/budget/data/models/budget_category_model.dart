import '../../domain/entities/budget_category.dart';

class BudgetCategoryModel extends BudgetCategory {
  const BudgetCategoryModel({
    required super.id,
    required super.userId,
    required super.name,
    required super.iconKey,
    required super.colorIndex,
    required super.createdAt,
    required super.updatedAt,
    super.deletedAt,
  });

  factory BudgetCategoryModel.fromMap(Map<String, dynamic> map) {
    return BudgetCategoryModel(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      name: map['name'] as String,
      iconKey: map['icon_key'] as String? ?? 'other',
      colorIndex: map['color_index'] as int? ?? 0,
      createdAt: DateTime.parse(map['created_at'] as String).toLocal(),
      updatedAt: DateTime.parse(map['updated_at'] as String).toLocal(),
      deletedAt: map['deleted_at'] != null
          ? DateTime.parse(map['deleted_at'] as String).toLocal()
          : null,
    );
  }
}
