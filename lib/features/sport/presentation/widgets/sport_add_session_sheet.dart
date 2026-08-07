import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/rpg_colors.dart';
import '../../domain/entities/sport_session.dart';

const _colorSport = Color(0xFFFF7043);

const _categoryColors = {
  SportCategory.strength: Color(0xFFEF5350),
  SportCategory.cardio: Color(0xFFFF7043),
  SportCategory.mobility: Color(0xFF26A69A),
  SportCategory.sportSpecific: Color(0xFF7986CB),
};

class SportAddSessionSheet extends StatefulWidget {
  final SportSession? existing;

  const SportAddSessionSheet({super.key, this.existing});

  static Future<(SportCategory, int)?> show(
    BuildContext context, {
    SportSession? existing,
  }) =>
      showModalBottomSheet<(SportCategory, int)>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => SportAddSessionSheet(existing: existing),
      );

  @override
  State<SportAddSessionSheet> createState() => _SportAddSessionSheetState();
}

class _SportAddSessionSheetState extends State<SportAddSessionSheet> {
  late SportCategory _category;
  final _minutesController = TextEditingController();
  @override
  void initState() {
    super.initState();
    _category = widget.existing?.category ?? SportCategory.strength;
    if (widget.existing != null) {
      _minutesController.text = '${widget.existing!.minutes}';
    }
  }

  @override
  void dispose() {
    _minutesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final minutes = int.tryParse(_minutesController.text.trim());
    if (minutes == null || minutes <= 0) return;
    if (!context.mounted) return;
    Navigator.pop(context, (_category, minutes));
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).viewInsets.bottom;
    final isEdit = widget.existing != null;

    return Container(
      decoration: const BoxDecoration(
        color: RpgColors.panelBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        border: Border(top: BorderSide(color: RpgColors.border)),
      ),
      padding: EdgeInsets.fromLTRB(20, 0, 20, bottomPad + 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 3,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: RpgColors.textMuted,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text(
            isEdit ? 'EDIT SESSION' : 'LOG SESSION',
            style: const TextStyle(
              color: RpgColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 2.4,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'CATEGORY',
            style: TextStyle(
              color: RpgColors.textMuted,
              fontSize: 9,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.8,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: SportCategory.values.map((cat) {
              final selected = _category == cat;
              final color = _categoryColors[cat] ?? _colorSport;
              return GestureDetector(
                onTap: () => setState(() => _category = cat),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: selected
                        ? color.withValues(alpha: 0.15)
                        : RpgColors.panelBgAlt,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: selected
                          ? color.withValues(alpha: 0.7)
                          : RpgColors.border,
                      width: selected ? 1.5 : 1,
                    ),
                  ),
                  child: Text(
                    cat.displayName,
                    style: TextStyle(
                      color: selected ? color : RpgColors.textMuted,
                      fontSize: 12,
                      fontWeight: selected
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          const Text(
            'DURATION',
            style: TextStyle(
              color: RpgColors.textMuted,
              fontSize: 9,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.8,
            ),
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _minutesController,
            autofocus: true,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: const TextStyle(
              color: RpgColors.textPrimary,
              fontSize: 15,
            ),
            decoration: InputDecoration(
              hintText: '45',
              hintStyle: const TextStyle(color: RpgColors.textMuted),
              suffixText: 'min',
              suffixStyle: const TextStyle(
                  color: RpgColors.textMuted, fontSize: 13),
              filled: true,
              fillColor: RpgColors.panelBgAlt,
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 12),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: const BorderSide(color: RpgColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide:
                    BorderSide(color: _colorSport.withValues(alpha: 0.7)),
              ),
            ),
            onFieldSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: _submit,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 13),
              decoration: BoxDecoration(
                color: _colorSport.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                    color: _colorSport.withValues(alpha: 0.6)),
              ),
              child: Center(
                child: Text(
                  isEdit ? 'SAVE CHANGES' : 'LOG SESSION',
                  style: const TextStyle(
                    color: _colorSport,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.6,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
