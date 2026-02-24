import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/entities/creation_project.dart';

enum _SessionKind { general, project }

class CreationAddSessionSheet extends StatefulWidget {
  final List<CreationProject> activeProjects;
  final bool isBusy;
  final Future<String?> Function(int minutes) onAddGeneral;
  final Future<String?> Function(String projectId, int minutes) onAddProject;

  const CreationAddSessionSheet({
    super.key,
    required this.activeProjects,
    required this.isBusy,
    required this.onAddGeneral,
    required this.onAddProject,
  });

  @override
  State<CreationAddSessionSheet> createState() =>
      _CreationAddSessionSheetState();
}

class _CreationAddSessionSheetState extends State<CreationAddSessionSheet> {
  final _formKey = GlobalKey<FormState>();
  final _minutesController = TextEditingController();
  _SessionKind _kind = _SessionKind.general;
  String? _selectedProjectId;

  @override
  void dispose() {
    _minutesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final minutes = int.tryParse(_minutesController.text.trim());
    if (minutes == null) return;

    String? error;
    if (_kind == _SessionKind.general) {
      error = await widget.onAddGeneral(minutes);
    } else {
      if (_selectedProjectId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Select a project.')),
        );
        return;
      }
      error = await widget.onAddProject(_selectedProjectId!, minutes);
    }

    if (!mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error), backgroundColor: Colors.red));
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasProjects = widget.activeProjects.isNotEmpty;

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

            // Kind toggle
            SegmentedButton<_SessionKind>(
              segments: [
                const ButtonSegment(
                  value: _SessionKind.general,
                  label: Text('General'),
                  icon: Icon(Icons.brush_outlined),
                ),
                ButtonSegment(
                  value: _SessionKind.project,
                  label: const Text('Project'),
                  icon: const Icon(Icons.folder_outlined),
                  enabled: hasProjects,
                ),
              ],
              selected: {_kind},
              onSelectionChanged: (s) => setState(() => _kind = s.first),
              style: ButtonStyle(
                visualDensity: VisualDensity.compact,
              ),
            ),

            const SizedBox(height: 12),

            // Project dropdown (only when project kind is selected)
            if (_kind == _SessionKind.project) ...[
              DropdownButtonFormField<String>(
                initialValue: _selectedProjectId,
                hint: const Text('Select project'),
                isExpanded: true,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
                items: widget.activeProjects
                    .map(
                      (p) => DropdownMenuItem(
                        value: p.id,
                        child: Text(p.name),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _selectedProjectId = v),
                validator: (v) =>
                    v == null ? 'Select a project' : null,
              ),
              const SizedBox(height: 12),
            ],

            // Minutes input
            TextFormField(
              controller: _minutesController,
              autofocus: true,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: 'Minutes',
                hintText: '30',
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
