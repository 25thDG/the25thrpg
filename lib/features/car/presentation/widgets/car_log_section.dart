import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/rpg_colors.dart';
import '../../domain/entities/car_stats.dart';
import 'car_formatters.dart';
import 'car_panel.dart';

const _error = Color(0xFFEF5350);

/// Logs today's odometer. The date is always today's calendar date, so there
/// is no date picker; saving again on the same day replaces the reading.
class CarLogSection extends StatefulWidget {
  final CarStats stats;
  final bool isBusy;
  final Future<String?> Function(int odometerKm) onSave;

  const CarLogSection({
    super.key,
    required this.stats,
    required this.isBusy,
    required this.onSave,
  });

  @override
  State<CarLogSection> createState() => _CarLogSectionState();
}

class _CarLogSectionState extends State<CarLogSection> {
  late final TextEditingController _controller;
  final _formKey = GlobalKey<FormState>();

  // Calendar date on purpose — only routines roll over at 04:00.
  DateTime get _today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  int? get _todayKm => widget.stats.snapshotOn(_today)?.odometerKm;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _todayKm?.toString() ?? '');
  }

  @override
  void didUpdateWidget(CarLogSection old) {
    super.didUpdateWidget(old);
    final newVal = _todayKm;
    if (newVal != old.stats.snapshotOn(_today)?.odometerKm) {
      _controller.text = newVal?.toString() ?? '';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final value = int.tryParse(_controller.text.trim());
    if (value == null) return;

    FocusScope.of(context).unfocus();
    final error = await widget.onSave(value);
    if (error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: _error),
      );
    }
  }

  String? _validate(String? v) {
    if (v == null || v.trim().isEmpty) return 'Enter the odometer reading';
    final km = int.tryParse(v.trim());
    if (km == null) return 'Enter a whole number of km';

    // An odometer only goes up, so a lower value is a typo.
    final floor = widget.stats.odometerFloorOn(_today);
    if (km < floor) {
      return 'Lower than the previous reading (${fmtKm(floor)} km)';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final stats = widget.stats;
    final isEdit = _todayKm != null;

    return CarPanel(
      title: 'LOG ODOMETER',
      trailing: fmtDay(_today).toUpperCase(),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  isEdit
                      ? "Today's snapshot is on record — saving will replace it."
                      : stats.hasSnapshots
                          ? 'Last reading ${fmtKm(stats.odometerKm)} km on '
                              '${fmtDay(stats.asOf)}.'
                          : 'Handover reading ${fmtKm(stats.odometerKm)} km.',
                  style: const TextStyle(
                    color: RpgColors.textMuted,
                    fontSize: 11,
                  ),
                ),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _controller,
                      enabled: !widget.isBusy,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      onFieldSubmitted: (_) => _submit(),
                      validator: _validate,
                      style: const TextStyle(
                        color: RpgColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: InputDecoration(
                        suffixText: 'km',
                        suffixStyle: const TextStyle(
                          color: RpgColors.textSecondary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        hintText: 'Odometer',
                        hintStyle: const TextStyle(
                            color: RpgColors.textMuted, fontSize: 18),
                        errorStyle:
                            const TextStyle(color: _error, fontSize: 11),
                        errorMaxLines: 2,
                        filled: true,
                        fillColor: RpgColors.panelBgAlt,
                        border: _border(RpgColors.border),
                        enabledBorder: _border(RpgColors.border),
                        disabledBorder: _border(RpgColors.border),
                        focusedBorder:
                            _border(RpgColors.textSecondary, width: 1.5),
                        errorBorder: _border(_error),
                        focusedErrorBorder: _border(_error, width: 1.5),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: widget.isBusy ? null : _submit,
                    child: Container(
                      width: 96,
                      height: 48,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: RpgColors.textPrimary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(3),
                        border: Border.all(
                          color: RpgColors.textPrimary.withValues(alpha: 0.35),
                        ),
                      ),
                      child: widget.isBusy
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: RpgColors.textPrimary,
                              ),
                            )
                          : Text(
                              isEdit ? 'UPDATE' : 'SAVE',
                              style: const TextStyle(
                                color: RpgColors.textPrimary,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.6,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  OutlineInputBorder _border(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(3),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}
