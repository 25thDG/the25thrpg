import 'package:flutter/material.dart';

import '../../../../core/theme/rpg_colors.dart';
import '../../domain/entities/car_contract.dart';
import '../../domain/entities/car_snapshot.dart';
import '../../domain/entities/car_stats.dart';
import 'car_formatters.dart';
import 'car_panel.dart';

const _delete = Color(0xFFEF5350);

/// Rows shown before "Show all" is tapped.
const _collapsedRows = 10;

/// Every snapshot, newest first, with the distance since the one before.
/// Deleting from here is the only way to fix a typo on an earlier day.
class CarHistorySection extends StatefulWidget {
  final CarContract contract;
  final List<CarHistoryEntry> history;
  final bool isBusy;
  final Future<String?> Function(String id) onDelete;

  const CarHistorySection({
    super.key,
    required this.contract,
    required this.history,
    required this.isBusy,
    required this.onDelete,
  });

  @override
  State<CarHistorySection> createState() => _CarHistorySectionState();
}

class _CarHistorySectionState extends State<CarHistorySection> {
  bool _showAll = false;

  Future<void> _confirmDelete(CarSnapshot snapshot) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: RpgColors.panelBg,
        title: const Text('Remove this snapshot?',
            style: TextStyle(color: RpgColors.textPrimary)),
        content: Text(
          '${fmtDay(snapshot.snapshotDate)} · ${fmtKm(snapshot.odometerKm)} km',
          style: const TextStyle(color: RpgColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel',
                style: TextStyle(color: RpgColors.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove', style: TextStyle(color: _delete)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final error = await widget.onDelete(snapshot.id);
    if (error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: _delete),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final history = widget.history;
    final collapsible = history.length > _collapsedRows;
    final visible = _showAll || !collapsible
        ? history
        : history.take(_collapsedRows).toList();
    // The handover reading closes the list, so the oldest snapshot's
    // "since previous" has something to point at.
    final showHandover = visible.length == history.length;

    return CarPanel(
      title: 'SNAPSHOTS',
      trailing: '${history.length} LOGGED',
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 6, 8),
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.only(right: 42, bottom: 6),
              child: Row(
                children: [
                  Expanded(flex: 4, child: _HeaderText('DATE')),
                  Expanded(flex: 3, child: _HeaderText('ODOMETER')),
                  Expanded(
                    flex: 4,
                    child: _HeaderText('SINCE PREVIOUS', alignRight: true),
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(right: 10),
              child: Divider(height: 1, color: RpgColors.divider),
            ),
            for (final entry in visible)
              _SnapshotRow(
                entry: entry,
                onDelete:
                    widget.isBusy ? null : () => _confirmDelete(entry.snapshot),
              ),
            if (showHandover) _HandoverRow(contract: widget.contract),
            if (collapsible)
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => setState(() => _showAll = !_showAll),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 10, 10, 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _showAll
                            ? 'Show fewer'
                            : 'Show all ${history.length} snapshots',
                        style: const TextStyle(
                          color: RpgColors.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Icon(
                        _showAll ? Icons.expand_less : Icons.expand_more,
                        size: 16,
                        color: RpgColors.textSecondary,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _HeaderText extends StatelessWidget {
  final String text;
  final bool alignRight;

  const _HeaderText(this.text, {this.alignRight = false});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: alignRight ? TextAlign.right : TextAlign.left,
      style: const TextStyle(
        color: RpgColors.textMuted,
        fontSize: 9,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.5,
      ),
    );
  }
}

class _SnapshotRow extends StatelessWidget {
  final CarHistoryEntry entry;

  /// Null while a save or delete is in flight.
  final VoidCallback? onDelete;

  const _SnapshotRow({required this.entry, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final rate = entry.kmPerDay;
    final days = entry.daysSincePrevious;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Text(
              fmtDay(entry.snapshot.snapshotDate),
              style: const TextStyle(
                color: RpgColors.textSecondary,
                fontSize: 11,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              '${fmtKm(entry.snapshot.odometerKm)} km',
              style: const TextStyle(
                color: RpgColors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '+${fmtKm(entry.kmSincePrevious)} km',
                  style: const TextStyle(
                    color: RpgColors.textPrimary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  rate == null
                      ? 'same day'
                      : '${fmtRate(rate)} km/day · $days d',
                  style: const TextStyle(
                    color: RpgColors.textMuted,
                    fontSize: 9.5,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 42,
            child: IconButton(
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline, size: 16),
              color: RpgColors.textMuted,
              disabledColor: RpgColors.divider,
              tooltip: 'Remove snapshot',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints.tightFor(width: 36, height: 36),
              // Without this Material pads the button back out to 48 and
              // every row grows with it.
              style: IconButton.styleFrom(
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HandoverRow extends StatelessWidget {
  final CarContract contract;

  const _HandoverRow({required this.contract});

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(color: RpgColors.textMuted, fontSize: 11);

    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 10, right: 42),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Text(fmtDay(contract.startDate), style: style),
          ),
          Expanded(
            flex: 3,
            child: Text('${fmtKm(contract.startOdometerKm)} km', style: style),
          ),
          const Expanded(
            flex: 4,
            child: Text('Handover', textAlign: TextAlign.right, style: style),
          ),
        ],
      ),
    );
  }
}
