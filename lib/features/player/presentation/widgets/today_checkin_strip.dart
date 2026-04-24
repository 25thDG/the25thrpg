import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/datasources/today_status_datasource.dart';
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
          // Rainbow accent bar
          Container(
            height: 3,
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
              gradient: LinearGradient(
                colors: [_colorJp, _colorMind, _colorSober, _colorBudget],
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
                  _todayLabel(),
                  style: const TextStyle(
                    color: RpgColors.textMuted,
                    fontSize: 10,
                    letterSpacing: 0.4,
                  ),
                ),
              ],
            ),
          ),
          // Status row
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Center(
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    color: RpgColors.textMuted,
                  ),
                ),
              ),
            )
          else if (_status == null)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Text('—', style: TextStyle(color: RpgColors.textMuted)),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
              child: Row(
                children: [
                  Expanded(
                    child: _Chip(
                      label: 'JAPANESE',
                      value: _status!.jpMinutes > 0
                          ? '${_status!.jpMinutes}m'
                          : '—',
                      color: _status!.jpMinutes > 0
                          ? _colorJp
                          : RpgColors.textMuted,
                      icon: Icons.language,
                    ),
                  ),
                  Expanded(
                    child: _Chip(
                      label: 'MINDFUL',
                      value: _status!.mindMinutes > 0
                          ? '${_status!.mindMinutes}m'
                          : '—',
                      color: _status!.mindMinutes > 0
                          ? _colorMind
                          : RpgColors.textMuted,
                      icon: Icons.self_improvement,
                    ),
                  ),
                  Expanded(
                    child: _Chip(
                      label: 'SOBRIETY',
                      value: _status!.isClean == null
                          ? '—'
                          : (_status!.isClean! ? 'CLEAN' : 'RELAPSED'),
                      color: _status!.isClean == null
                          ? RpgColors.textMuted
                          : (_status!.isClean! ? _colorSober : _colorRelapse),
                      icon: _status!.isClean == null
                          ? Icons.radio_button_unchecked
                          : (_status!.isClean!
                              ? Icons.check_circle_outline
                              : Icons.cancel_outlined),
                    ),
                  ),
                  Expanded(
                    child: _Chip(
                      label: 'BUDGET',
                      value: _status!.budgetCents > 0
                          ? '€${(_status!.budgetCents / 100).toStringAsFixed(2)}'
                          : '—',
                      color: _status!.budgetCents > 3000
                          ? _colorRelapse
                          : (_status!.budgetCents > 0
                              ? _colorBudget
                              : RpgColors.textMuted),
                      icon: Icons.wallet_outlined,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _Chip({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: const TextStyle(
            color: RpgColors.textMuted,
            fontSize: 8,
            fontWeight: FontWeight.w500,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }
}
