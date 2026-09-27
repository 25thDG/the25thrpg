import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/rpg_colors.dart';
import '../../domain/entities/japanese_milestone.dart';

const _jp = Color(0xFFFF7043);
const _jpLight = Color(0xFFFFAB91);

const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

/// Countdown to the next lifetime-hours milestone at this week's pace.
class MilestoneSection extends StatelessWidget {
  final MilestoneForecast forecast;
  final ValueChanged<JapaneseMilestone> onChanged;

  const MilestoneSection({
    super.key,
    required this.forecast,
    required this.onChanged,
  });

  Future<void> _edit(BuildContext context) async {
    final next = await MilestoneEditSheet.show(context, forecast.milestone);
    if (next != null) onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    final m = forecast.milestone;

    return GestureDetector(
      onTap: () => _edit(context),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: RpgColors.panelBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: RpgColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 0),
              child: Row(
                children: [
                  Container(width: 6, height: 6, color: _jp),
                  const SizedBox(width: 8),
                  const Text(
                    'NEXT MILESTONE',
                    style: TextStyle(
                      color: RpgColors.textSecondary,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2.4,
                    ),
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.edit_outlined,
                    size: 14,
                    color: RpgColors.textMuted,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Flexible(
                    child: Text(
                      m.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: RpgColors.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: Text(
                      '${m.targetHours} h',
                      style: const TextStyle(
                        color: RpgColors.textMuted,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Bar(progress: forecast.progress),
                  const SizedBox(height: 6),
                  Text(
                    forecast.isReached
                        ? 'Reached. Tap to set the next one.'
                        : '${forecast.remainingHours.toStringAsFixed(1)} h to go'
                            ' · ${forecast.lifetimeHours.toStringAsFixed(1)}'
                            ' / ${m.targetHours} h',
                    style: const TextStyle(
                      color: RpgColors.textMuted,
                      fontSize: 10,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
            if (!forecast.isReached) ...[
              Container(height: 1, color: RpgColors.divider),
              IntrinsicHeight(
                child: Row(
                  children: [
                    Expanded(
                      child: _Stat(
                        label: 'PACE · LAST 7 DAYS',
                        value: forecast.hoursPerWeek.toStringAsFixed(1),
                        unit: 'h/week',
                        caption: forecast.hoursPerWeek > 0
                            ? null
                            : 'Nothing logged this week',
                        color: _jp,
                      ),
                    ),
                    Container(width: 1, color: RpgColors.divider),
                    Expanded(child: _etaStat()),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _etaStat() {
    final days = forecast.daysLeft;
    if (days == null) {
      return const _Stat(
        label: 'ETA',
        value: '—',
        caption: 'Log a session to see it',
        color: _jpLight,
      );
    }
    final (value, unit) = _fmtDuration(days);
    final eta = forecast.etaFrom(DateTime.now())!;
    return _Stat(
      label: 'ETA',
      value: value,
      unit: unit,
      caption: '~${eta.day} ${_months[eta.month - 1]} ${eta.year}',
      color: _jpLight,
    );
  }

  /// Days rounded to the unit that reads naturally at that distance.
  (String, String) _fmtDuration(int days) {
    if (days < 14) return ('$days', days == 1 ? 'day' : 'days');
    if (days < 120) return ('${(days / 7).round()}', 'weeks');
    if (days < 730) return ('${(days / 30.44).round()}', 'months');
    return ((days / 365.25).toStringAsFixed(1), 'years');
  }
}

class _Bar extends StatelessWidget {
  final double progress;
  const _Bar({required this.progress});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: progress),
      duration: const Duration(milliseconds: 1400),
      curve: Curves.easeOutCubic,
      builder: (_, v, _) => ClipRRect(
        borderRadius: BorderRadius.circular(2),
        child: Stack(
          children: [
            Container(height: 6, color: RpgColors.progressTrack),
            FractionallySizedBox(
              widthFactor: v,
              child: Container(
                height: 6,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(colors: [_jp, _jpLight]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final String? unit;
  final String? caption;
  final Color color;

  const _Stat({
    required this.label,
    required this.value,
    this.unit,
    this.caption,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: RpgColors.textMuted,
              fontSize: 9,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.6,
            ),
          ),
          const SizedBox(height: 6),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: TextStyle(
                    color: color,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.6,
                  ),
                ),
                if (unit != null)
                  TextSpan(
                    text: ' $unit',
                    style: const TextStyle(
                      color: RpgColors.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.3,
                    ),
                  ),
              ],
            ),
          ),
          if (caption != null) ...[
            const SizedBox(height: 4),
            Text(
              caption!,
              style: const TextStyle(
                color: RpgColors.textMuted,
                fontSize: 10,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Sets the target hours and what reaching them means.
class MilestoneEditSheet extends StatefulWidget {
  final JapaneseMilestone current;

  const MilestoneEditSheet({super.key, required this.current});

  static Future<JapaneseMilestone?> show(
    BuildContext context,
    JapaneseMilestone current,
  ) {
    return showModalBottomSheet<JapaneseMilestone?>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MilestoneEditSheet(current: current),
    );
  }

  @override
  State<MilestoneEditSheet> createState() => _MilestoneEditSheetState();
}

class _MilestoneEditSheetState extends State<MilestoneEditSheet> {
  late final TextEditingController _hours;
  late final TextEditingController _label;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _hours = TextEditingController(text: '${widget.current.targetHours}');
    _label = TextEditingController(text: widget.current.label);
  }

  @override
  void dispose() {
    _hours.dispose();
    _label.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final label = _label.text.trim();
    Navigator.of(context).pop(JapaneseMilestone(
      targetHours: int.parse(_hours.text.trim()),
      label: label.isEmpty ? 'Milestone' : label,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: RpgColors.panelBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        border: Border(top: BorderSide(color: RpgColors.border)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
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
                Container(width: 6, height: 6, color: _jp),
                const SizedBox(width: 8),
                const Text(
                  'SET MILESTONE',
                  style: TextStyle(
                    color: RpgColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2.4,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const _FieldLabel('TARGET'),
            const SizedBox(height: 10),
            TextFormField(
              controller: _hours,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: _fieldStyle,
              decoration: _decoration(hint: '700', suffix: 'hours'),
              validator: (v) {
                final n = int.tryParse(v?.trim() ?? '');
                if (n == null || n <= 0) return 'Enter a positive number';
                return null;
              },
            ),
            const SizedBox(height: 22),
            const _FieldLabel('WHAT IT UNLOCKS'),
            const SizedBox(height: 10),
            TextFormField(
              controller: _label,
              textCapitalization: TextCapitalization.sentences,
              maxLength: 24,
              style: _fieldStyle,
              decoration: _decoration(hint: 'Japan'),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _submit,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: _jp.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: _jp.withValues(alpha: 0.4)),
                ),
                child: const Text(
                  'SAVE',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _jp,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.6,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static const _fieldStyle = TextStyle(
    color: RpgColors.textPrimary,
    fontSize: 18,
    fontWeight: FontWeight.w600,
  );

  InputDecoration _decoration({required String hint, String? suffix}) {
    OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide(color: c, width: w),
        );
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: RpgColors.textMuted, fontSize: 18),
      suffixText: suffix,
      suffixStyle: const TextStyle(
        color: RpgColors.textMuted,
        fontSize: 13,
        letterSpacing: 0.4,
      ),
      counterStyle: const TextStyle(color: RpgColors.textMuted, fontSize: 10),
      filled: true,
      fillColor: RpgColors.panelBgAlt,
      border: border(RpgColors.border),
      enabledBorder: border(RpgColors.border),
      focusedBorder: border(_jp, 1.5),
      errorBorder: border(const Color(0xFFEF5350)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

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
