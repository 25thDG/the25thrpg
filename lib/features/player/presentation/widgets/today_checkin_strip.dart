import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/datasources/today_status_datasource.dart';
import 'player_card.dart';
import 'player_section.dart';
import 'rpg_colors.dart';

const _colorJp = Color(0xFF4FC3F7);
const _colorMind = Color(0xFF26A69A);
const _colorSober = Color(0xFF66BB6A);
const _colorBudget = Color(0xFFFFD54F);
const _colorRelapse = Color(0xFFEF5350);

class TodayCheckInStrip extends StatefulWidget {
  const TodayCheckInStrip({super.key});

  @override
  State<TodayCheckInStrip> createState() => _TodayCheckInStripState();
}

class _TodayCheckInStripState extends State<TodayCheckInStrip> {
  late final TodayStatusDatasource _ds;
  TodayStatus? _status;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _ds = TodayStatusDatasource(Supabase.instance.client);
    _load();
  }

  Future<void> _load() async {
    try {
      final status = await _ds.fetch();
      if (mounted) setState(() { _status = status; _loading = false; });
    } catch (_) {
      if (mounted) setState(() { _loading = false; });
    }
  }

  String _todayLabel() {
    final d = DateTime.now();
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[d.month - 1]} ${d.day}';
  }

  @override
  Widget build(BuildContext context) {
    return PlayerSection(
      title: 'TODAY',
      trailing: _todayLabel(),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
        child: PlayerCard(
          margin: EdgeInsets.zero,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 14),
          child: _loading
              ? const SizedBox(
                  height: 44,
                  child: Center(
                    child: SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.5,
                        color: RpgColors.textMuted,
                      ),
                    ),
                  ),
                )
              : Row(children: [for (final t in _tiles()) Expanded(child: t)]),
        ),
      ),
    );
  }

  /// Today's four check-ins as a quick-access dock.
  List<Widget> _tiles() {
    final s = _status;
    if (s == null) {
      return const [
        _DockTile(icon: Icons.language, label: 'JAPANESE', value: '\u2014'),
        _DockTile(
            icon: Icons.self_improvement, label: 'MINDFUL', value: '\u2014'),
        _DockTile(
            icon: Icons.shield_outlined, label: 'SOBRIETY', value: '\u2014'),
        _DockTile(icon: Icons.wallet_outlined, label: 'BUDGET', value: '\u2014'),
      ];
    }

    return [
      _DockTile(
        icon: Icons.language,
        label: 'JAPANESE',
        value: s.jpMinutes > 0 ? '${s.jpMinutes}m' : '\u2014',
        color: s.jpMinutes > 0 ? _colorJp : null,
      ),
      _DockTile(
        icon: Icons.self_improvement,
        label: 'MINDFUL',
        value: s.mindMinutes > 0 ? '${s.mindMinutes}m' : '\u2014',
        color: s.mindMinutes > 0 ? _colorMind : null,
      ),
      _DockTile(
        icon: s.isClean == null
            ? Icons.shield_outlined
            : (s.isClean! ? Icons.verified_outlined : Icons.error_outline),
        label: 'SOBRIETY',
        value: s.isClean == null
            ? '\u2014'
            : (s.isClean! ? 'CLEAN' : 'SLIP'),
        color: s.isClean == null
            ? null
            : (s.isClean! ? _colorSober : _colorRelapse),
      ),
      _DockTile(
        icon: Icons.wallet_outlined,
        label: 'BUDGET',
        value: s.budgetCents > 0
            ? '\u20AC${(s.budgetCents / 100).toStringAsFixed(0)}'
            : '\u2014',
        color: s.budgetCents > 3000
            ? _colorRelapse
            : (s.budgetCents > 0 ? _colorBudget : null),
      ),
    ];
  }
}

/// One slot of the dock: a glowing icon puck over its value.
class _DockTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? color;

  const _DockTile({
    required this.icon,
    required this.label,
    required this.value,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final active = color != null;
    final tint = color ?? RpgColors.textMuted;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: tint.withValues(alpha: active ? 0.14 : 0.06),
            border: Border.all(
              color: tint.withValues(alpha: active ? 0.45 : 0.15),
            ),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: tint.withValues(alpha: 0.28),
                      blurRadius: 12,
                    ),
                  ]
                : null,
          ),
          child: Icon(icon, size: 17, color: tint),
        ),
        const SizedBox(height: 8),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            maxLines: 1,
            style: TextStyle(
              color: active ? tint : RpgColors.textMuted,
              fontSize: 13,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
            ),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: const TextStyle(
            color: RpgColors.textMuted,
            fontSize: 7,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.0,
          ),
        ),
      ],
    );
  }
}
