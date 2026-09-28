import 'package:flutter/material.dart';

import '../../../../core/theme/rpg_colors.dart';
import '../../domain/entities/budget_category.dart';
import '../../domain/entities/budget_transaction.dart';

/// Imported rows waiting for a look: set the category and note, confirm.
class StatementReviewSheet extends StatefulWidget {
  final List<BudgetTransaction> transactions;
  final List<BudgetCategory> categories;
  final Future<String?> Function({
    required String id,
    required String categoryId,
    String? note,
  }) onReview;
  final Future<String?> Function({
    required String keyword,
    required String categoryId,
  }) onAddRule;

  const StatementReviewSheet({
    super.key,
    required this.transactions,
    required this.categories,
    required this.onReview,
    required this.onAddRule,
  });

  @override
  State<StatementReviewSheet> createState() => _StatementReviewSheetState();
}

class _StatementReviewSheetState extends State<StatementReviewSheet> {
  late final List<BudgetTransaction> _pending = [...widget.transactions];
  final _categoryIds = <String, String>{};
  final _notes = <String, TextEditingController>{};

  /// Transactions whose "always categorize" rule has been saved.
  final _ruleSaved = <String>{};
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    for (final t in _pending) {
      _categoryIds[t.id] = t.categoryId;
      _notes[t.id] = TextEditingController(text: t.note ?? '');
    }
  }

  @override
  void dispose() {
    for (final c in _notes.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _showError(String error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error), backgroundColor: const Color(0xFFEF5350)),
    );
  }

  Future<String?> _save(BudgetTransaction t) => widget.onReview(
        id: t.id,
        categoryId: _categoryIds[t.id]!,
        note: _notes[t.id]!.text,
      );

  void _done(Iterable<BudgetTransaction> reviewed) {
    final ids = reviewed.map((t) => t.id).toSet();
    setState(() => _pending.removeWhere((t) => ids.contains(t.id)));
    if (_pending.isEmpty) Navigator.pop(context);
  }

  Future<void> _confirm(BudgetTransaction t) async {
    setState(() => _busy = true);
    final error = await _save(t);
    if (!mounted) return;
    setState(() => _busy = false);
    if (error != null) {
      _showError(error);
    } else {
      _done([t]);
    }
  }

  Future<void> _confirmAll() async {
    setState(() => _busy = true);
    final rows = [..._pending];
    final errors = await Future.wait(rows.map(_save));
    if (!mounted) return;
    setState(() => _busy = false);
    _done([
      for (var i = 0; i < rows.length; i++)
        if (errors[i] == null) rows[i],
    ]);
    final firstError = errors.whereType<String>().firstOrNull;
    if (firstError != null) _showError(firstError);
  }

  Future<void> _addRule(BudgetTransaction t) async {
    final error = await widget.onAddRule(
      keyword: t.bankDescription!,
      categoryId: _categoryIds[t.id]!,
    );
    if (!mounted) return;
    if (error != null) {
      _showError(error);
    } else {
      setState(() => _ruleSaved.add(t.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: Container(
        constraints: BoxConstraints(maxHeight: media.size.height * 0.88),
        decoration: BoxDecoration(
          color: RpgColors.panelBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          border: Border.all(color: RpgColors.border),
        ),
        padding: const EdgeInsets.only(top: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 3,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: RpgColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 12, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'REVIEW IMPORT  ·  ${_pending.length}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: RpgColors.textMuted,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 2.4,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _busy || _pending.isEmpty ? null : _confirmAll,
                    child: const Text(
                      'CONFIRM ALL',
                      style: TextStyle(
                        color: Color(0xFF4FC3F7),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(height: 0.5, color: RpgColors.divider),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: EdgeInsets.only(bottom: 16 + media.padding.bottom),
                itemCount: _pending.length,
                separatorBuilder: (_, _) =>
                    Container(height: 0.5, color: RpgColors.divider),
                itemBuilder: (_, i) {
                  final t = _pending[i];
                  final categoryId = _categoryIds[t.id]!;
                  return _ReviewRow(
                    key: ValueKey(t.id),
                    transaction: t,
                    categories: widget.categories,
                    categoryId: categoryId,
                    noteController: _notes[t.id]!,
                    busy: _busy,
                    // Offered only once you move a row off the category it
                    // was imported with.
                    ruleOffer: categoryId == t.categoryId
                        ? _RuleOffer.none
                        : _ruleSaved.contains(t.id)
                            ? _RuleOffer.saved
                            : _RuleOffer.offer,
                    onCategory: (id) => setState(() {
                      _categoryIds[t.id] = id;
                      _ruleSaved.remove(t.id);
                    }),
                    onConfirm: () => _confirm(t),
                    onAddRule: () => _addRule(t),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _RuleOffer { none, offer, saved }

class _ReviewRow extends StatelessWidget {
  final BudgetTransaction transaction;
  final List<BudgetCategory> categories;
  final String categoryId;
  final TextEditingController noteController;
  final bool busy;
  final _RuleOffer ruleOffer;
  final ValueChanged<String> onCategory;
  final VoidCallback onConfirm;
  final VoidCallback onAddRule;

  const _ReviewRow({
    super.key,
    required this.transaction,
    required this.categories,
    required this.categoryId,
    required this.noteController,
    required this.busy,
    required this.ruleOffer,
    required this.onCategory,
    required this.onConfirm,
    required this.onAddRule,
  });

  @override
  Widget build(BuildContext context) {
    final t = transaction;
    final d = t.spentAt;
    final dateStr = '${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')}';
    final merchant = t.bankDescription ?? '';
    final selected = categories.where((c) => c.id == categoryId).firstOrNull;
    // The imported category leads so you can see it without scrolling.
    final pills = [
      ...categories.where((c) => c.id == t.categoryId),
      ...categories.where((c) => c.id != t.categoryId),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date · merchant · amount
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Row(
              children: [
                Text(
                  dateStr,
                  style: const TextStyle(
                      color: RpgColors.textMuted, fontSize: 11),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    merchant,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: RpgColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '${t.isRefund ? '+' : ''}€${t.amountEur.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: t.isRefund
                        ? const Color(0xFF26A69A)
                        : RpgColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Category pills
          SizedBox(
            height: 30,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: pills.length,
              separatorBuilder: (_, _) => const SizedBox(width: 6),
              itemBuilder: (_, i) {
                final c = pills[i];
                final isSelected = c.id == categoryId;
                return GestureDetector(
                  onTap: busy ? null : () => onCategory(c.id),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? c.color.withValues(alpha: 0.18)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: isSelected ? c.color : RpgColors.border,
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(c.icon,
                            size: 12,
                            color: isSelected ? c.color : RpgColors.textMuted),
                        const SizedBox(width: 5),
                        Text(
                          c.name,
                          style: TextStyle(
                            color: isSelected ? c.color : RpgColors.textMuted,
                            fontSize: 11,
                            fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),

          // Note + confirm
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: noteController,
                  enabled: !busy,
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
                      borderSide: const BorderSide(color: RpgColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: const BorderSide(color: RpgColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: const BorderSide(color: Color(0xFF4FC3F7)),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    isDense: true,
                  ),
                ),
              ),
              IconButton(
                onPressed: busy ? null : onConfirm,
                tooltip: 'Confirm',
                icon: const Icon(Icons.check_circle_outline,
                    color: Color(0xFF26A69A)),
              ),
            ],
          ),

          if (ruleOffer != _RuleOffer.none && selected != null)
            Padding(
              padding: const EdgeInsets.only(top: 4, right: 8),
              child: ruleOffer == _RuleOffer.saved
                  ? Text(
                      'Rule saved: $merchant → ${selected.name}',
                      style: const TextStyle(
                          color: RpgColors.textMuted, fontSize: 11),
                    )
                  : GestureDetector(
                      onTap: busy ? null : onAddRule,
                      child: Text(
                        'Always categorize $merchant as ${selected.name}',
                        style: const TextStyle(
                          color: Color(0xFF4FC3F7),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
            ),
        ],
      ),
    );
  }
}
