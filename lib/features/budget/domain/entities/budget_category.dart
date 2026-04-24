import 'package:flutter/material.dart';

const budgetIconOptions = <String, IconData>{
  'coffee': Icons.coffee,
  'restaurant': Icons.restaurant,
  'shopping': Icons.shopping_bag,
  'gaming': Icons.sports_esports,
  'transport': Icons.directions_car,
  'entertainment': Icons.movie,
  'health': Icons.favorite,
  'clothing': Icons.checkroom,
  'travel': Icons.flight,
  'gift': Icons.card_giftcard,
  'gym': Icons.fitness_center,
  'book': Icons.menu_book,
  'music': Icons.music_note,
  'bar': Icons.local_bar,
  'other': Icons.more_horiz,
};

const budgetColorOptions = <Color>[
  Color(0xFF4FC3F7), // sky blue
  Color(0xFFFFD54F), // gold
  Color(0xFF26A69A), // teal
  Color(0xFFEF5350), // red
  Color(0xFFAB47BC), // purple
  Color(0xFF66BB6A), // green
  Color(0xFFFF7043), // orange
  Color(0xFFEC407A), // pink
  Color(0xFF8D6E63), // brown
  Color(0xFF78909C), // blue-grey
];

class BudgetCategory {
  final String id;
  final String userId;
  final String name;
  final String iconKey;
  final int colorIndex;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  const BudgetCategory({
    required this.id,
    required this.userId,
    required this.name,
    required this.iconKey,
    required this.colorIndex,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  Color get color =>
      budgetColorOptions[colorIndex.clamp(0, budgetColorOptions.length - 1)];

  IconData get icon => budgetIconOptions[iconKey] ?? Icons.more_horiz;

  bool get isDeleted => deletedAt != null;

  BudgetCategory copyWith({
    String? id,
    String? userId,
    String? name,
    String? iconKey,
    int? colorIndex,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return BudgetCategory(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      iconKey: iconKey ?? this.iconKey,
      colorIndex: colorIndex ?? this.colorIndex,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is BudgetCategory && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
