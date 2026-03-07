import 'package:flutter/material.dart';

import '../../domain/entities/wealth_stats.dart';
import 'section_card.dart';
import 'wealth_formatters.dart';

class WealthMillionSection extends StatelessWidget {
  final WealthStats stats;

  const WealthMillionSection({super.key, required this.stats});

  static const _target = 1_000_000.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final current = stats.currentNetWorth;

    if (current == null || !stats.hasData) return const SizedBox.shrink();

    Widget content;

    if (current >= _target) {
      content = _buildReached(theme);
    } else if (stats.monthlyHistory.length < 2) {
      content = _buildNeedMoreData(theme, current);
    } else {
      final avgMonthlyGrowth = _calcAvgMonthlyGrowth();
      if (avgMonthlyGrowth <= 0) {
        content = _buildNotGrowing(theme, current, avgMonthlyGrowth);
      } else {
        final monthsLeft = (_target - current) / avgMonthlyGrowth;
        final targetDate = _addMonths(DateTime.now(), monthsLeft.ceil());
        content = _buildProjection(
            theme, current, avgMonthlyGrowth, monthsLeft, targetDate);
      }
    }

    return SectionCard(title: '\u20ac1M Goal', child: content);
  }

  double _calcAvgMonthlyGrowth() {
    final h = stats.monthlyHistory;
    final first = h.first;
    final last = h.last;
    final months = (last.snapshotMonth.year - first.snapshotMonth.year) * 12 +
        (last.snapshotMonth.month - first.snapshotMonth.month);
    if (months == 0) return last.netWorthEur - first.netWorthEur;
    return (last.netWorthEur - first.netWorthEur) / months;
  }

  DateTime _addMonths(DateTime date, int months) {
    var m = date.month + months;
    final y = date.year + (m - 1) ~/ 12;
    m = ((m - 1) % 12) + 1;
    return DateTime(y, m, 1);
  }

  Widget _buildReached(ThemeData theme) {
    return Row(
      children: [
        const SizedBox(width: 4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "You've reached \u20ac1,000,000!",
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Goal achieved.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNeedMoreData(ThemeData theme, double current) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ProgressBar(progress: current / _target, theme: theme),
        const SizedBox(height: 10),
        Text(
          '${fmtEur(_target - current)} remaining',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Add more monthly snapshots to see your projected arrival date.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
          ),
        ),
      ],
    );
  }

  Widget _buildNotGrowing(ThemeData theme, double current, double growth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ProgressBar(progress: current / _target, theme: theme),
        const SizedBox(height: 10),
        Text(
          '${fmtEur(_target - current)} remaining',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          growth == 0
              ? 'No growth detected yet — keep adding snapshots!'
              : 'Net worth is declining (${fmtEurCompact(growth)}/mo avg).',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.error.withValues(alpha: 0.85),
          ),
        ),
      ],
    );
  }

  Widget _buildProjection(
    ThemeData theme,
    double current,
    double avgMonthlyGrowth,
    double monthsLeft,
    DateTime targetDate,
  ) {
    final years = (monthsLeft / 12).floor();
    final months = monthsLeft.ceil() % 12;
    final timeStr = years > 0
        ? '$years yr${years > 1 ? 's' : ''}${months > 0 ? ' $months mo' : ''}'
        : '${monthsLeft.ceil()} mo';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ProgressBar(progress: current / _target, theme: theme),
        const SizedBox(height: 14),
        Row(
          children: [
            _Stat(
              label: 'Estimated',
              value: fmtMonth(targetDate),
              theme: theme,
              highlighted: true,
            ),
            const SizedBox(width: 20),
            _Stat(
              label: 'Time left',
              value: timeStr,
              theme: theme,
            ),
            const SizedBox(width: 20),
            _Stat(
              label: 'Avg/month',
              value:
                  '${avgMonthlyGrowth >= 0 ? '+' : ''}${fmtEurCompact(avgMonthlyGrowth)}',
              theme: theme,
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          '${fmtEur(_target - current)} remaining',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
          ),
        ),
      ],
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final double progress;
  final ThemeData theme;

  const _ProgressBar({required this.progress, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${(progress * 100).toStringAsFixed(1)}%',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.primary,
              ),
            ),
            Text(
              '\u20ac1,000,000',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            minHeight: 8,
            backgroundColor:
                theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
            valueColor: AlwaysStoppedAnimation(theme.colorScheme.primary),
          ),
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final ThemeData theme;
  final bool highlighted;

  const _Stat({
    required this.label,
    required this.value,
    required this.theme,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
            fontSize: 9,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: highlighted
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}
