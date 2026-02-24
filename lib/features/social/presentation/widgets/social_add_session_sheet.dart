import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/entities/social_session.dart';

class SocialAddSessionSheet extends StatefulWidget {
  final bool isBusy;
  final Future<String?> Function(InitiationType, int minutes) onSave;

  const SocialAddSessionSheet({
    super.key,
    required this.isBusy,
    required this.onSave,
  });

  @override
  State<SocialAddSessionSheet> createState() => _SocialAddSessionSheetState();
}

class _SocialAddSessionSheetState extends State<SocialAddSessionSheet> {
  final _formKey = GlobalKey<FormState>();
  final _minutesController = TextEditingController();
  InitiationType _initiationType = InitiationType.self;

  @override
  void dispose() {
    _minutesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final minutes = int.tryParse(_minutesController.text.trim());
    if (minutes == null) return;
    final error = await widget.onSave(_initiationType, minutes);
    if (!mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.red),
      );
    } else {
      Navigator.pop(context);
    }
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

            // Initiation type selector
            Text(
              'Who initiated?',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 8),
            SegmentedButton<InitiationType>(
              segments: const [
                ButtonSegment(
                  value: InitiationType.self,
                  label: Text('I initiated'),
                  icon: Icon(Icons.person_outline),
                ),
                ButtonSegment(
                  value: InitiationType.other,
                  label: Text('They initiated'),
                  icon: Icon(Icons.people_outline),
                ),
              ],
              selected: {_initiationType},
              onSelectionChanged: (s) =>
                  setState(() => _initiationType = s.first),
              style: const ButtonStyle(
                visualDensity: VisualDensity.compact,
              ),
            ),

            const SizedBox(height: 16),

            // Minutes input
            TextFormField(
              controller: _minutesController,
              autofocus: true,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: 'Minutes',
                hintText: '60',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Enter minutes';
                final n = int.tryParse(v.trim());
                if (n == null || n <= 0) return 'Enter a positive number';
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
