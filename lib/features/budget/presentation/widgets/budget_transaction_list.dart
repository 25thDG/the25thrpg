import 'package:flutter/material.dart';

import '../../../../core/theme/rpg_colors.dart';
import '../../domain/entities/budget_category.dart';
import '../../domain/entities/budget_summary.dart';
import '../../domain/entities/budget_transaction.dart';
import 'add_transaction_sheet.dart';

class BudgetTransactionList extends StatelessWidget {
  final BudgetSummary summary;
  final Future<String?> Function({
    required String id,
    required String categoryId,
    required int amountCents,
    String? note,
    required DateTime spentAt,
  }) onUpdate;
  final Future<String?> Function(String id) onDelete;

  const BudgetTransactionList({
    super.key,
    required this.summary,
    required this.onUpdate,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final transactions = summary.transactions;
    final categoryMap = {for (final c in summary.allCategories) c.id: c};

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: RpgColors.panelBg,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: RpgColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            width: double.infinity,
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: RpgColors.divider)),
            ),
            child: Text(
              'TRANSACTIONS  ·  ${transactions.length}',
              style: const TextStyle(
                color: RpgColors.textMuted,
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 2.4,
              ),
            ),
          ),

          if (transactions.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32, horizontal: 16),
              child: Center(
                child: Text(
                  'No transactions this month.',
                  style: TextStyle(
                    color: RpgColors.textMuted,
                    fontSize: 12,
                  ),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: transactions.length,
              separatorBuilder: (_, _) => Container(
                height: 0.5,
                color: RpgColors.divider,
                margin: const EdgeInsets.only(left: 56),
              ),
              itemBuilder: (context, i) {
                final tx = transactions[i];
                final cat = categoryMap[tx.categoryId];
                return _TransactionRow(
                  transaction: tx,
                  category: cat,
                  onEdit: () => _showEditSheet(context, tx, cat),
                  onDelete: () => _confirmDelete(context, tx.id),
                );
              },
            ),
        ],
      ),
    );
  }

  void _showEditSheet(
      BuildContext context, BudgetTransaction tx, BudgetCategory? cat) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => AddTransactionSheet(
        categories: summary.allCategories,
        initialTransaction: tx,
        onSave: ({
          required categoryId,
          required amountCents,
          note,
          required spentAt,
        }) =>
            onUpdate(
          id: tx.id,
          categoryId: categoryId,
          amountCents: amountCents,
          note: note,
          spentAt: spentAt,
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: RpgColors.panelBg,
        title: const Text('Delete transaction?',
            style: TextStyle(color: RpgColors.textPrimary, fontSize: 15)),
        content: const Text('This cannot be undone.',
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
              onDelete(id);
            },
            child: const Text('Delete',
                style: TextStyle(color: Color(0xFFEF5350))),
          ),
        ],
      ),
    );
  }
}

class _TransactionRow extends StatelessWidget {
  final BudgetTransaction transaction;
  final BudgetCategory? category;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _TransactionRow({
    required this.transaction,
    required this.category,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final color = category?.color ?? RpgColors.textMuted;
    final d = transaction.spentAt;
    final dateStr = '${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')}';

    return Dismissible(
      key: Key(transaction.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: const Color(0xFFEF5350).withValues(alpha: 0.15),
        child: const Icon(Icons.delete_outline,
            color: Color(0xFFEF5350), size: 20),
      ),
      confirmDismiss: (_) async {
        onDelete();
        return false;
      },
      child: InkWell(
        onTap: onEdit,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // Category icon circle
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: 0.1),
                  border: Border.all(color: color.withValues(alpha: 0.3)),
                ),
                child: Icon(category?.icon ?? Icons.more_horiz,
                    size: 16, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category?.name ?? 'Unknown',
                      style: const TextStyle(
                        color: RpgColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (transaction.note != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        transaction.note!,
                        style: const TextStyle(
                          color: RpgColors.textMuted,
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '€${transaction.amountEur.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: color,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    dateStr,
                    style: const TextStyle(
                      color: RpgColors.textMuted,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
