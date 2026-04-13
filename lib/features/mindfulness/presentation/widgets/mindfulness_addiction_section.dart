import 'package:flutter/material.dart';

import '../../../../core/theme/rpg_colors.dart';
import '../../domain/entities/mindfulness_stats.dart';
import 'section_card.dart';

class MindfulnessAddictionSection extends StatefulWidget {
  final MindfulnessStats stats;
  final Future<String?> Function({required bool isClean}) onLog;

  const MindfulnessAddictionSection({
    super.key,
    required this.stats,
    required this.onLog,
  });

  @override
  State<MindfulnessAddictionSection> createState() =>
      _MindfulnessAddictionSectionState();
}

class _MindfulnessAddictionSectionState
    extends State<MindfulnessAddictionSection> {
  bool _loading = false;

  Future<void> _handleLog(bool isClean) async {
    setState(() => _loading = true);
    final error = await widget.onLog(isClean: isClean);
    if (!mounted) return;
    setState(() => _loading = false);
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final stats = widget.stats;
    final isLogged = stats.isCleanToday || stats.isRelapsedToday;

    return SectionCard(
      title: 'Addiction Streak',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Streak counter ──────────────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              TweenAnimationBuilder<double>(
                tween:
                    Tween(begin: 0, end: stats.addictionStreak.toDouble()),
                duration: const Duration(milliseconds: 900),
                curve: Curves.easeOutCubic,
                builder: (_, value, _) => Text(
                  value.round().toString(),
                  style: const TextStyle(
                    color: RpgColors.textPrimary,
                    fontSize: 56,
                    fontWeight: FontWeight.w700,
                    height: 1.0,
                    letterSpacing: -2,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  stats.addictionStreak == 1 ? 'day clean' : 'days clean',
                  style: const TextStyle(
                    color: RpgColors.textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 4),

          // ── Today's status indicator ────────────────────────────────────
          _StatusBadge(
            isCleanToday: stats.isCleanToday,
            isRelapsedToday: stats.isRelapsedToday,
          ),

          const SizedBox(height: 16),

          // ── Log buttons (disabled once logged today) ────────────────────
          if (!isLogged) ...[
            Row(
              children: [
                Expanded(
                  child: _LogButton(
                    label: 'Clean Day',
                    icon: Icons.check_circle_outline,
                    color: const Color(0xFF26A69A),
                    loading: _loading,
                    onTap: () => _handleLog(true),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _LogButton(
                    label: 'Relapsed',
                    icon: Icons.cancel_outlined,
                    color: const Color(0xFFEF5350),
                    loading: _loading,
                    onTap: () => _handleLog(false),
                  ),
                ),
              ],
            ),
          ] else ...[
            _LoggedTodayRow(
              isClean: stats.isCleanToday,
            ),
          ],
        ],
      ),
    );
  }
}

// ── Status badge ──────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final bool isCleanToday;
  final bool isRelapsedToday;

  const _StatusBadge({
    required this.isCleanToday,
    required this.isRelapsedToday,
  });

  @override
  Widget build(BuildContext context) {
    if (isCleanToday) {
      return _badge(
        icon: Icons.check_circle,
        label: 'Clean today',
        color: const Color(0xFF26A69A),
      );
    }
    if (isRelapsedToday) {
      return _badge(
        icon: Icons.cancel,
        label: 'Relapsed today',
        color: const Color(0xFFEF5350),
      );
    }
    return _badge(
      icon: Icons.radio_button_unchecked,
      label: 'Not logged today',
      color: RpgColors.textMuted,
    );
  }

  Widget _badge({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }
}

// ── Log button ────────────────────────────────────────────────────────────────

class _LogButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool loading;
  final VoidCallback onTap;

  const _LogButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.loading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: loading ? null : onTap,
      icon: loading
          ? SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: color,
              ),
            )
          : Icon(icon, size: 16, color: color),
      label: Text(
        label,
        style: TextStyle(
          color: loading ? RpgColors.textMuted : color,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
      style: OutlinedButton.styleFrom(
        side: BorderSide(
          color: loading ? RpgColors.border : color.withValues(alpha: 0.5),
        ),
        padding: const EdgeInsets.symmetric(vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

// ── Already logged row ────────────────────────────────────────────────────────

class _LoggedTodayRow extends StatelessWidget {
  final bool isClean;

  const _LoggedTodayRow({required this.isClean});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        isClean
            ? '+10 min logged for today\'s clean day.'
            : 'Relapse logged. Stay strong — tomorrow is a new day.',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
