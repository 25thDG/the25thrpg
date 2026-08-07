import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/datasources/today_status_datasource.dart';
import 'player_section.dart';
import 'player_stat_grid.dart';
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
      child: _loading
          ? const Padding(
              padding: EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  color: RpgColors.textMuted,
                ),
              ),
            )
          : PlayerStatGrid(cells: _cells()),
    );
  }

  /// Today's four check-ins, in the same label/value shape as the character's
  /// summary stats above.
  List<PlayerStatCell> _cells() {
    final s = _status;
    if (s == null) {
      return const [
        PlayerStatCell(label: 'JAPANESE', value: '\u2014'),
        PlayerStatCell(label: 'MINDFUL', value: '\u2014'),
        PlayerStatCell(label: 'SOBRIETY', value: '\u2014'),
        PlayerStatCell(label: 'BUDGET', value: '\u2014'),
      ];
    }

    return [
      PlayerStatCell(
        label: 'JAPANESE',
        value: s.jpMinutes > 0 ? '${s.jpMinutes}m' : '\u2014',
        valueColor: s.jpMinutes > 0 ? _colorJp : null,
      ),
      PlayerStatCell(
        label: 'MINDFUL',
        value: s.mindMinutes > 0 ? '${s.mindMinutes}m' : '\u2014',
        valueColor: s.mindMinutes > 0 ? _colorMind : null,
      ),
      PlayerStatCell(
        label: 'SOBRIETY',
        value: s.isClean == null
            ? '\u2014'
            : (s.isClean! ? 'CLEAN' : 'RELAPSED'),
        valueColor: s.isClean == null
            ? null
            : (s.isClean! ? _colorSober : _colorRelapse),
        flex: 4,
      ),
      PlayerStatCell(
        label: 'BUDGET',
        value: s.budgetCents > 0
            ? '\u20AC${(s.budgetCents / 100).toStringAsFixed(0)}'
            : '\u2014',
        valueColor: s.budgetCents > 3000
            ? _colorRelapse
            : (s.budgetCents > 0 ? _colorBudget : null),
      ),
    ];
  }
}
