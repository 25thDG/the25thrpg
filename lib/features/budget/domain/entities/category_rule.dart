/// "If the merchant text contains [keyword], file it under [categoryId]."
class CategoryRule {
  final String id;
  final String keyword;
  final String categoryId;

  /// Lower runs first. Seed rules are spaced by 10 in their listed order;
  /// rules you add go in front of all of them.
  final int priority;

  const CategoryRule({
    required this.id,
    required this.keyword,
    required this.categoryId,
    required this.priority,
  });
}

/// Category of the first rule (by priority) whose keyword the description
/// contains, ignoring case. Null if none does.
String? categorize(String description, List<CategoryRule> rules) {
  final text = description.toLowerCase();
  final ordered = [...rules]..sort((a, b) => a.priority.compareTo(b.priority));
  for (final r in ordered) {
    if (text.contains(r.keyword.toLowerCase())) return r.categoryId;
  }
  return null;
}
