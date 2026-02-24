import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/entities/sport_session.dart';
import 'section_card.dart';

const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

String _formatToday() {
  final now = DateTime.now();
  return '${_weekdays[now.weekday - 1]}, ${_months[now.month - 1]} ${now.day}';
}

class SportTodaySection extends StatefulWidget {
  final List<SportSession> sessions;
  final bool isBusy;
  final Future<String?> Function(String id, int minutes) onUpdate;
  final Future<String?> Function(String id) onDelete;
  final VoidCallback onAdd;

  const SportTodaySection({
    super.key,
    required this.sessions,
    required this.isBusy,
    required this.onUpdate,
    required this.onDelete,
    required this.onAdd,
  });

  @override
  State<SportTodaySection> createState() => _SportTodaySectionState();
}

class _SportTodaySectionState extends State<SportTodaySection> {
  String? _editingId;
  final _editController = TextEditingController();

  @override
  void dispose() {
    _editController.dispose();
    super.dispose();
  }

  Future<void> _saveEdit(SportSession session) async {
    final minutes = int.tryParse(_editController.text.trim());
    if (minutes == null || minutes <= 0) {
      setState(() => _editingId = null);
      return;
    }

    setState(() => _editingId = null);
    final error = await widget.onUpdate(session.id, minutes);
    if (error != null && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
    }
  }

  Future<void> _confirmDelete(SportSession session) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove session?'),
        content: Text(
          'Remove ${session.minutes} min of ${session.category.displayName}?',
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

    if (ok != true || !mounted) return;

    final error = await widget.onDelete(session.id);
    if (error != null && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SectionCard(
      title: _formatToday(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.sessions.isEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                'No sessions logged today.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
                ),
              ),
            )
          else
            ...widget.sessions.map((session) {
              final isEditing = _editingId == session.id;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: isEditing
                          ? TextFormField(
                              controller: _editController,
                              autofocus: true,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              decoration: InputDecoration(
                                labelText: 'Minutes',
                                isDense: true,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onFieldSubmitted: (_) => _saveEdit(session),
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  session.category.displayName,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.55),
                                  ),
                                ),
                                Text(
                                  '${session.minutes} min',
                                  style: theme.textTheme.bodyMedium,
                                ),
                              ],
                            ),
                    ),
                    if (isEditing) ...[
                      IconButton(
                        icon: const Icon(Icons.check, size: 18),
                        onPressed: () => _saveEdit(session),
                        tooltip: 'Save',
                        visualDensity: VisualDensity.compact,
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () => setState(() => _editingId = null),
                        tooltip: 'Cancel',
                        visualDensity: VisualDensity.compact,
                      ),
                    ] else ...[
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        onPressed: widget.isBusy
                            ? null
                            : () {
                                _editController.text = '${session.minutes}';
                                setState(() => _editingId = session.id);
                              },
                        tooltip: 'Edit',
                        visualDensity: VisualDensity.compact,
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.delete_outline,
                          size: 18,
                          color: theme.colorScheme.error,
                        ),
                        onPressed: widget.isBusy
                            ? null
                            : () => _confirmDelete(session),
                        tooltip: 'Remove',
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ],
                ),
              );
            }),
          const SizedBox(height: 4),
          FilledButton.icon(
            onPressed: widget.isBusy ? null : widget.onAdd,
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Log session'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
