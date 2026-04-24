import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/rpg_colors.dart';
import '../../domain/entities/budget_category.dart';
import '../../domain/entities/budget_summary.dart';

class BudgetCategoryChart extends StatefulWidget {
  final BudgetSummary summary;

  const BudgetCategoryChart({super.key, required this.summary});

  @override
  State<BudgetCategoryChart> createState() => _BudgetCategoryChartState();
}

class _BudgetCategoryChartState extends State<BudgetCategoryChart> {
  int _touched = -1;

  @override
  Widget build(BuildContext context) {
    final totals = widget.summary.categoryTotals;
    if (totals.isEmpty) return const SizedBox.shrink();

    final entries = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final grandTotal = entries.fold(0, (s, e) => s + e.value);

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
          _Header(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
            child: Row(
              children: [
                // Pie chart
                SizedBox(
                  width: 130,
                  height: 130,
                  child: PieChart(
                    PieChartData(
                      sections: List.generate(entries.length, (i) {
                        final cat = entries[i].key;
                        final cents = entries[i].value;
                        final isTouched = i == _touched;
                        return PieChartSectionData(
                          value: cents.toDouble(),
                          color: cat.color,
                          radius: isTouched ? 46 : 38,
                          title: isTouched
                              ? '${(cents / grandTotal * 100).round()}%'
                              : '',
                          titleStyle: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                          borderSide: BorderSide(
                            color: isTouched
                                ? cat.color.withValues(alpha: 0.6)
                                : Colors.transparent,
                            width: isTouched ? 2 : 0,
                          ),
                        );
                      }),
                      centerSpaceRadius: 28,
                      sectionsSpace: 2,
                      pieTouchData: PieTouchData(
                        touchCallback: (event, resp) {
                          setState(() {
                            if (!event.isInterestedForInteractions ||
                                resp?.touchedSection == null) {
                              _touched = -1;
                            } else {
                              _touched = resp!
                                  .touchedSection!.touchedSectionIndex;
                            }
                          });
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                // Legend
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: entries.map((e) {
                      return _LegendRow(
                        category: e.key,
                        cents: e.value,
                        grandTotal: grandTotal,
                      );
                    }).toList(),
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

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: RpgColors.divider)),
      ),
      child: const Text(
        'SPENDING BREAKDOWN',
        style: TextStyle(
          color: RpgColors.textMuted,
          fontSize: 10,
          fontWeight: FontWeight.w600,
          letterSpacing: 2.4,
        ),
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  final BudgetCategory category;
  final int cents;
  final int grandTotal;

  const _LegendRow({
    required this.category,
    required this.cents,
    required this.grandTotal,
  });

  @override
  Widget build(BuildContext context) {
    final pct = grandTotal > 0 ? cents / grandTotal * 100 : 0.0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: category.color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              category.name,
              style: const TextStyle(
                color: RpgColors.textSecondary,
                fontSize: 11,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '€${(cents / 100).toStringAsFixed(2)}',
            style: TextStyle(
              color: category.color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 4),
          SizedBox(
            width: 30,
            child: Text(
              '${pct.round()}%',
              style: const TextStyle(
                color: RpgColors.textMuted,
                fontSize: 9,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
