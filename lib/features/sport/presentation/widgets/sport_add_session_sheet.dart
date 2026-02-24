import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/entities/sport_session.dart';

class SportAddSessionSheet extends StatefulWidget {
  final bool isBusy;
  final Future<String?> Function(SportCategory, int minutes) onSave;

  const SportAddSessionSheet({
    super.key,
    required this.isBusy,
    required this.onSave,
  });

  @override
  State<SportAddSessionSheet> createState() => _SportAddSessionSheetState();
}

class _SportAddSessionSheetState extends State<SportAddSessionSheet> {
  final _formKey = GlobalKey<FormState>();
  final _minutesController = TextEditingController();
  SportCategory _category = SportCategory.strength;

  @override
  void dispose() {
    _minutesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final minutes = int.tryParse(_minutesController.text.trim());
    if (minutes == null) return;

    final error = await widget.onSave(_category, minutes);
    if (!mounted) return;

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Theme.of(context).colorScheme.error),
      );
      return;
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Log session', style: theme.textTheme.titleMedium),
            const SizedBox(height: 16),
            Text(
              'Category',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: SportCategory.values.map((category) {
                return ChoiceChip(
                  label: Text(category.displayName),
                  selected: _category == category,
                  onSelected: (_) => setState(() => _category = category),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _minutesController,
              autofocus: true,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: 'Minutes',
                hintText: '45',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Enter minutes';
                }
                final minutes = int.tryParse(value.trim());
                if (minutes == null || minutes <= 0) {
                  return 'Enter a positive number';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
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
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
