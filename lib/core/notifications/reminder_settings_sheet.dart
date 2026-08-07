import 'package:flutter/material.dart';

import '../theme/rpg_colors.dart';
import 'reminder_service.dart';

const _accent = Color(0xFFF59E0B);

/// Bottom sheet for turning the daily reminder on and picking its time.
class ReminderSettingsSheet extends StatefulWidget {
  const ReminderSettingsSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const ReminderSettingsSheet(),
    );
  }

  @override
  State<ReminderSettingsSheet> createState() => _ReminderSettingsSheetState();
}

class _ReminderSettingsSheetState extends State<ReminderSettingsSheet> {
  final _service = ReminderService.instance;
  bool _busy = false;

  Future<void> _toggle(bool on) async {
    setState(() => _busy = true);

    ReminderStatus status = ReminderStatus.ok;
    if (on) {
      status = await _service.enable();
    } else {
      await _service.disable();
    }

    if (!mounted) return;
    setState(() => _busy = false);
    if (status != ReminderStatus.ok) _report(status);
  }

  Future<void> _sendTest() async {
    final status = await _service.sendTestNotification();
    if (!mounted) return;
    if (status != ReminderStatus.ok) _report(status);
  }

  void _report(ReminderStatus status) {
    final message = switch (status) {
      ReminderStatus.denied =>
        'Notifications are blocked. Turn them on for The 25th in your system '
            'settings, then try again.',
      ReminderStatus.unavailable =>
        'Notifications are not loaded yet. Fully quit and relaunch the app — '
            'a hot restart does not install new native code.',
      ReminderStatus.ok => '',
    };
    if (message.isEmpty) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFEF5350),
        duration: const Duration(seconds: 6),
      ),
    );
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _service.time,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: _accent,
            surface: RpgColors.panelBg,
            onSurface: RpgColors.textPrimary,
          ),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    await _service.setTime(picked);
    if (mounted) setState(() {});
  }

  String _fmt(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final enabled = _service.isEnabled;

    return Container(
      decoration: const BoxDecoration(
        color: RpgColors.panelBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        border: Border(top: BorderSide(color: RpgColors.border)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
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
              Container(width: 6, height: 6, color: _accent),
              const SizedBox(width: 8),
              const Text(
                'DAILY REMINDER',
                style: TextStyle(
                  color: RpgColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2.4,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'One nudge a day to log your sessions.',
            style: TextStyle(color: RpgColors.textMuted, fontSize: 11),
          ),
          const SizedBox(height: 20),

          // ── On / off ─────────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: RpgColors.panelBgAlt,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: RpgColors.border),
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'REMINDERS',
                    style: TextStyle(
                      color: RpgColors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.4,
                    ),
                  ),
                ),
                if (_busy)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      color: RpgColors.textMuted,
                    ),
                  )
                else
                  Switch(
                    value: enabled,
                    activeThumbColor: _accent,
                    onChanged: _toggle,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // ── Time ─────────────────────────────────────────────────────────
          Opacity(
            opacity: enabled ? 1 : 0.4,
            child: GestureDetector(
              onTap: enabled ? _pickTime : null,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                decoration: BoxDecoration(
                  color: RpgColors.panelBgAlt,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: RpgColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.schedule,
                        size: 16, color: RpgColors.textMuted),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'TIME',
                        style: TextStyle(
                          color: RpgColors.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.4,
                        ),
                      ),
                    ),
                    Text(
                      _fmt(_service.time),
                      style: const TextStyle(
                        color: _accent,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.chevron_right,
                        size: 16, color: RpgColors.textMuted),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),

          // ── Test ─────────────────────────────────────────────────────────
          GestureDetector(
            onTap: _sendTest,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 13),
              decoration: BoxDecoration(
                color: _accent.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: _accent.withValues(alpha: 0.35)),
              ),
              child: const Text(
                'SEND A TEST NOTIFICATION',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _accent,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.6,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
