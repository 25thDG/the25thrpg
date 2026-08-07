import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/rpg_colors.dart';
import '../../domain/entities/japanese_session.dart';

const _jp = Color(0xFFFF7043);

const _categoryColors = {
  SessionCategory.vocab: Color(0xFF7986CB),
  SessionCategory.reading: Color(0xFFFF7043),
  SessionCategory.active: Color(0xFF66BB6A),
  SessionCategory.passive: Color(0xFF26A69A),
  SessionCategory.accent: Color(0xFFFFA726),
};

class AddSessionBottomSheet extends StatefulWidget {
  final JapaneseSession? existing;

  const AddSessionBottomSheet({super.key, this.existing});

  static Future<(SessionCategory, int)?> show(
    BuildContext context, {
    JapaneseSession? existing,
  }) {
    return showModalBottomSheet<(SessionCategory, int)?>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddSessionBottomSheet(existing: existing),
    );
  }

  @override
  State<AddSessionBottomSheet> createState() => _AddSessionBottomSheetState();
}

class _AddSessionBottomSheetState extends State<AddSessionBottomSheet> {
  late SessionCategory _category;
  late final TextEditingController _minutesController;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _category = widget.existing?.category ?? SessionCategory.vocab;
    _minutesController = TextEditingController(
      text: widget.existing != null ? '${widget.existing!.minutes}' : '',
    );
  }

  @override
  void dispose() {
    _minutesController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final minutes = int.parse(_minutesController.text.trim());
    Navigator.of(context).pop((_category, minutes));
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;

    return Container(
      decoration: const BoxDecoration(
        color: RpgColors.panelBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        border: Border(top: BorderSide(color: RpgColors.border)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 3,
                decoration: BoxDecoration(
                  color: RpgColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Container(width: 6, height: 6, color: _jp),
                const SizedBox(width: 8),
                Text(
                  isEdit ? 'EDIT SESSION' : 'LOG SESSION',
                  style: const TextStyle(
                    color: RpgColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2.4,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

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
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: SessionCategory.values.map((c) {
                final selected = c == _category;
                final color = _categoryColors[c] ?? _jp;
                return GestureDetector(
                  onTap: () => setState(() => _category = c),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected
                          ? color.withValues(alpha: 0.15)
                          : RpgColors.panelBgAlt,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: selected
                            ? color.withValues(alpha: 0.6)
                            : RpgColors.border,
                        width: selected ? 1.5 : 1,
                      ),
                    ),
                    child: Text(
                      c.displayName.toUpperCase(),
                      style: TextStyle(
                        color: selected ? color : RpgColors.textMuted,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 22),

            const Text(
              'DURATION',
              style: TextStyle(
                color: RpgColors.textMuted,
                fontSize: 9,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.8,
              ),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _minutesController,
              autofocus: true,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: const TextStyle(
                color: RpgColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                hintText: '0',
                hintStyle:
                    const TextStyle(color: RpgColors.textMuted, fontSize: 18),
                suffixText: 'min',
                suffixStyle: const TextStyle(
                  color: RpgColors.textMuted,
                  fontSize: 13,
                  letterSpacing: 0.4,
                ),
                filled: true,
                fillColor: RpgColors.panelBgAlt,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: const BorderSide(color: RpgColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: const BorderSide(color: RpgColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: const BorderSide(color: _jp, width: 1.5),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide:
                      const BorderSide(color: Color(0xFFEF5350)),
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
              ),
              validator: (v) {
                final n = int.tryParse(v?.trim() ?? '');
                if (n == null || n <= 0) return 'Enter a positive number';
                return null;
              },
            ),
            const SizedBox(height: 22),

            GestureDetector(
              onTap: _submit,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: _jp.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4),
                  border:
                      Border.all(color: _jp.withValues(alpha: 0.4)),
                ),
                child: Text(
                  isEdit ? 'SAVE CHANGES' : 'LOG SESSION',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: _jp,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.6,
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
