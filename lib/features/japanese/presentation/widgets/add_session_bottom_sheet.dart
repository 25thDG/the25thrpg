import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/entities/japanese_session.dart';

class AddSessionBottomSheet extends StatefulWidget {
  /// If non-null, this is an edit — pre-fills the form.
  final JapaneseSession? existing;

  const AddSessionBottomSheet({super.key, this.existing});

  /// Returns `(category, minutes)` or null if cancelled.
  static Future<(SessionCategory, int)?> show(
    BuildContext context, {
    JapaneseSession? existing,
  }) {
    return showModalBottomSheet<(SessionCategory, int)?>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
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
    final theme = Theme.of(context);
    final isEdit = widget.existing != null;

    return Padding(
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
            Text(
              isEdit ? 'Edit Session' : 'Log Session',
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 20),

            // Category picker
            Text(
              'CATEGORY',
              style: theme.textTheme.labelSmall?.copyWith(
                letterSpacing: 1.1,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: SessionCategory.values.map((c) {
                final selected = c == _category;
                return ChoiceChip(
                  label: Text(c.displayName),
                  selected: selected,
                  onSelected: (_) => setState(() => _category = c),
                  selectedColor: theme.colorScheme.primaryContainer,
                  labelStyle: TextStyle(
                    color: selected
                        ? theme.colorScheme.onPrimaryContainer
                        : theme.colorScheme.onSurface,
                    fontWeight:
                        selected ? FontWeight.w600 : FontWeight.normal,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Minutes input
            Text(
              'MINUTES',
              style: theme.textTheme.labelSmall?.copyWith(
                letterSpacing: 1.1,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _minutesController,
              autofocus: true,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                hintText: 'e.g. 45',
                suffixText: 'min',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
              validator: (v) {
                final n = int.tryParse(v?.trim() ?? '');
                if (n == null || n <= 0) return 'Enter a positive number';
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Save button
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _submit,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(isEdit ? 'Save Changes' : 'Log'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
