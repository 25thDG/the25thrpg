import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/entities/wealth_snapshot.dart';
import 'section_card.dart';

const _months = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];

class WealthMonthlyInputSection extends StatefulWidget {
  /// Pre-existing snapshot for the current month, if any.
  final WealthSnapshot? currentMonthSnapshot;
  final bool isBusy;
  final Future<String?> Function(double netWorthEur) onSave;
  final Future<String?> Function(String id) onDelete;

  const WealthMonthlyInputSection({
    super.key,
    required this.currentMonthSnapshot,
    required this.isBusy,
    required this.onSave,
    required this.onDelete,
  });

  @override
  State<WealthMonthlyInputSection> createState() =>
      _WealthMonthlyInputSectionState();
}

class _WealthMonthlyInputSectionState
    extends State<WealthMonthlyInputSection> {
  late final TextEditingController _controller;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.currentMonthSnapshot != null
          ? _stripTrailingZeroes(widget.currentMonthSnapshot!.netWorthEur)
          : '',
    );
  }

  @override
  void didUpdateWidget(WealthMonthlyInputSection old) {
    super.didUpdateWidget(old);
    // Sync field when the snapshot changes externally (e.g. after save).
    final newVal = widget.currentMonthSnapshot?.netWorthEur;
    final oldVal = old.currentMonthSnapshot?.netWorthEur;
    if (newVal != oldVal) {
      _controller.text =
          newVal != null ? _stripTrailingZeroes(newVal) : '';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _stripTrailingZeroes(double v) {
    final s = v.toStringAsFixed(2);
    if (s.endsWith('.00')) return s.substring(0, s.length - 3);
    if (s.endsWith('0')) return s.substring(0, s.length - 1);
    return s;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final raw = _controller.text.trim().replaceAll(',', '');
    final value = double.tryParse(raw);
    if (value == null) return;
    final error = await widget.onSave(value);
    if (error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove this month?'),
        content: const Text(
          'This will soft-delete the current month\'s snapshot.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final error =
        await widget.onDelete(widget.currentMonthSnapshot!.id);
    if (error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final monthName = '${_months[now.month - 1]} ${now.year}';
    final isEdit = widget.currentMonthSnapshot != null;

    return SectionCard(
      title: monthName,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isEdit)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  'Snapshot on record — updating will replace it.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ),

            // Net worth input
            TextFormField(
              controller: _controller,
              enabled: !widget.isBusy,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true, signed: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^-?[\d,]*\.?\d*')),
              ],
              decoration: InputDecoration(
                prefixText: '€ ',
                hintText: '0',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Enter a value';
                final n = double.tryParse(v.trim().replaceAll(',', ''));
                if (n == null) return 'Enter a valid number';
                return null;
              },
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: widget.isBusy ? null : _submit,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: widget.isBusy
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child:
                                CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(isEdit ? 'Update' : 'Save'),
                  ),
                ),
                if (isEdit) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: widget.isBusy ? null : _confirmDelete,
                    icon: const Icon(Icons.delete_outline),
                    color: theme.colorScheme.error,
                    tooltip: 'Remove this month',
                    style: IconButton.styleFrom(
                      side: BorderSide(
                        color:
                            theme.colorScheme.error.withValues(alpha: 0.4),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
