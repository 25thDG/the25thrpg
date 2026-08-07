import 'package:flutter/material.dart';

import '../../../../core/theme/rpg_colors.dart';
import '../../domain/entities/mindfulness_session.dart';
import 'mindfulness_add_session_sheet.dart';

const _colorMind = Color(0xFFAB47BC);

const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

String _formatToday() {
  final d = DateTime.now();
  return '${_weekdays[d.weekday - 1]}, ${_months[d.month - 1]} ${d.day}';
}

class MindfulnessTodaySection extends StatefulWidget {
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
  State<MindfulnessTodaySection> createState() =>
      _MindfulnessTodaySectionState();
}

class _MindfulnessTodaySectionState extends State<MindfulnessTodaySection> {
  Future<void> _handleAdd() async {
    final result = await MindfulnessAddSessionSheet.show(context);
    if (result == null || !context.mounted) return;
    final (category, minutes) = result;
    final error = await widget.onAdd(category: category, minutes: minutes);
    if (error != null && context.mounted) _showError(error);
  }

  Future<void> _handleEdit(MindfulnessSession session) async {
    final result =
        await MindfulnessAddSessionSheet.show(context, existing: session);
    if (result == null || !context.mounted) return;
    final (_, minutes) = result;
    final error =
        await widget.onUpdate(sessionId: session.id, minutes: minutes);
    if (error != null && context.mounted) _showError(error);
  }

  Future<void> _handleDelete(MindfulnessSession session) async {
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
    final error = await widget.onDelete(session.id);
    if (error != null && context.mounted) _showError(error);
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
    final regularSessions =
        widget.sessions.where((s) => !s.category.isAddiction).toList();
    final totalMinutes =
        regularSessions.fold<int>(0, (sum, s) => sum + s.minutes);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: RpgColors.panelBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: RpgColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 3,
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
              gradient: LinearGradient(
                  colors: [_colorMind, Color(0xFFCE93D8)]),
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
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_outline,
                            color: _colorMind, size: 14),
                        const SizedBox(width: 6),
                        Text(
                          '$totalMinutes min logged today',
                          style: const TextStyle(
                            color: _colorMind,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                GestureDetector(
                  onTap: _handleAdd,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    decoration: BoxDecoration(
                      color: _colorMind.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                          color: _colorMind.withValues(alpha: 0.4)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add, color: _colorMind, size: 15),
                        SizedBox(width: 6),
                        Text(
                          'LOG SESSION',
                          style: TextStyle(
                            color: _colorMind,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (regularSessions.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'SESSIONS',
                    style: TextStyle(
                      color: RpgColors.textMuted,
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...regularSessions.map(
                    (s) => _SessionTile(
                      session: s,
                      onEdit: () => _handleEdit(s),
                      onDelete: () => _handleDelete(s),
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
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: RpgColors.panelBgAlt,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: RpgColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 30,
            decoration: BoxDecoration(
              color: _colorMind,
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
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 16),
            color: const Color(0xFFEF5350),
            onPressed: onDelete,
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}
