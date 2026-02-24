import 'package:flutter/material.dart';

import '../../domain/entities/mindfulness_session.dart';
import 'mindfulness_add_session_sheet.dart';
import 'section_card.dart';

const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

String _formatToday() {
  final d = DateTime.now();
  return '${_weekdays[d.weekday - 1]}, ${_months[d.month - 1]} ${d.day}';
}

class MindfulnessTodaySection extends StatelessWidget {
  final List<MindfulnessSession> sessions;
  final Future<String?> Function({
    required MindfulnessCategory category,
    required int minutes,
  }) onAdd;
  final Future<String?> Function({
    required String sessionId,
    required int minutes,
  }) onUpdate;
  final Future<String?> Function(String sessionId) onDelete;

  const MindfulnessTodaySection({
    super.key,
    required this.sessions,
    required this.onAdd,
    required this.onUpdate,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SectionCard(
      title: 'Today  ·  ${_formatToday()}',
      child: Column(
        children: [
          OutlinedButton.icon(
            onPressed: () => _handleAdd(context),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Log Session'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(42),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          if (sessions.isEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'No sessions logged today.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
              ),
            ),
          ] else ...[
            const SizedBox(height: 12),
            ...sessions.map(
              (s) => _SessionTile(
                session: s,
                onEdit: () => _handleEdit(context, s),
                onDelete: () => _handleDelete(context, s),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _handleAdd(BuildContext context) async {
    final result = await MindfulnessAddSessionSheet.show(context);
    if (result == null || !context.mounted) return;
    final (category, minutes) = result;
    final error = await onAdd(category: category, minutes: minutes);
    if (error != null && context.mounted) _showError(context, error);
  }

  Future<void> _handleEdit(
      BuildContext context, MindfulnessSession session) async {
    final result =
        await MindfulnessAddSessionSheet.show(context, existing: session);
    if (result == null || !context.mounted) return;
    final (_, minutes) = result;
    final error = await onUpdate(sessionId: session.id, minutes: minutes);
    if (error != null && context.mounted) _showError(context, error);
  }

  Future<void> _handleDelete(
      BuildContext context, MindfulnessSession session) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete session?'),
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
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final error = await onDelete(session.id);
    if (error != null && context.mounted) _showError(context, error);
  }

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Theme.of(context).colorScheme.error),
    );
  }
}

class _SessionTile extends StatelessWidget {
  final MindfulnessSession session;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _SessionTile({
    required this.session,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
        leading: Text(
          session.category.displayName,
          style: theme.textTheme.bodyMedium
              ?.copyWith(fontWeight: FontWeight.w500),
        ),
        title: Text(
          '${session.minutes} min',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 18),
              onPressed: onEdit,
              visualDensity: VisualDensity.compact,
              tooltip: 'Edit',
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 18),
              onPressed: onDelete,
              visualDensity: VisualDensity.compact,
              tooltip: 'Delete',
              color: theme.colorScheme.error,
            ),
          ],
        ),
      ),
    );
  }
}
