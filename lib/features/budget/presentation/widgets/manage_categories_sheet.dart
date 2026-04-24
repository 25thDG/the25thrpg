import 'package:flutter/material.dart';

import '../../../../core/theme/rpg_colors.dart';
import '../../domain/entities/budget_category.dart';

class ManageCategoriesSheet extends StatelessWidget {
  final List<BudgetCategory> categories;
  final Future<String?> Function({
    required String name,
    required String iconKey,
    required int colorIndex,
  }) onAdd;
  final Future<String?> Function({
    required String id,
    required String name,
    required String iconKey,
    required int colorIndex,
  }) onUpdate;
  final Future<String?> Function(String id) onDelete;

  const ManageCategoriesSheet({
    super.key,
    required this.categories,
    required this.onAdd,
    required this.onUpdate,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    return Container(
      decoration: BoxDecoration(
        color: RpgColors.panelBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        border: Border.all(color: RpgColors.border),
      ),
      padding: EdgeInsets.fromLTRB(24, 20, 24, 24 + bottomPad),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 3,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: RpgColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Row(
            children: [
              const Text(
                'CATEGORIES',
                style: TextStyle(
                  color: RpgColors.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 2.4,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () => _showCategoryForm(context, null),
                icon: const Icon(Icons.add, size: 16,
                    color: Color(0xFF4FC3F7)),
                label: const Text(
                  'NEW',
                  style: TextStyle(
                    color: Color(0xFF4FC3F7),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
                style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (categories.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(
                  'No categories yet. Create one to start tracking.',
                  style: const TextStyle(
                      color: RpgColors.textMuted, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          else
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.45,
              ),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: categories.length,
                separatorBuilder: (_, _) =>
                    Container(height: 0.5, color: RpgColors.divider),
                itemBuilder: (_, i) {
                  final cat = categories[i];
                  return _CategoryRow(
                    category: cat,
                    onEdit: () => _showCategoryForm(context, cat),
                    onDelete: () => _confirmDelete(context, cat),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  void _showCategoryForm(BuildContext context, BudgetCategory? existing) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _CategoryFormSheet(
        existing: existing,
        onSave: existing == null
            ? ({required name, required iconKey, required colorIndex}) =>
                onAdd(name: name, iconKey: iconKey, colorIndex: colorIndex)
            : ({required name, required iconKey, required colorIndex}) =>
                onUpdate(
                    id: existing.id,
                    name: name,
                    iconKey: iconKey,
                    colorIndex: colorIndex),
      ),
    );
  }

  void _confirmDelete(BuildContext context, BudgetCategory cat) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: RpgColors.panelBg,
        title: Text('Delete "${cat.name}"?',
            style: const TextStyle(
                color: RpgColors.textPrimary, fontSize: 15)),
        content: const Text(
            'Existing transactions will remain but lose their category.',
            style: TextStyle(color: RpgColors.textMuted, fontSize: 12)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(color: RpgColors.textMuted)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              onDelete(cat.id);
            },
            child: const Text('Delete',
                style: TextStyle(color: Color(0xFFEF5350))),
          ),
        ],
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  final BudgetCategory category;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CategoryRow({
    required this.category,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onEdit,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: category.color.withValues(alpha: 0.12),
                border: Border.all(
                    color: category.color.withValues(alpha: 0.35)),
              ),
              child: Icon(category.icon, size: 16, color: category.color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                category.name,
                style: const TextStyle(
                  color: RpgColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit_outlined,
                  size: 16, color: RpgColors.textMuted),
              onPressed: onEdit,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.delete_outline,
                  size: 16, color: Color(0xFFEF5350)),
              onPressed: onDelete,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Category form sheet ───────────────────────────────────────────────────────

class _CategoryFormSheet extends StatefulWidget {
  final BudgetCategory? existing;
  final Future<String?> Function({
    required String name,
    required String iconKey,
    required int colorIndex,
  }) onSave;

  const _CategoryFormSheet({required this.existing, required this.onSave});

  @override
  State<_CategoryFormSheet> createState() => _CategoryFormSheetState();
}

class _CategoryFormSheetState extends State<_CategoryFormSheet> {
  late final TextEditingController _nameCtrl;
  late String _iconKey;
  late int _colorIndex;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl =
        TextEditingController(text: widget.existing?.name ?? '');
    _iconKey = widget.existing?.iconKey ?? 'other';
    _colorIndex = widget.existing?.colorIndex ?? 0;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) return;
    setState(() => _loading = true);
    final error = await widget.onSave(
        name: _nameCtrl.text.trim(),
        iconKey: _iconKey,
        colorIndex: _colorIndex);
    if (!mounted) return;
    setState(() => _loading = false);
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(error),
            backgroundColor: const Color(0xFFEF5350)),
      );
    } else {
      Navigator.pop(context);
      Navigator.pop(context); // close parent sheet too
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final selectedColor = budgetColorOptions[_colorIndex];

    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: RpgColors.panelBg,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(16)),
          border: Border.all(color: RpgColors.border),
        ),
        padding: EdgeInsets.fromLTRB(24, 20, 24, 24 + bottomPad),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 3,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: RpgColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            Text(
              widget.existing == null ? 'NEW CATEGORY' : 'EDIT CATEGORY',
              style: const TextStyle(
                color: RpgColors.textMuted,
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 2.4,
              ),
            ),
            const SizedBox(height: 16),

            // Name field
            TextField(
              controller: _nameCtrl,
              autofocus: true,
              style: const TextStyle(
                  color: RpgColors.textPrimary, fontSize: 16),
              decoration: InputDecoration(
                hintText: 'Category name',
                hintStyle: const TextStyle(
                    color: RpgColors.textMuted, fontSize: 16),
                filled: true,
                fillColor: RpgColors.panelBgAlt,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: const BorderSide(color: RpgColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: const BorderSide(color: RpgColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide:
                      BorderSide(color: selectedColor),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
            const SizedBox(height: 20),

            // Icon picker
            const Text(
              'ICON',
              style: TextStyle(
                color: RpgColors.textMuted,
                fontSize: 9,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.8,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: budgetIconOptions.entries.map((e) {
                final selected = e.key == _iconKey;
                return GestureDetector(
                  onTap: () => setState(() => _iconKey = e.key),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: selected
                          ? selectedColor.withValues(alpha: 0.15)
                          : Colors.transparent,
                      border: Border.all(
                        color: selected ? selectedColor : RpgColors.border,
                        width: selected ? 1.5 : 1,
                      ),
                    ),
                    child: Icon(e.value,
                        size: 18,
                        color: selected
                            ? selectedColor
                            : RpgColors.textMuted),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Color picker
            const Text(
              'COLOR',
              style: TextStyle(
                color: RpgColors.textMuted,
                fontSize: 9,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.8,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(budgetColorOptions.length, (i) {
                final selected = i == _colorIndex;
                final c = budgetColorOptions[i];
                return GestureDetector(
                    onTap: () => setState(() => _colorIndex = i),
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: c,
                        border: Border.all(
                          color: selected
                              ? Colors.white.withValues(alpha: 0.8)
                              : Colors.transparent,
                          width: 2,
                        ),
                        boxShadow: selected
                            ? [
                                BoxShadow(
                                    color: c.withValues(alpha: 0.5),
                                    blurRadius: 8,
                                    spreadRadius: 1)
                              ]
                            : null,
                      ),
                    ),
                  );
              }),
            ),
            const SizedBox(height: 24),

            // Save button
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _loading ? null : _save,
                style: FilledButton.styleFrom(
                  backgroundColor: selectedColor,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6)),
                ),
                child: _loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.black),
                      )
                    : Text(
                        widget.existing == null ? 'CREATE' : 'SAVE',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          letterSpacing: 1.4,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
