import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';

import '../../domain/entities/quest.dart';

// ── Palette: flat dark panels on true black, neon for what you can act on ────

const _panel = Color(0xFF151517);
const _panelRaised = Color(0xFF1C1C1E);
const _hairline = Color(0xFF2C2C2E);

const _textPrimary = Color(0xFFF5F5F7);
const _textSecondary = Color(0xFF98989F);
const _textMuted = Color(0xFF636366);

const _mint = Color(0xFF3CF2A3);
const _purple = Color(0xFFB45CFF);
const _red = Color(0xFFFF4B5C);
const _amber = Color(0xFFFFB020);

/// Rank as a neon accent, bright enough to read against the dark panels.
const _rankColors = {
  QuestDifficulty.side: Color(0xFF8E8E93),
  QuestDifficulty.normal: _amber,
  QuestDifficulty.epic: _purple,
  QuestDifficulty.legendary: _red,
};

const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

/// The platform sans — SF Pro on Apple platforms, Roboto on Android.
TextStyle _type(
  double size, {
  Color color = _textPrimary,
  FontWeight weight = FontWeight.w400,
  double spacing = 0,
  double? height,
  TextDecoration? decoration,
}) =>
    TextStyle(
      fontSize: size,
      color: color,
      fontWeight: weight,
      letterSpacing: spacing,
      height: height,
      decoration: decoration,
      decorationColor: color,
    );

/// Small, tracked-out caps for category labels such as "EPIC QUEST".
TextStyle _label(Color color, {double size = 10.5}) =>
    _type(size, color: color, weight: FontWeight.w700, spacing: 1.8);

String _fmtDate(DateTime d) => '${d.day} ${_months[d.month - 1]} ${d.year}';

/// "6 Dec", with the year only when it isn't this one.
String _fmtShortDate(DateTime d) => d.year == DateTime.now().year
    ? '${d.day} ${_months[d.month - 1]}'
    : _fmtDate(d);

String _fmtDays(int days) {
  if (days == 1) return '1 day';
  if (days < 60) return '$days days';
  if (days < 365) return '${(days / 30).round()} months';
  return '${(days / 365).toStringAsFixed(1)} years';
}

// ── The board ─────────────────────────────────────────────────────────────────

/// A header with the tallies; every panel stacks below it.
class QuestBoard extends StatelessWidget {
  final int openCount;
  final int fulfilledCount;
  final List<Widget> children;

  const QuestBoard({
    super.key,
    required this.openCount,
    required this.fulfilledCount,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _BoardHeader(open: openCount, fulfilled: fulfilledCount),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }
}

class _BoardHeader extends StatelessWidget {
  final int open;
  final int fulfilled;

  const _BoardHeader({required this.open, required this.fulfilled});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quest Board',
            style: _type(
              28,
              weight: FontWeight.w800,
              spacing: -0.6,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _Tally(count: open, label: 'OPEN', color: _mint),
              const SizedBox(width: 8),
              _Tally(count: fulfilled, label: 'FULFILLED', color: _purple),
            ],
          ),
        ],
      ),
    );
  }
}

class _Tally extends StatelessWidget {
  final int count;
  final String label;
  final Color color;

  const _Tally({required this.count, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 6, 12, 6),
      decoration: BoxDecoration(
        color: _panel,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
          const SizedBox(width: 8),
          Text('$count', style: _type(13, weight: FontWeight.w700)),
          const SizedBox(width: 6),
          Text(label, style: _label(_textSecondary, size: 10)),
        ],
      ),
    );
  }
}

// ── Panels, badges and buttons ────────────────────────────────────────────────

/// A flat quest container: no shadow, no border, heavy radius.
class _Panel extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;

  const _Panel({required this.child, required this.padding});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: _panel,
        borderRadius: BorderRadius.circular(20),
      ),
      child: child,
    );
  }
}

/// A flat circle: tinted fill, neon ring.
class _Badge extends StatelessWidget {
  final Color color;
  final Widget child;

  const _Badge({required this.color, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.14),
        border: Border.all(color: color, width: 1.5),
      ),
      child: child,
    );
  }
}

/// Rank as a badge: the initial of the difficulty in its colour.
class _RankBadge extends StatelessWidget {
  final QuestDifficulty difficulty;

  const _RankBadge({required this.difficulty});

  @override
  Widget build(BuildContext context) {
    final color = _rankColors[difficulty]!;
    return _Badge(
      color: color,
      child: Text(
        difficulty.displayName[0],
        style: _type(15, color: color, weight: FontWeight.w800),
      ),
    );
  }
}

class _Rule extends StatelessWidget {
  const _Rule();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(vertical: 14),
      color: _hairline,
    );
  }
}

/// Neon pill: solid when the panel is waiting on it, tinted otherwise.
class _PillButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool solid;
  final VoidCallback onTap;

  const _PillButton({
    required this.icon,
    required this.label,
    required this.color,
    this.solid = true,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fg = solid ? Colors.black : color;
    return Material(
      color: solid ? color : color.withValues(alpha: 0.14),
      shape: const StadiumBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 15, color: fg),
              const SizedBox(width: 6),
              Text(
                label,
                style: _type(14, color: fg, weight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _Chip({required this.icon, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 5, 10, 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: _type(12, color: color, weight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

/// Secondary actions: a monoline icon in a flat circle.
class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final Color color;

  const _CircleIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.color = _textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: _panelRaised,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: 36,
            height: 36,
            child: Icon(icon, size: 17, color: color),
          ),
        ),
      ),
    );
  }
}

// ── An open quest ─────────────────────────────────────────────────────────────

/// Folded to its title, progress and terms; tap to open the tasks, reward and
/// actions.
class QuestNotice extends StatefulWidget {
  final Quest quest;
  final VoidCallback onEdit;
  final VoidCallback onComplete;
  final VoidCallback onDelete;
  final ValueChanged<String> onToggleObjective;

  const QuestNotice({
    super.key,
    required this.quest,
    required this.onEdit,
    required this.onComplete,
    required this.onDelete,
    required this.onToggleObjective,
  });

  @override
  State<QuestNotice> createState() => _QuestNoticeState();
}

class _QuestNoticeState extends State<QuestNotice> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final q = widget.quest;
    final rank = _rankColors[q.difficulty]!;
    // Fulfil stays quiet until every task is ticked.
    final ready = q.allObjectivesDone;
    final fulfil = _PillButton(
      icon: CupertinoIcons.checkmark,
      label: 'Fulfil',
      color: _mint,
      solid: ready,
      onTap: widget.onComplete,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: _Panel(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => setState(() => _open = !_open),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${q.difficulty.displayName.toUpperCase()} QUEST',
                              style: _label(rank),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              q.title,
                              style: _type(
                                20,
                                weight: FontWeight.w700,
                                spacing: -0.3,
                                height: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      _RankBadge(difficulty: q.difficulty),
                    ],
                  ),
                  if (q.objectives.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _ProgressBar(quest: q),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (!_open && ready) ...[
                        fulfil,
                        const SizedBox(width: 10),
                      ],
                      // The reward box takes over from its chip once open.
                      Expanded(
                        child: _Terms(quest: q, showReward: !_open),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        _open
                            ? CupertinoIcons.chevron_up
                            : CupertinoIcons.chevron_down,
                        size: 16,
                        color: _textMuted,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: _open
                  ? _details(q, fulfil)
                  : const SizedBox(width: double.infinity),
            ),
          ],
        ),
      ),
    );
  }

  Widget _details(Quest q, Widget fulfil) {
    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (q.description != null) ...[
            const SizedBox(height: 14),
            Text(
              q.description!,
              style: _type(14, color: _textSecondary, height: 1.4),
            ),
          ],
          const _Rule(),
          if (q.objectives.isNotEmpty) ...[
            _Objectives(quest: q, onToggle: widget.onToggleObjective),
            const SizedBox(height: 10),
          ],
          if (q.hasReward) _RewardLine(quest: q),
          if (q.objectives.isEmpty && q.daysLeft == null && !q.hasReward)
            Text(
              'No terms set. Tap the pencil to add steps, a deadline or a '
              'reward.',
              style: _type(13, color: _textMuted, height: 1.35),
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              fulfil,
              const Spacer(),
              _CircleIconButton(
                icon: CupertinoIcons.pencil,
                tooltip: 'Edit',
                onTap: widget.onEdit,
              ),
              const SizedBox(width: 8),
              _CircleIconButton(
                icon: CupertinoIcons.trash,
                tooltip: 'Tear down',
                onTap: widget.onDelete,
                color: _red,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Tasks done as a bar, coloured by pace; the tick marks how much of the time
/// to the deadline has gone.
class _ProgressBar extends StatelessWidget {
  final Quest quest;

  const _ProgressBar({required this.quest});

  @override
  Widget build(BuildContext context) {
    final done = quest.objectiveFraction!;
    final elapsed = quest.timeElapsedFraction;
    final color = switch (quest.pace) {
      QuestPace.behind => _amber,
      QuestPace.overdue => _red,
      _ => _mint,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 12,
          child: LayoutBuilder(
            builder: (context, c) {
              final w = c.maxWidth;
              return Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.centerLeft,
                children: [
                  Container(
                    height: 6,
                    decoration: BoxDecoration(
                      color: _hairline,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  Container(
                    width: w * done,
                    height: 6,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  if (elapsed != null)
                    Positioned(
                      left: (w * elapsed.clamp(0.0, 1.0) - 1).clamp(0.0, w - 2),
                      top: 0,
                      bottom: 0,
                      child: Container(
                        width: 2,
                        decoration: BoxDecoration(
                          color: _textPrimary,
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Text(
              '${quest.completedObjectives} of ${quest.objectives.length} tasks',
              style: _type(12, color: _textSecondary, weight: FontWeight.w600),
            ),
            const Spacer(),
            if (elapsed != null)
              Text(
                '${(elapsed * 100).round()}% of the time gone',
                style: _type(12, color: _textMuted),
              ),
          ],
        ),
      ],
    );
  }
}

/// Deadline, pace and prize as chips, so a folded quest still says where it
/// stands.
class _Terms extends StatelessWidget {
  final Quest quest;
  final bool showReward;

  const _Terms({required this.quest, required this.showReward});

  @override
  Widget build(BuildContext context) {
    final q = quest;
    final left = q.daysLeft;

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        if (left != null) _due(q.targetDate!, left),
        if (q.pace == QuestPace.onTrack)
          const _Chip(
            icon: CupertinoIcons.arrow_up_right,
            text: 'On pace',
            color: _mint,
          ),
        if (q.pace == QuestPace.behind)
          const _Chip(
            icon: CupertinoIcons.arrow_down_right,
            text: 'Behind pace',
            color: _amber,
          ),
        if (q.hasReward && showReward)
          _Chip(
            icon: CupertinoIcons.gift,
            text: q.rewardText!,
            color: _textSecondary,
          ),
      ],
    );
  }

  Widget _due(DateTime target, int left) {
    final date = _fmtShortDate(target);
    final (text, color) = switch (left) {
      < 0 => ('$date · ${_fmtDays(-left)} overdue', _red),
      0 => ('Due today', _red),
      <= 14 => ('$date · ${_fmtDays(left)} left', _amber),
      _ => ('$date · ${_fmtDays(left)} left', _textSecondary),
    };
    return _Chip(icon: CupertinoIcons.calendar, text: text, color: color);
  }
}

class _Objectives extends StatelessWidget {
  final Quest quest;
  final ValueChanged<String> onToggle;

  const _Objectives({required this.quest, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('TASKS', style: _label(_textMuted)),
        const SizedBox(height: 8),
        for (final o in quest.objectives)
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => onToggle(o.id),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 1),
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: o.completed ? _mint : null,
                      border: o.completed
                          ? null
                          : Border.all(color: _textMuted, width: 1.5),
                    ),
                    child: o.completed
                        ? const Icon(
                            CupertinoIcons.checkmark,
                            size: 12,
                            color: Colors.black,
                          )
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      o.text,
                      style: _type(
                        15,
                        color: o.completed ? _textMuted : _textPrimary,
                        height: 1.3,
                        decoration: o.completed
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// The prize: locked while the quest is open, claimable once it is fulfilled,
/// crossed out once collected.
class _RewardLine extends StatelessWidget {
  final Quest quest;
  final VoidCallback? onClaim;

  const _RewardLine({required this.quest, this.onClaim});

  @override
  Widget build(BuildContext context) {
    final claimable = quest.isRewardClaimable;
    final claimed = quest.isRewardClaimed;
    final cost = quest.rewardCostCents;

    final (icon, note) = claimed
        ? (CupertinoIcons.checkmark_circle, 'Claimed')
        : claimable
            ? (CupertinoIcons.gift, 'Ready to claim')
            : (CupertinoIcons.lock, 'Locked until fulfilled');

    return Container(
      margin: const EdgeInsets.only(top: 2, bottom: 4),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: _panelRaised,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: claimable ? _mint : _textSecondary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('REWARD', style: _label(_textMuted, size: 9.5)),
                const SizedBox(height: 3),
                Text(
                  quest.rewardText!,
                  style: _type(
                    15,
                    weight: FontWeight.w700,
                    color: claimed ? _textMuted : _textPrimary,
                    decoration: claimed ? TextDecoration.lineThrough : null,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  note,
                  style: _type(12, color: claimable ? _mint : _textSecondary),
                ),
              ],
            ),
          ),
          if (cost != null && !claimed)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Text(
                '€${(cost / 100).round()}',
                style: _type(17, weight: FontWeight.w700),
              ),
            ),
          if (claimable && onClaim != null) ...[
            const SizedBox(width: 10),
            _PillButton(
              icon: CupertinoIcons.gift,
              label: 'Claim',
              color: _mint,
              onTap: onClaim!,
            ),
          ],
        ],
      ),
    );
  }
}

// ── Posting a new one ─────────────────────────────────────────────────────────

class PostQuestSlip extends StatelessWidget {
  final VoidCallback onTap;

  const PostQuestSlip({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    const shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(20)),
      side: BorderSide(color: _hairline),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        shape: shape,
        child: InkWell(
          onTap: onTap,
          customBorder: shape,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 18),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _mint.withValues(alpha: 0.14),
                  ),
                  child: const Icon(
                    CupertinoIcons.plus,
                    size: 16,
                    color: _mint,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Post a new quest',
                  style: _type(
                    15,
                    color: _textSecondary,
                    weight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Shown on the board when nothing is pinned to it.
class EmptyBoardNote extends StatelessWidget {
  const EmptyBoardNote({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 24),
      child: Text(
        'Nothing is posted. The board is waiting.',
        textAlign: TextAlign.center,
        style: _type(14, color: _textMuted),
      ),
    );
  }
}

// ── Fulfilled ─────────────────────────────────────────────────────────────────

/// Finished quests, kept below the open ones and folded away by default.
class FulfilledShelf extends StatefulWidget {
  final List<Quest> quests;
  final ValueChanged<Quest> onReopen;
  final ValueChanged<Quest> onDelete;
  final ValueChanged<Quest> onClaimReward;

  const FulfilledShelf({
    super.key,
    required this.quests,
    required this.onReopen,
    required this.onDelete,
    required this.onClaimReward,
  });

  @override
  State<FulfilledShelf> createState() => _FulfilledShelfState();
}

class _FulfilledShelfState extends State<FulfilledShelf> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    // A prize waiting to be collected should not hide behind the fold.
    final waiting = widget.quests.where((q) => q.isRewardClaimable).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => setState(() => _open = !_open),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(4, 22, 4, 14),
            child: Row(
              children: [
                Text('FULFILLED', style: _label(_textSecondary, size: 11)),
                const SizedBox(width: 8),
                Text(
                  '${widget.quests.length}',
                  style: _label(_textMuted, size: 11),
                ),
                if (waiting > 0) ...[
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: _mint.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '$waiting TO CLAIM',
                      style: _label(_mint, size: 9.5),
                    ),
                  ),
                ],
                const Spacer(),
                Icon(
                  _open
                      ? CupertinoIcons.chevron_up
                      : CupertinoIcons.chevron_down,
                  size: 16,
                  color: _textSecondary,
                ),
              ],
            ),
          ),
        ),
        if (_open)
          for (final q in widget.quests)
            _FulfilledNotice(
              quest: q,
              onReopen: () => widget.onReopen(q),
              onDelete: () => widget.onDelete(q),
              onClaimReward: () => widget.onClaimReward(q),
            ),
      ],
    );
  }
}

class _FulfilledNotice extends StatelessWidget {
  final Quest quest;
  final VoidCallback onReopen;
  final VoidCallback onDelete;
  final VoidCallback onClaimReward;

  const _FulfilledNotice({
    required this.quest,
    required this.onReopen,
    required this.onDelete,
    required this.onClaimReward,
  });

  @override
  Widget build(BuildContext context) {
    final q = quest;
    final rank = _rankColors[q.difficulty]!;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: _Panel(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${q.difficulty.displayName.toUpperCase()} QUEST',
                        style: _label(rank.withValues(alpha: 0.75), size: 10),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        q.title,
                        style: _type(
                          17,
                          weight: FontWeight.w700,
                          color: _textSecondary,
                          spacing: -0.2,
                          height: 1.2,
                        ),
                      ),
                      if (q.completedAt != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Fulfilled ${_fmtDate(q.completedAt!.toLocal())}',
                          style: _type(12.5, color: _textMuted),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Semantics(
                  label: 'Fulfilled',
                  child: const _Badge(
                    color: _mint,
                    child: Icon(
                      CupertinoIcons.checkmark,
                      size: 16,
                      color: _mint,
                    ),
                  ),
                ),
              ],
            ),
            if (q.hasReward)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: _RewardLine(quest: q, onClaim: onClaimReward),
              ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _CircleIconButton(
                  icon: CupertinoIcons.arrow_counterclockwise,
                  tooltip: 'Reopen',
                  onTap: onReopen,
                ),
                const SizedBox(width: 8),
                _CircleIconButton(
                  icon: CupertinoIcons.trash,
                  tooltip: 'Tear down',
                  onTap: onDelete,
                  color: _red,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
