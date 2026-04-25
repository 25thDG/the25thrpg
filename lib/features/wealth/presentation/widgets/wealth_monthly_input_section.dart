import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/rpg_colors.dart';
import '../../domain/entities/wealth_snapshot.dart';

const _colorGold = Color(0xFF10B981);

const _months = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];

class WealthMonthlyInputSection extends StatefulWidget {
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
          ? _strip(widget.currentMonthSnapshot!.netWorthEur)
          : '',
    );
  }

  @override
  void didUpdateWidget(WealthMonthlyInputSection old) {
    super.didUpdateWidget(old);
    final newVal = widget.currentMonthSnapshot?.netWorthEur;
    final oldVal = old.currentMonthSnapshot?.netWorthEur;
    if (newVal != oldVal) {
      _controller.text = newVal != null ? _strip(newVal) : '';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _strip(double v) {
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
    if (error != null && mounted) _showError(error);
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: RpgColors.panelBg,
        title: const Text('Remove this month?',
            style: TextStyle(color: RpgColors.textPrimary)),
        content: const Text(
          "This will soft-delete the current month's snapshot.",
          style: TextStyle(color: RpgColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel',
                style: TextStyle(color: RpgColors.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove',
                style: TextStyle(color: Color(0xFFEF5350))),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final error = await widget.onDelete(widget.currentMonthSnapshot!.id);
    if (error != null && mounted) _showError(error);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(message),
          backgroundColor: const Color(0xFFEF5350)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final monthName = '${_months[now.month - 1]} ${now.year}';
    final isEdit = widget.currentMonthSnapshot != null;

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
          // Gold accent bar
          Container(
            height: 3,
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
              gradient: LinearGradient(
                colors: [_colorGold, Color(0xFF34D399)],
              ),
            ),
          ),
          Container(
            width: double.infinity,
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(
              border:
                  Border(bottom: BorderSide(color: RpgColors.divider)),
            ),
            child: Row(
              children: [
                const Text(
                  'LOG SNAPSHOT',
                  style: TextStyle(
                    color: RpgColors.textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 2.4,
                  ),
                ),
                const Spacer(),
                Text(
                  monthName,
                  style: const TextStyle(
                    color: RpgColors.textMuted,
                    fontSize: 10,
                    letterSpacing: 0.4,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isEdit)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: Text(
                        'Snapshot on record — updating will replace it.',
                        style: TextStyle(
                          color: RpgColors.textMuted,
                          fontSize: 11,
                        ),
                      ),
                    ),

                  // Input field
                  TextFormField(
                    controller: _controller,
                    enabled: !widget.isBusy,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true, signed: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                          RegExp(r'^-?[\d,]*\.?\d*')),
                    ],
                    style: const TextStyle(
                      color: RpgColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: InputDecoration(
                      prefixText: '€ ',
                      prefixStyle: const TextStyle(
                        color: _colorGold,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                      hintText: '0',
                      hintStyle: const TextStyle(
                          color: RpgColors.textMuted, fontSize: 18),
                      filled: true,
                      fillColor: RpgColors.panelBgAlt,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(3),
                        borderSide:
                            const BorderSide(color: RpgColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(3),
                        borderSide:
                            const BorderSide(color: RpgColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(3),
                        borderSide: const BorderSide(
                            color: _colorGold, width: 1.5),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(3),
                        borderSide: const BorderSide(
                            color: Color(0xFFEF5350)),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Enter a value';
                      }
                      final n = double.tryParse(
                          v.trim().replaceAll(',', ''));
                      if (n == null) return 'Enter a valid number';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: widget.isBusy ? null : _submit,
                          child: Container(
                            padding:
                                const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _colorGold.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(3),
                              border: Border.all(
                                  color: _colorGold.withValues(alpha: 0.4)),
                            ),
                            child: widget.isBusy
                                ? const Center(
                                    child: SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: _colorGold,
                                      ),
                                    ),
                                  )
                                : Text(
                                    isEdit ? 'UPDATE' : 'SAVE',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: _colorGold,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1.6,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                      if (isEdit) ...[
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: widget.isBusy ? null : _confirmDelete,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEF5350)
                                  .withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(3),
                              border: Border.all(
                                color: const Color(0xFFEF5350)
                                    .withValues(alpha: 0.35),
                              ),
                            ),
                            child: const Icon(
                              Icons.delete_outline,
                              color: Color(0xFFEF5350),
                              size: 18,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
