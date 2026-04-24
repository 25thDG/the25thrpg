import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/theme/rpg_colors.dart';
import '../../domain/entities/mindfulness_session.dart';
import 'mindfulness_add_session_sheet.dart';

const _colorMind = Color(0xFF26A69A);

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
  Timer? _ticker;
  int _elapsedSeconds = 0;
  bool _running = false;
  bool _saving = false;

  void _startTimer() {
    setState(() { _running = true; _elapsedSeconds = 0; });
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _elapsedSeconds++);
    });
  }

  Future<void> _stopTimer() async {
    _ticker?.cancel();
    _ticker = null;
    final elapsed = _elapsedSeconds;
    setState(() { _running = false; _elapsedSeconds = 0; });

    final minutes = (elapsed / 60).round().clamp(1, 999);
    setState(() => _saving = true);
    final error = await widget.onAdd(
      category: MindfulnessCategory.meditation,
      minutes: minutes,
    );
    if (mounted) {
      setState(() => _saving = false);
      if (error != null) _showError(error);
    }
  }

  void _cancelTimer() {
    _ticker?.cancel();
    _ticker = null;
    setState(() { _running = false; _elapsedSeconds = 0; });
  }

  Future<void> _handleManualAdd() async {
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
        title: const Text(
          'Delete session?',
          style: TextStyle(color: RpgColors.textPrimary),
        ),
        content: Text(
          'Remove ${session.minutes} min of ${session.category.displayName}?',
          style: const TextStyle(color: RpgColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: RpgColors.textMuted),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Color(0xFFEF5350)),
            ),
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
        backgroundColor: const Color(0xFFEF5350),
      ),
    );
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  String _formatElapsed() {
    final m = _elapsedSeconds ~/ 60;
    final s = _elapsedSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
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
              gradient: LinearGradient(
                colors: [Color(0xFF26A69A), Color(0xFF00BCD4)],
              ),
            ),
          ),
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: RpgColors.divider)),
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
                // Timer section
                _TimerSection(
                  running: _running,
                  saving: _saving,
                  elapsed: _formatElapsed(),
                  totalMinutes: totalMinutes,
                  onStart: _startTimer,
                  onStop: _stopTimer,
                  onCancel: _cancelTimer,
                  onManualAdd: _handleManualAdd,
                ),

                if (regularSessions.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const _SectionLabel('SESSIONS'),
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

// ── Timer section ─────────────────────────────────────────────────────────────

class _TimerSection extends StatelessWidget {
  final bool running;
  final bool saving;
  final String elapsed;
  final int totalMinutes;
  final VoidCallback onStart;
  final VoidCallback onCancel;
  final Future<void> Function() onStop;
  final VoidCallback onManualAdd;

  const _TimerSection({
    required this.running,
    required this.saving,
    required this.elapsed,
    required this.totalMinutes,
    required this.onStart,
    required this.onStop,
    required this.onCancel,
    required this.onManualAdd,
  });

  @override
  Widget build(BuildContext context) {
    if (saving) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: _colorMind,
            ),
          ),
        ),
      );
    }

    if (running) {
      return Column(
        children: [
          // Elapsed display
          Center(
            child: Text(
              elapsed,
              style: const TextStyle(
                color: _colorMind,
                fontSize: 44,
                fontWeight: FontWeight.w700,
                letterSpacing: -2,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ),
          const SizedBox(height: 4),
          const Center(
            child: Text(
              'SESSION IN PROGRESS',
              style: TextStyle(
                color: _colorMind,
                fontSize: 9,
                fontWeight: FontWeight.w600,
                letterSpacing: 2.0,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  label: 'STOP & LOG',
                  color: _colorMind,
                  onPressed: onStop,
                ),
              ),
              const SizedBox(width: 10),
              _CancelButton(onPressed: onCancel),
            ],
          ),
        ],
      );
    }

    // Idle state
    return Column(
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
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        Row(
          children: [
            Expanded(
              child: _ActionButton(
                label: 'START SESSION',
                color: _colorMind,
                onPressed: onStart,
                icon: Icons.play_arrow_rounded,
              ),
            ),
            const SizedBox(width: 10),
            _IconActionButton(
              icon: Icons.add,
              tooltip: 'Log manually',
              onPressed: onManualAdd,
            ),
          ],
        ),
      ],
    );
  }
}

// ── Session tile ──────────────────────────────────────────────────────────────

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
        borderRadius: BorderRadius.circular(3),
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

// ── Shared small widgets ──────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: RpgColors.textMuted,
        fontSize: 9,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.8,
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.label,
    required this.color,
    required this.onPressed,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(3),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CancelButton extends StatelessWidget {
  final VoidCallback onPressed;
  const _CancelButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: RpgColors.panelBgAlt,
          borderRadius: BorderRadius.circular(3),
          border: Border.all(color: RpgColors.border),
        ),
        child: const Text(
          'CANCEL',
          style: TextStyle(
            color: RpgColors.textMuted,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }
}

class _IconActionButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  const _IconActionButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: RpgColors.panelBgAlt,
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: RpgColors.border),
          ),
          child: Icon(icon, color: RpgColors.textSecondary, size: 18),
        ),
      ),
    );
  }
}
