import 'package:flutter/material.dart';

import '../../../../core/theme/rpg_colors.dart';
import '../../domain/entities/japanese_session.dart';
import 'add_session_bottom_sheet.dart';

const _colorJp = Color(0xFF4FC3F7);

const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

const _categoryColors = {
  SessionCategory.vocab: Color(0xFF5C6BC0),
  SessionCategory.reading: Color(0xFF26A69A),
  SessionCategory.active: Color(0xFF4FC3F7),
  SessionCategory.passive: Color(0xFFAB47BC),
  SessionCategory.accent: Color(0xFFEC407A),
};

String _formatToday() {
  final d = DateTime.now();
  return '${_weekdays[d.weekday - 1]}, ${_months[d.month - 1]} ${d.day}';
}

class TodaySessionsSection extends StatelessWidget {
  final List<JapaneseSession> sessions;
  final Future<String?> Function({
    required SessionCategory category,
    required int minutes,
  }) onAdd;
  final Future<String?> Function({
    required String sessionId,
    required int minutes,
  }) onUpdate;
  final Future<String?> Function(String sessionId) onDelete;

  const TodaySessionsSection({
    super.key,
    required this.sessions,
    required this.onAdd,
    required this.onUpdate,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final totalMinutes =
        sessions.fold<int>(0, (sum, s) => sum + s.minutes);

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
          // Accent bar
          Container(
            height: 3,
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
              gradient:
                  LinearGradient(colors: [_colorJp, Color(0xFF81D4FA)]),
            ),
          ),
          // Header
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
                  'TODAY',
                  style: TextStyle(
                    color: RpgColors.textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 2.4,
                  ),
                ),
                const Spacer(),
                Text(
                  _formatToday(),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (totalMinutes > 0)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_outline,
                            color: _colorJp, size: 14),
                        const SizedBox(width: 6),
                        Text(
                          '$totalMinutes min logged today',
                          style: const TextStyle(
                            color: _colorJp,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

                // Add button
                GestureDetector(
                  onTap: () => _handleAdd(context),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: _colorJp.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(3),
                      border: Border.all(
                          color: _colorJp.withValues(alpha: 0.35)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add, color: _colorJp, size: 16),
                        SizedBox(width: 6),
                        Text(
                          'LOG SESSION',
                          style: TextStyle(
                            color: _colorJp,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                if (sessions.isNotEmpty) ...[
                  const SizedBox(height: 14),
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
          ),
        ],
      ),
    );
  }

  Future<void> _handleAdd(BuildContext context) async {
    final result = await AddSessionBottomSheet.show(context);
    if (result == null || !context.mounted) return;
    final (category, minutes) = result;
    final error = await onAdd(category: category, minutes: minutes);
    if (error != null && context.mounted) _showError(context, error);
  }

  Future<void> _handleEdit(
      BuildContext context, JapaneseSession session) async {
    final result =
        await AddSessionBottomSheet.show(context, existing: session);
    if (result == null || !context.mounted) return;
    final (_, minutes) = result;
    final error =
        await onUpdate(sessionId: session.id, minutes: minutes);
    if (error != null && context.mounted) _showError(context, error);
  }

  Future<void> _handleDelete(
      BuildContext context, JapaneseSession session) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: RpgColors.panelBg,
        title: const Text('Delete session?',
            style: TextStyle(color: RpgColors.textPrimary)),
        content: Text(
          'Remove ${session.minutes} min of ${session.category.displayName}?',
          style: const TextStyle(color: RpgColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel',
                style: TextStyle(color: RpgColors.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete',
                style: TextStyle(color: Color(0xFFEF5350))),
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
      SnackBar(
          content: Text(message),
          backgroundColor: const Color(0xFFEF5350)),
    );
  }
}

class _SessionTile extends StatelessWidget {
  final JapaneseSession session;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _SessionTile({
    required this.session,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final color =
        _categoryColors[session.category] ?? _colorJp;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: RpgColors.panelBgAlt,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: RpgColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 30,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.category.displayName,
                  style: const TextStyle(
                    color: RpgColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${session.minutes} min',
                  style: const TextStyle(
                    color: RpgColors.textMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 16),
            color: RpgColors.textMuted,
            onPressed: onEdit,
            visualDensity: VisualDensity.compact,
            tooltip: 'Edit',
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 16),
            color: const Color(0xFFEF5350),
            onPressed: onDelete,
            visualDensity: VisualDensity.compact,
            tooltip: 'Delete',
          ),
        ],
      ),
    );
  }
}
