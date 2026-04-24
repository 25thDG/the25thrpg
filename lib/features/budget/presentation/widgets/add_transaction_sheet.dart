import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/rpg_colors.dart';
import '../../domain/entities/budget_category.dart';
import '../../domain/entities/budget_transaction.dart';

class AddTransactionSheet extends StatefulWidget {
  final List<BudgetCategory> categories;
  final BudgetTransaction? initialTransaction;
  final Future<String?> Function({
    required String categoryId,
    required int amountCents,
    String? note,
    required DateTime spentAt,
  }) onSave;

  const AddTransactionSheet({
    super.key,
    required this.categories,
    required this.onSave,
    this.initialTransaction,
  });

  @override
  State<AddTransactionSheet> createState() => _AddTransactionSheetState();
}

class _AddTransactionSheetState extends State<AddTransactionSheet> {
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  BudgetCategory? _selectedCategory;
  DateTime _spentAt = DateTime.now();
  bool _loading = false;

  bool get _isEditing => widget.initialTransaction != null;

  @override
  void initState() {
    super.initState();
    final tx = widget.initialTransaction;
    if (tx != null) {
      _amountCtrl.text =
          (tx.amountCents / 100).toStringAsFixed(2);
      _noteCtrl.text = tx.note ?? '';
      _spentAt = tx.spentAt;
      _selectedCategory = widget.categories
          .where((c) => c.id == tx.categoryId)
          .firstOrNull;
    } else if (widget.categories.isNotEmpty) {
      _selectedCategory = widget.categories.first;
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) return;

    final euroStr = _amountCtrl.text.trim().replaceAll(',', '.');
    final euro = double.tryParse(euroStr) ?? 0;
    final cents = (euro * 100).round();

    setState(() => _loading = true);
    final error = await widget.onSave(
      categoryId: _selectedCategory!.id,
      amountCents: cents,
      note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
      spentAt: _spentAt,
    );
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
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _spentAt,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFF4FC3F7),
            surface: RpgColors.panelBg,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _spentAt = picked);
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: RpgColors.panelBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          border: Border.all(color: RpgColors.border),
        ),
        padding: EdgeInsets.fromLTRB(24, 20, 24, 24 + bottomPad),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
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
                _isEditing ? 'EDIT EXPENSE' : 'ADD EXPENSE',
                style: const TextStyle(
                  color: RpgColors.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 2.4,
                ),
              ),

              const SizedBox(height: 20),

              // Amount field
              TextFormField(
                controller: _amountCtrl,
                autofocus: !_isEditing,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                      RegExp(r'^\d*[.,]?\d{0,2}')),
                ],
                style: const TextStyle(
                  color: RpgColors.textPrimary,
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -1,
                ),
                decoration: InputDecoration(
                  prefixText: '€ ',
                  prefixStyle: const TextStyle(
                    color: RpgColors.textMuted,
                    fontSize: 28,
                    fontWeight: FontWeight.w400,
                  ),
                  hintText: '0.00',
                  hintStyle: const TextStyle(
                    color: RpgColors.textMuted,
                    fontSize: 32,
                    fontWeight: FontWeight.w300,
                  ),
                  border: InputBorder.none,
                ),
                validator: (v) {
                  final val =
                      double.tryParse(v?.replaceAll(',', '.') ?? '');
                  if (val == null || val <= 0) return 'Enter a valid amount';
                  return null;
                },
              ),

              Container(height: 0.5, color: RpgColors.divider),
              const SizedBox(height: 16),

              // Category picker
              const Text(
                'CATEGORY',
                style: TextStyle(
                  color: RpgColors.textMuted,
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.8,
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 68,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: widget.categories.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final cat = widget.categories[i];
                    final selected = cat.id == _selectedCategory?.id;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedCategory = cat),
                      child: Column(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: selected
                                  ? cat.color.withValues(alpha: 0.18)
                                  : Colors.transparent,
                              border: Border.all(
                                color: selected
                                    ? cat.color
                                    : RpgColors.border,
                                width: selected ? 1.5 : 1,
                              ),
                            ),
                            child: Icon(cat.icon,
                                size: 18,
                                color: selected
                                    ? cat.color
                                    : RpgColors.textMuted),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            cat.name,
                            style: TextStyle(
                              color: selected
                                  ? cat.color
                                  : RpgColors.textMuted,
                              fontSize: 8,
                              fontWeight: selected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 16),

              // Note + Date row
              Row(
                children: [
                  // Note
                  Expanded(
                    child: TextFormField(
                      controller: _noteCtrl,
                      style: const TextStyle(
                          color: RpgColors.textPrimary, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Note (optional)',
                        hintStyle: const TextStyle(
                            color: RpgColors.textMuted, fontSize: 13),
                        filled: true,
                        fillColor: RpgColors.panelBgAlt,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide: const BorderSide(
                              color: RpgColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide:
                              const BorderSide(color: RpgColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide: const BorderSide(
                              color: Color(0xFF4FC3F7)),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Date button
                  GestureDetector(
                    onTap: _pickDate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: RpgColors.panelBgAlt,
                        borderRadius: BorderRadius.circular(6),
                        border:
                            Border.all(color: RpgColors.border),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today_outlined,
                              size: 14, color: RpgColors.textMuted),
                          const SizedBox(width: 6),
                          Text(
                            '${_spentAt.day.toString().padLeft(2, '0')}/'
                            '${_spentAt.month.toString().padLeft(2, '0')}',
                            style: const TextStyle(
                              color: RpgColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Save button
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _loading ? null : _save,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF4FC3F7),
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
                          _isEditing ? 'SAVE CHANGES' : 'ADD EXPENSE',
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
      ),
    );
  }
}
