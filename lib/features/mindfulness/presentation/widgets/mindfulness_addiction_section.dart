import 'package:flutter/material.dart';

import '../../../../core/theme/rpg_colors.dart';
import '../../domain/entities/mindfulness_stats.dart';

const _cleanColor = Color(0xFF26A69A);
const _relapseColor = Color(0xFFEF5350);
const _milestones = [7, 14, 30, 60, 90, 180, 365];

class MindfulnessAddictionSection extends StatefulWidget {
  final MindfulnessStats stats;
  final Future<String?> Function({required bool isClean}) onLog;
  final Future<String?> Function({required bool isClean, required DateTime date})
      onLogForDate;

  const MindfulnessAddictionSection({
    super.key,
    required this.stats,
    required this.onLog,
    required this.onLogForDate,
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
        SnackBar(content: Text(error), backgroundColor: _relapseColor),
      );
    }
  }

  Future<void> _handleLogForDate(bool isClean, DateTime date) async {
    setState(() => _loading = true);
    final error = await widget.onLogForDate(isClean: isClean, date: date);
    if (!mounted) return;
    setState(() => _loading = false);
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: _relapseColor),
      );
    }
  }

  void _showDayDialog(DateTime day) {
    final key =
        '${day.year}-${day.month}-${day.day}';
    final current = widget.stats.addictionDayHistory[key];
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _DayEditSheet(
        day: day,
        current: current,
        onSelect: (isClean) {
          Navigator.pop(context);
          _handleLogForDate(isClean, day);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final stats = widget.stats;
    final isLogged = stats.isCleanToday || stats.isRelapsedToday;
    final streak = stats.addictionStreak;

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
          // ── Header ───────────────────────────────────────────────────────
          _SectionHeader(
            isCleanToday: stats.isCleanToday,
            isRelapsedToday: stats.isRelapsedToday,
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Streak display ──────────────────────────────────────────
                _StreakDisplay(streak: streak),

                const SizedBox(height: 20),

                // ── Milestone progress ──────────────────────────────────────
                _MilestoneProgress(streak: streak),

                const SizedBox(height: 20),

                // ── 28-day history calendar ─────────────────────────────────
                _CalendarGrid(
                  dayHistory: stats.addictionDayHistory,
                  onTap: _showDayDialog,
                ),

                const SizedBox(height: 20),

                // ── Bottom stats row ────────────────────────────────────────
                _StatsRow(
                  longestStreak: stats.longestAddictionStreak,
                  currentStreak: streak,
                ),

                const SizedBox(height: 20),

                // ── Log buttons ─────────────────────────────────────────────
                if (!isLogged)
                  _LogButtons(loading: _loading, onLog: _handleLog)
                else
                  _LoggedMessage(isClean: stats.isCleanToday),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final bool isCleanToday;
  final bool isRelapsedToday;

  const _SectionHeader({
    required this.isCleanToday,
    required this.isRelapsedToday,
  });

  @override
  Widget build(BuildContext context) {
    Color accentColor = RpgColors.textMuted;
    String statusText = 'NOT LOGGED';

    if (isCleanToday) {
      accentColor = _cleanColor;
      statusText = 'CLEAN TODAY';
    } else if (isRelapsedToday) {
      accentColor = _relapseColor;
      statusText = 'RELAPSED';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        border: const Border(bottom: BorderSide(color: RpgColors.divider)),
      ),
      child: Row(
        children: [
          const Text(
            'SOBRIETY',
            style: TextStyle(
              color: RpgColors.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 2.4,
            ),
          ),
          const Spacer(),
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accentColor,
              boxShadow: [
                BoxShadow(
                    color: accentColor.withValues(alpha: 0.6), blurRadius: 6),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Text(
            statusText,
            style: TextStyle(
              color: accentColor,
              fontSize: 9,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Streak display ────────────────────────────────────────────────────────────

class _StreakDisplay extends StatelessWidget {
  final int streak;

  const _StreakDisplay({required this.streak});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: streak.toDouble()),
          duration: const Duration(milliseconds: 1000),
          curve: Curves.easeOutCubic,
          builder: (_, value, _) => Text(
            value.round().toString(),
            style: TextStyle(
              color: streak > 0 ? _cleanColor : RpgColors.textPrimary,
              fontSize: 72,
              fontWeight: FontWeight.w800,
              height: 1.0,
              letterSpacing: -3,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                streak == 1 ? 'DAY' : 'DAYS',
                style: const TextStyle(
                  color: RpgColors.textSecondary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2.0,
                  height: 1.1,
                ),
              ),
              const Text(
                'CLEAN',
                style: TextStyle(
                  color: RpgColors.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 2.0,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Milestone progress ────────────────────────────────────────────────────────

class _MilestoneProgress extends StatelessWidget {
  final int streak;

  const _MilestoneProgress({required this.streak});

  @override
  Widget build(BuildContext context) {
    // Find next and previous milestone
    int prev = 0;
    int next = _milestones.first;
    for (final m in _milestones) {
      if (streak >= m) {
        prev = m;
      } else {
        next = m;
        break;
      }
    }
    // Past all milestones
    if (streak >= _milestones.last) {
      prev = _milestones.last;
      next = _milestones.last + 365;
    }

    final progress = prev == next ? 1.0 : (streak - prev) / (next - prev);
    final daysLeft = next - streak;
    final allUnlocked = streak >= _milestones.last;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              allUnlocked ? 'ALL MILESTONES REACHED' : 'NEXT MILESTONE',
              style: const TextStyle(
                color: RpgColors.textMuted,
                fontSize: 9,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.8,
              ),
            ),
            if (!allUnlocked)
              Text(
                '$daysLeft day${daysLeft == 1 ? '' : 's'} to go',
                style: const TextStyle(
                  color: RpgColors.textMuted,
                  fontSize: 9,
                  letterSpacing: 0.3,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        // Milestone dots row
        Row(
          children: _milestones.map((m) {
            final unlocked = streak >= m;
            final isNext = !unlocked && m == next;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Column(
                  children: [
                    Container(
                      height: 4,
                      decoration: BoxDecoration(
                        color: unlocked
                            ? _cleanColor
                            : (isNext
                                ? _cleanColor.withValues(alpha: 0.25)
                                : RpgColors.divider),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      m >= 365 ? '1y' : '${m}d',
                      style: TextStyle(
                        color: unlocked
                            ? _cleanColor
                            : (isNext
                                ? _cleanColor.withValues(alpha: 0.5)
                                : RpgColors.textMuted),
                        fontSize: 8,
                        fontWeight: unlocked || isNext
                            ? FontWeight.w700
                            : FontWeight.w400,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        if (!allUnlocked) ...[
          const SizedBox(height: 10),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: progress.clamp(0.0, 1.0)),
            duration: const Duration(milliseconds: 1200),
            curve: Curves.easeOutCubic,
            builder: (_, v, _) => ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: v,
                backgroundColor: RpgColors.progressTrack,
                valueColor: const AlwaysStoppedAnimation(_cleanColor),
                minHeight: 4,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$streak / $next days',
            style: const TextStyle(
              color: RpgColors.textMuted,
              fontSize: 9,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ],
    );
  }
}

// ── 28-day calendar heatmap ───────────────────────────────────────────────────

class _CalendarGrid extends StatelessWidget {
  final Map<String, bool> dayHistory;
  final void Function(DateTime) onTap;

  const _CalendarGrid({required this.dayHistory, required this.onTap});

  static String _key(DateTime d) => '${d.year}-${d.month}-${d.day}';

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    // Build list of last 28 days oldest→newest
    final days = List.generate(
      28,
      (i) => today.subtract(Duration(days: 27 - i)),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'LAST 28 DAYS',
          style: TextStyle(
            color: RpgColors.textMuted,
            fontSize: 9,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.8,
          ),
        ),
        const SizedBox(height: 8),
        // Legend
        Row(
          children: [
            _LegendDot(color: _cleanColor, label: 'Clean'),
            const SizedBox(width: 12),
            _LegendDot(color: _relapseColor, label: 'Relapsed'),
            const SizedBox(width: 12),
            _LegendDot(color: RpgColors.divider, label: 'Not logged'),
          ],
        ),
        const SizedBox(height: 10),
        // 4 rows × 7 days grid
        ...List.generate(4, (row) {
          final rowDays = days.sublist(row * 7, row * 7 + 7);
          return Padding(
            padding: const EdgeInsets.only(bottom: 5),
            child: Row(
              children: rowDays.map((day) {
                final key = _key(day);
                final isToday = key == _key(today);
                final logged = dayHistory[key];
                Color fill;
                if (logged == true) {
                  fill = _cleanColor;
                } else if (logged == false) {
                  fill = _relapseColor;
                } else {
                  fill = RpgColors.divider.withValues(alpha: 0.6);
                }
                final isFuture = day.isAfter(today);
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: GestureDetector(
                        onTap: isFuture ? null : () => onTap(day),
                        child: Container(
                          decoration: BoxDecoration(
                            color: logged != null
                                ? fill.withValues(alpha: 0.18)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: isToday
                                  ? (logged == true
                                      ? _cleanColor
                                      : (logged == false
                                          ? _relapseColor
                                          : RpgColors.textMuted))
                                  : fill,
                              width: isToday ? 1.5 : 1,
                            ),
                          ),
                          child: logged != null
                              ? Center(
                                  child: Icon(
                                    logged ? Icons.check : Icons.close,
                                    size: 10,
                                    color: fill,
                                  ),
                                )
                              : null,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          );
        }),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            color: RpgColors.textMuted,
            fontSize: 9,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }
}

// ── Stats row ─────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  final int longestStreak;
  final int currentStreak;

  const _StatsRow({required this.longestStreak, required this.currentStreak});

  @override
  Widget build(BuildContext context) {
    final isRecord =
        currentStreak > 0 && currentStreak >= longestStreak;

    return Row(
      children: [
        _StatCell(
          label: 'CURRENT STREAK',
          value: '$currentStreak d',
          color: currentStreak > 0 ? _cleanColor : RpgColors.textSecondary,
        ),
        Container(width: 1, height: 32, color: RpgColors.divider),
        _StatCell(
          label: 'LONGEST STREAK',
          value: '$longestStreak d',
          color: isRecord ? const Color(0xFFFFD54F) : RpgColors.textSecondary,
          trailing: isRecord ? '  RECORD' : null,
        ),
      ],
    );
  }
}

class _StatCell extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final String? trailing;

  const _StatCell({
    required this.label,
    required this.value,
    required this.color,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: RpgColors.textMuted,
                fontSize: 8,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.4,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    color: color,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
                if (trailing != null)
                  Text(
                    trailing!,
                    style: const TextStyle(
                      color: Color(0xFFFFD54F),
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.0,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Log buttons ───────────────────────────────────────────────────────────────

class _LogButtons extends StatelessWidget {
  final bool loading;
  final Future<void> Function(bool) onLog;

  const _LogButtons({required this.loading, required this.onLog});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _LogButton(
            label: 'CLEAN DAY',
            icon: Icons.check_circle_outline,
            color: _cleanColor,
            loading: loading,
            onTap: () => onLog(true),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _LogButton(
            label: 'RELAPSED',
            icon: Icons.cancel_outlined,
            color: _relapseColor,
            loading: loading,
            onTap: () => onLog(false),
          ),
        ),
      ],
    );
  }
}

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
              child: CircularProgressIndicator(strokeWidth: 2, color: color),
            )
          : Icon(icon, size: 16, color: color),
      label: Text(
        label,
        style: TextStyle(
          color: loading ? RpgColors.textMuted : color,
          fontWeight: FontWeight.w700,
          fontSize: 11,
          letterSpacing: 1.2,
        ),
      ),
      style: OutlinedButton.styleFrom(
        side: BorderSide(
          color: loading ? RpgColors.border : color.withValues(alpha: 0.5),
        ),
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
    );
  }
}

// ── Day edit sheet ────────────────────────────────────────────────────────────

class _DayEditSheet extends StatelessWidget {
  final DateTime day;
  final bool? current;
  final void Function(bool isClean) onSelect;

  const _DayEditSheet({
    required this.day,
    required this.current,
    required this.onSelect,
  });

  static const _months = [
    'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
    'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC',
  ];

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final label =
        '${day.day} ${_months[day.month - 1]} ${day.year}';
    final statusText = current == true
        ? 'Currently logged as clean'
        : current == false
            ? 'Currently logged as relapsed'
            : 'Not yet logged';
    final statusColor = current == true
        ? _cleanColor
        : current == false
            ? _relapseColor
            : RpgColors.textMuted;

    return Container(
      decoration: BoxDecoration(
        color: RpgColors.panelBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        border: Border.all(color: RpgColors.border),
      ),
      padding: EdgeInsets.fromLTRB(24, 20, 24, 24 + bottomPad),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 3,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: RpgColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: RpgColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            statusText,
            style: TextStyle(color: statusColor, fontSize: 11),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _SheetButton(
                  label: 'CLEAN DAY',
                  icon: Icons.check_circle_outline,
                  color: _cleanColor,
                  onTap: () => onSelect(true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SheetButton(
                  label: 'RELAPSED',
                  icon: Icons.cancel_outlined,
                  color: _relapseColor,
                  onTap: () => onSelect(false),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SheetButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _SheetButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16, color: color),
      label: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 11,
          letterSpacing: 1.2,
        ),
      ),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: color.withValues(alpha: 0.5)),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
    );
  }
}

// ── Logged message ────────────────────────────────────────────────────────────

class _LoggedMessage extends StatelessWidget {
  final bool isClean;

  const _LoggedMessage({required this.isClean});

  @override
  Widget build(BuildContext context) {
    final color = isClean ? _cleanColor : _relapseColor;
    final icon = isClean ? Icons.check_circle : Icons.cancel;
    final text = isClean
        ? 'Logged as clean. Keep going — every day matters.'
        : 'Relapse logged. Be honest, stay aware, reset tomorrow.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: color.withValues(alpha: 0.85),
                fontSize: 11,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
