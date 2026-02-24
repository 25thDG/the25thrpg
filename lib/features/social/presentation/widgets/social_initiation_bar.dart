import 'package:flutter/material.dart';

/// A calm split bar showing self vs other initiation.
class SocialInitiationBar extends StatelessWidget {
  final double selfPct; // 0–100
  final int selfMinutes;
  final int otherMinutes;

  const SocialInitiationBar({
    super.key,
    required this.selfPct,
    required this.selfMinutes,
    required this.otherMinutes,
  });

  String _fmtMin(int min) {
    if (min == 0) return '0 min';
    final h = min ~/ 60;
    final m = min % 60;
    if (h == 0) return '${m}min';
    if (m == 0) return '${h}h';
    return '${h}h ${m}min';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selfFrac = (selfPct / 100).clamp(0.0, 1.0);
    final otherFrac = 1.0 - selfFrac;
    final hasData = selfMinutes + otherMinutes > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Split bar
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: SizedBox(
            height: 6,
            child: hasData
                ? Row(
                    children: [
                      if (selfFrac > 0)
                        Expanded(
                          flex: (selfFrac * 1000).round(),
                          child: ColoredBox(
                            color: theme.colorScheme.primary
                                .withValues(alpha: 0.75),
                          ),
                        ),
                      if (otherFrac > 0)
                        Expanded(
                          flex: (otherFrac * 1000).round(),
                          child: ColoredBox(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.12),
                          ),
                        ),
                    ],
                  )
                : ColoredBox(
                    color:
                        theme.colorScheme.onSurface.withValues(alpha: 0.08),
                  ),
          ),
        ),
        const SizedBox(height: 8),
        // Labels
        Row(
          children: [
            _Label(
              color: theme.colorScheme.primary.withValues(alpha: 0.75),
              label: 'You initiated',
              value: hasData
                  ? '${selfPct.toStringAsFixed(0)}% · ${_fmtMin(selfMinutes)}'
                  : '—',
              theme: theme,
            ),
            const Spacer(),
            _Label(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
              label: 'Others initiated',
              value: hasData
                  ? '${(100 - selfPct).toStringAsFixed(0)}% · ${_fmtMin(otherMinutes)}'
                  : '—',
              theme: theme,
              alignRight: true,
            ),
          ],
        ),
      ],
    );
  }
}

class _Label extends StatelessWidget {
  final Color color;
  final String label;
  final String value;
  final ThemeData theme;
  final bool alignRight;

  const _Label({
    required this.color,
    required this.label,
    required this.value,
    required this.theme,
    this.alignRight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          alignRight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!alignRight) ...[
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
            if (alignRight) ...[
              const SizedBox(width: 4),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }
}
