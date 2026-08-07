import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/rpg_colors.dart';
import '../../domain/entities/quest.dart';

const _colorQuest = Color(0xFFF59E0B);

const _difficultyColors = {
  QuestDifficulty.side: Color(0xFF607D8B),
  QuestDifficulty.normal: Color(0xFFF59E0B),
  QuestDifficulty.epic: Color(0xFFAB47BC),
  QuestDifficulty.legendary: Color(0xFFEF5350),
};

class QuestAddSheet extends StatefulWidget {
  final Quest? existing;

  const QuestAddSheet({super.key, this.existing});

  static Future<QuestFormResult?> show(BuildContext context,
          {Quest? existing}) =>
      showModalBottomSheet<QuestFormResult>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => QuestAddSheet(existing: existing),
      );

  @override
  State<QuestAddSheet> createState() => _QuestAddSheetState();
}

class _QuestAddSheetState extends State<QuestAddSheet> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _xpController = TextEditingController();
  final _objectiveController = TextEditingController();
  final _rewardController = TextEditingController();
  final _rewardCostController = TextEditingController();

  QuestDifficulty _difficulty = QuestDifficulty.normal;
  List<_DraftObjective> _objectives = [];
  DateTime? _targetDate;

  @override
  void initState() {
    super.initState();
    final q = widget.existing;
    if (q != null) {
      _titleController.text = q.title;
      _descController.text = q.description ?? '';
      _xpController.text = '${q.xpReward}';
      _difficulty = q.difficulty;
      _objectives = q.objectives
          .map((o) => _DraftObjective(id: o.id, text: o.text, completed: o.completed))
          .toList();
      _targetDate = q.targetDate;
      _rewardController.text = q.rewardText ?? '';
      _rewardCostController.text = q.rewardCostCents != null
          ? (q.rewardCostCents! / 100).toStringAsFixed(0)
          : '';
    } else {
      _xpController.text = '${QuestDifficulty.normal.defaultXp}';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _xpController.dispose();
    _objectiveController.dispose();
    _rewardController.dispose();
    _rewardCostController.dispose();
    super.dispose();
  }

  Future<void> _pickTargetDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _targetDate ?? now.add(const Duration(days: 90)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365 * 5)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: _colorQuest,
            surface: RpgColors.panelBg,
            onSurface: RpgColors.textPrimary,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _targetDate = picked);
  }

  void _onDifficultyChanged(QuestDifficulty d) {
    setState(() {
      _difficulty = d;
      if (widget.existing == null ||
          _xpController.text == '${widget.existing!.difficulty.defaultXp}') {
        _xpController.text = '${d.defaultXp}';
      }
    });
  }

  void _addObjective() {
    final text = _objectiveController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _objectives.add(_DraftObjective(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: text,
        completed: false,
      ));
      _objectiveController.clear();
    });
  }

  void _submit() {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;
    final xp = int.tryParse(_xpController.text.trim()) ?? _difficulty.defaultXp;
    final objectives = _objectives
        .map((o) => QuestObjective(id: o.id, text: o.text, completed: o.completed))
        .toList();
    final reward = _rewardController.text.trim();
    final costEuros = int.tryParse(_rewardCostController.text.trim());

    Navigator.pop(
      context,
      QuestFormResult(
        title: title,
        description: _descController.text.trim().isEmpty
            ? null
            : _descController.text.trim(),
        xpReward: xp,
        difficulty: _difficulty,
        objectives: objectives,
        targetDate: _targetDate,
        rewardText: reward.isEmpty ? null : reward,
        // Cost only means something alongside a named reward.
        rewardCostCents:
            reward.isEmpty || costEuros == null ? null : costEuros * 100,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).viewInsets.bottom;
    final isEdit = widget.existing != null;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.92,
      ),
      decoration: const BoxDecoration(
        color: RpgColors.panelBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        border: Border(top: BorderSide(color: RpgColors.border)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(20, 0, 20, bottomPad + 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isEdit ? 'EDIT QUEST' : 'NEW QUEST',
                    style: const TextStyle(
                      color: RpgColors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2.4,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Title
                  _label('TITLE'),
                  const SizedBox(height: 8),
                  _darkField(
                    controller: _titleController,
                    hint: 'Quest name...',
                    autofocus: true,
                  ),
                  const SizedBox(height: 16),

                  // Description
                  _label('DESCRIPTION  (optional)'),
                  const SizedBox(height: 8),
                  _darkField(
                    controller: _descController,
                    hint: 'What needs to be done...',
                    maxLines: 2,
                  ),
                  const SizedBox(height: 20),

                  // Difficulty
                  _label('DIFFICULTY'),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: QuestDifficulty.values.map((d) {
                      final selected = _difficulty == d;
                      final color = _difficultyColors[d]!;
                      return GestureDetector(
                        onTap: () => _onDifficultyChanged(d),
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
                            d.displayName.toUpperCase(),
                            style: TextStyle(
                              color: selected ? color : RpgColors.textMuted,
                              fontSize: 11,
                              fontWeight: selected
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // XP Reward
                  _label('XP REWARD'),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: 120,
                    child: TextFormField(
                      controller: _xpController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      style: TextStyle(
                        color: _difficultyColors[_difficulty],
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                      decoration: InputDecoration(
                        suffixText: 'XP',
                        suffixStyle: const TextStyle(
                          color: RpgColors.textMuted,
                          fontSize: 12,
                        ),
                        filled: true,
                        fillColor: RpgColors.panelBgAlt,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4),
                          borderSide:
                              const BorderSide(color: RpgColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4),
                          borderSide: BorderSide(
                              color: _colorQuest.withValues(alpha: 0.6)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Target date — drives the days-left and pace readout
                  _label('TARGET DATE'),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: _pickTargetDate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 14),
                      decoration: BoxDecoration(
                        color: RpgColors.panelBgAlt,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: RpgColors.border),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.flag_outlined,
                              size: 16, color: RpgColors.textMuted),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _targetDate == null
                                  ? 'No deadline'
                                  : _fmtDate(_targetDate!),
                              style: TextStyle(
                                color: _targetDate == null
                                    ? RpgColors.textMuted
                                    : RpgColors.textPrimary,
                                fontSize: 13,
                                fontWeight: _targetDate == null
                                    ? FontWeight.w400
                                    : FontWeight.w600,
                              ),
                            ),
                          ),
                          if (_targetDate != null)
                            GestureDetector(
                              onTap: () => setState(() => _targetDate = null),
                              child: const Icon(Icons.close,
                                  size: 16, color: RpgColors.textMuted),
                            )
                          else
                            const Icon(Icons.chevron_right,
                                size: 16, color: RpgColors.textMuted),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Real-world reward
                  _label('REWARD'),
                  const SizedBox(height: 4),
                  const Text(
                    'What you get in real life when this is done. '
                    'Set the price so it is planned, not a surprise.',
                    style: TextStyle(
                      color: RpgColors.textMuted,
                      fontSize: 10,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _darkField(
                    controller: _rewardController,
                    hint: 'e.g. New phone',
                  ),
                  const SizedBox(height: 8),
                  _darkField(
                    controller: _rewardCostController,
                    hint: 'Cost in € (optional)',
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                  const SizedBox(height: 20),

                  // Objectives
                  _label('OBJECTIVES'),
                  const SizedBox(height: 10),
                  if (_objectives.isNotEmpty)
                    ...List.generate(_objectives.length, (i) {
                      final obj = _objectives[i];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: [
                            Container(
                              width: 16,
                              height: 16,
                              margin: const EdgeInsets.only(right: 10),
                              decoration: BoxDecoration(
                                border: Border.all(color: RpgColors.border),
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                obj.text,
                                style: const TextStyle(
                                  color: RpgColors.textSecondary,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () =>
                                  setState(() => _objectives.removeAt(i)),
                              child: const Icon(Icons.close,
                                  size: 16, color: RpgColors.textMuted),
                            ),
                          ],
                        ),
                      );
                    }),
                  Row(
                    children: [
                      Expanded(
                        child: _darkField(
                          controller: _objectiveController,
                          hint: 'Add objective...',
                          onSubmitted: (_) => _addObjective(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _addObjective,
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: _colorQuest.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                                color: _colorQuest.withValues(alpha: 0.4)),
                          ),
                          child: const Icon(Icons.add,
                              color: _colorQuest, size: 18),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  GestureDetector(
                    onTap: _submit,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      decoration: BoxDecoration(
                        color: _colorQuest.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                            color: _colorQuest.withValues(alpha: 0.6)),
                      ),
                      child: Center(
                        child: Text(
                          isEdit ? 'SAVE CHANGES' : 'CREATE QUEST',
                          style: const TextStyle(
                            color: _colorQuest,
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
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String text) => Text(
        text,
        style: const TextStyle(
          color: RpgColors.textMuted,
          fontSize: 9,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.8,
        ),
      );

  static String _fmtDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }

  Widget _darkField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    bool autofocus = false,
    void Function(String)? onSubmitted,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) =>
      TextFormField(
        controller: controller,
        autofocus: autofocus,
        maxLines: maxLines,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        style: const TextStyle(color: RpgColors.textPrimary, fontSize: 14),
        onFieldSubmitted: onSubmitted,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: RpgColors.textMuted, fontSize: 14),
          filled: true,
          fillColor: RpgColors.panelBgAlt,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: const BorderSide(color: RpgColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide:
                BorderSide(color: _colorQuest.withValues(alpha: 0.6)),
          ),
        ),
      );
}

class _DraftObjective {
  final String id;
  final String text;
  final bool completed;
  _DraftObjective({required this.id, required this.text, required this.completed});
}

class QuestFormResult {
  final String title;
  final String? description;
  final int xpReward;
  final QuestDifficulty difficulty;
  final List<QuestObjective> objectives;
  final DateTime? targetDate;
  final String? rewardText;
  final int? rewardCostCents;

  const QuestFormResult({
    required this.title,
    this.description,
    required this.xpReward,
    required this.difficulty,
    required this.objectives,
    this.targetDate,
    this.rewardText,
    this.rewardCostCents,
  });
}
