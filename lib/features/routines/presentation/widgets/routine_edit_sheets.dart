import 'package:flutter/material.dart';

import '../../../player/presentation/widgets/rpg_colors.dart';
import '../../domain/entities/routine.dart';
import 'foundation_style.dart';

const _accent = FoundationColors.solid;

/// Asks for a name, and for a routine also which part of the day it belongs to.
///
/// Returns null when dismissed, so callers can tell "cancelled" from "saved an
/// empty name" without a sentinel.
Future<({String name, PartOfDay part})?> showRoutineSheet(
  BuildContext context, {
  Routine? existing,
}) {
  return showModalBottomSheet<({String name, PartOfDay part})>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _RoutineSheet(existing: existing),
  );
}

/// Name-only sheet, used for habits.
Future<String?> showHabitSheet(
  BuildContext context, {
  String? existing,
  required String routineName,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _HabitSheet(existing: existing, routineName: routineName),
  );
}

// ── Shell ─────────────────────────────────────────────────────────────────────

class _SheetShell extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<Widget> children;

  const _SheetShell({
    required this.title,
    required this.subtitle,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: RpgColors.panelBg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
          border: Border(top: BorderSide(color: RpgColors.border)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
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
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(
                color: RpgColors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 2.4,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: const TextStyle(
                color: RpgColors.textMuted,
                fontSize: 11,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 18),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _NameField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onSubmitted;

  const _NameField({
    required this.controller,
    required this.hint,
    required this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      autofocus: true,
      textCapitalization: TextCapitalization.sentences,
      textInputAction: TextInputAction.done,
      onSubmitted: onSubmitted,
      style: const TextStyle(color: RpgColors.textPrimary, fontSize: 15),
      cursorColor: _accent,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: RpgColors.textMuted, fontSize: 14),
        filled: true,
        fillColor: RpgColors.panelBgAlt,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: RpgColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _accent),
        ),
      ),
    );
  }
}

class _SaveButton extends StatelessWidget {
  final VoidCallback onTap;

  const _SaveButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _accent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _accent.withValues(alpha: 0.4)),
          ),
          child: const Text(
            'SAVE',
            style: TextStyle(
              color: _accent,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 2.0,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Routine ───────────────────────────────────────────────────────────────────

class _RoutineSheet extends StatefulWidget {
  final Routine? existing;

  const _RoutineSheet({this.existing});

  @override
  State<_RoutineSheet> createState() => _RoutineSheetState();
}

class _RoutineSheetState extends State<_RoutineSheet> {
  late final TextEditingController _name =
      TextEditingController(text: widget.existing?.name ?? '');
  late PartOfDay _part = widget.existing?.partOfDay ?? PartOfDay.morning;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _save([String? _]) {
    final name = _name.text.trim();
    if (name.isEmpty) return;
    Navigator.of(context).pop((name: name, part: _part));
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.existing != null;

    return _SheetShell(
      title: editing ? 'EDIT ROUTINE' : 'NEW ROUTINE',
      subtitle: 'A group of habits that belong to one part of the day.',
      children: [
        _NameField(
          controller: _name,
          hint: 'Morning',
          onSubmitted: _save,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            for (final (i, part) in PartOfDay.values.indexed) ...[
              if (i > 0) const SizedBox(width: 8),
              Expanded(
                child: _PartOption(
                  part: part,
                  selected: part == _part,
                  onTap: () => setState(() => _part = part),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 20),
        _SaveButton(onTap: _save),
      ],
    );
  }
}

class _PartOption extends StatelessWidget {
  final PartOfDay part;
  final bool selected;
  final VoidCallback onTap;

  const _PartOption({
    required this.part,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 11),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: _accent.withValues(alpha: selected ? 0.14 : 0.03),
            border: Border.all(
              color: _accent.withValues(alpha: selected ? 0.45 : 0.10),
            ),
          ),
          child: Text(
            part.displayName,
            style: TextStyle(
              color: selected ? _accent : RpgColors.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Habit ─────────────────────────────────────────────────────────────────────

class _HabitSheet extends StatefulWidget {
  final String? existing;
  final String routineName;

  const _HabitSheet({this.existing, required this.routineName});

  @override
  State<_HabitSheet> createState() => _HabitSheetState();
}

class _HabitSheetState extends State<_HabitSheet> {
  late final TextEditingController _name =
      TextEditingController(text: widget.existing ?? '');

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _save([String? _]) {
    final name = _name.text.trim();
    if (name.isEmpty) return;
    Navigator.of(context).pop(name);
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.existing != null;

    return _SheetShell(
      title: editing ? 'EDIT HABIT' : 'NEW HABIT',
      subtitle: editing
          ? 'Renaming keeps every day already recorded.'
          : 'Into ${widget.routineName}. Small enough to do on a bad day.',
      children: [
        _NameField(
          controller: _name,
          hint: 'Read one page',
          onSubmitted: _save,
        ),
        const SizedBox(height: 20),
        _SaveButton(onTap: _save),
      ],
    );
  }
}

// ── Confirm ───────────────────────────────────────────────────────────────────

/// Shared confirm for removing a routine or a habit.
Future<bool> confirmDelete(
  BuildContext context, {
  required String what,
  required String detail,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: RpgColors.panelBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: RpgColors.border),
      ),
      title: Text(
        'Remove $what?',
        style: const TextStyle(
          color: RpgColors.textPrimary,
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
      ),
      content: Text(
        detail,
        style: const TextStyle(
          color: RpgColors.textSecondary,
          fontSize: 13,
          height: 1.45,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text(
            'KEEP',
            style: TextStyle(color: RpgColors.textMuted, fontSize: 12),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text(
            'REMOVE',
            style: TextStyle(
              color: FoundationColors.broken,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );
  return result ?? false;
}
