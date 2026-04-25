import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/theme/rpg_colors.dart';
import '../../application/use_cases/add_category_use_case.dart';
import '../../application/use_cases/add_transaction_use_case.dart';
import '../../application/use_cases/delete_category_use_case.dart';
import '../../application/use_cases/delete_transaction_use_case.dart';
import '../../application/use_cases/get_budget_summary_use_case.dart';
import '../../application/use_cases/update_category_use_case.dart';
import '../../application/use_cases/update_transaction_use_case.dart';
import '../../data/datasources/budget_supabase_datasource.dart';
import '../../data/repositories/budget_repository_impl.dart';
import '../../domain/entities/budget_summary.dart';
import '../controllers/budget_controller.dart';
import '../state/budget_state.dart';
import '../widgets/add_transaction_sheet.dart';
import '../widgets/budget_burn_chart.dart';
import '../widgets/budget_category_chart.dart';
import '../widgets/budget_gauge.dart';
import '../widgets/budget_transaction_list.dart';
import '../widgets/manage_categories_sheet.dart';

class BudgetPage extends StatefulWidget {
  const BudgetPage({super.key});

  @override
  State<BudgetPage> createState() => _BudgetPageState();
}

class _BudgetPageState extends State<BudgetPage> {
  late final BudgetController _controller;

  @override
  void initState() {
    super.initState();
    final ds = BudgetSupabaseDatasource(Supabase.instance.client);
    final repo = BudgetRepositoryImpl(ds);
    _controller = BudgetController(
      getSummary: GetBudgetSummaryUseCase(repo),
      addTransaction: AddTransactionUseCase(repo),
      updateTransaction: UpdateTransactionUseCase(repo),
      deleteTransaction: DeleteTransactionUseCase(repo),
      addCategory: AddCategoryUseCase(repo),
      updateCategory: UpdateCategoryUseCase(repo),
      deleteCategory: DeleteCategoryUseCase(repo),
    );
    _controller.load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _showAddTransaction(BuildContext context, BudgetSummary summary) {
    if (summary.allCategories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Create a category first.'),
          backgroundColor: Color(0xFFFF7043),
        ),
      );
      return;
    }
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => AddTransactionSheet(
        categories: summary.allCategories,
        onSave: ({
          required categoryId,
          required amountCents,
          note,
          required spentAt,
        }) =>
            _controller.addTransaction(
          categoryId: categoryId,
          amountCents: amountCents,
          note: note,
          spentAt: spentAt,
        ),
      ),
    );
  }

  void _showCategories(BuildContext context, BudgetSummary summary) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => ManageCategoriesSheet(
        categories: summary.allCategories,
        onAdd: ({required name, required iconKey, required colorIndex}) =>
            _controller.addCategory(
                name: name, iconKey: iconKey, colorIndex: colorIndex),
        onUpdate: ({
          required id,
          required name,
          required iconKey,
          required colorIndex,
        }) =>
            _controller.updateCategory(
                id: id, name: name, iconKey: iconKey, colorIndex: colorIndex),
        onDelete: (id) => _controller.deleteCategory(id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RpgColors.pageBg,
      appBar: AppBar(
        backgroundColor: RpgColors.pageBg,
        foregroundColor: RpgColors.textSecondary,
        scrolledUnderElevation: 0,
        elevation: 0,
        title: const Text(
          'BUDGET',
          style: TextStyle(
            color: RpgColors.textMuted,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 2.8,
          ),
        ),
        centerTitle: false,
        actions: [
          ListenableBuilder(
            listenable: _controller,
            builder: (_, _) {
              final summary = _controller.state.summary;
              return Row(
                children: [
                  if (_controller.state.isLoading)
                    const Padding(
                      padding: EdgeInsets.only(right: 8),
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.5,
                          color: RpgColors.textMuted,
                        ),
                      ),
                    ),
                  if (summary != null)
                    IconButton(
                      icon: const Icon(Icons.category_outlined, size: 18),
                      color: RpgColors.textMuted,
                      tooltip: 'Manage categories',
                      onPressed: () => _showCategories(context, summary),
                    ),
                  IconButton(
                    icon: const Icon(Icons.refresh, size: 18),
                    color: RpgColors.textMuted,
                    onPressed: _controller.load,
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) => _buildBody(context, _controller.state),
      ),
      floatingActionButton: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          final summary = _controller.state.summary;
          if (summary == null) return const SizedBox.shrink();
          return FloatingActionButton(
            onPressed: () => _showAddTransaction(context, summary),
            backgroundColor: const Color(0xFF4FC3F7),
            foregroundColor: Colors.black,
            elevation: 4,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            child: const Icon(Icons.add, size: 28),
          );
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, BudgetState state) {
    if (state.status == BudgetLoadStatus.initial ||
        (state.status == BudgetLoadStatus.loading && state.summary == null)) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF4FC3F7),
          strokeWidth: 1.5,
        ),
      );
    }

    if (state.status == BudgetLoadStatus.error && state.summary == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'LOAD FAILED',
                style: TextStyle(
                  color: RpgColors.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 2.0,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                state.errorMessage ?? 'Unknown error.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: RpgColors.textSecondary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 24),
              OutlinedButton(
                onPressed: _controller.load,
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF4FC3F7),
                  side: const BorderSide(color: RpgColors.border),
                ),
                child: const Text('RETRY'),
              ),
            ],
          ),
        ),
      );
    }

    final summary = state.summary!;

    return RefreshIndicator(
      onRefresh: _controller.load,
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.only(top: 8, bottom: 80),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ── Month navigator ─────────────────────────────────────
                _MonthNavigator(
                  month: state.selectedMonth,
                  canGoNext: _controller.canGoNext,
                  onPrevious: _controller.previousMonth,
                  onNext: _controller.nextMonth,
                ),
                const SizedBox(height: 16),

                // ── Empty state: no categories ──────────────────────────
                if (summary.allCategories.isEmpty)
                  _EmptyCategories(
                    onCreateCategory: () =>
                        _showCategories(context, summary),
                  )
                else ...[
                  // ── Gauge ───────────────────────────────────────────
                  _GaugePanel(
                      summary: summary, month: state.selectedMonth),
                  const SizedBox(height: 12),

                  // ── Burn rate chart ─────────────────────────────────
                  if (summary.hasTransactions) ...[
                    BudgetBurnChart(
                        summary: summary, month: state.selectedMonth),
                    const SizedBox(height: 12),
                  ],

                  // ── Category chart ──────────────────────────────────
                  if (summary.hasTransactions) ...[
                    BudgetCategoryChart(summary: summary),
                    const SizedBox(height: 12),
                  ],

                  // ── Transaction list ────────────────────────────────
                  BudgetTransactionList(
                    summary: summary,
                    onUpdate: ({
                      required id,
                      required categoryId,
                      required amountCents,
                      note,
                      required spentAt,
                    }) =>
                        _controller.updateTransaction(
                      id: id,
                      categoryId: categoryId,
                      amountCents: amountCents,
                      note: note,
                      spentAt: spentAt,
                    ),
                    onDelete: _controller.deleteTransaction,
                  ),
                ],
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Month navigator ───────────────────────────────────────────────────────────

class _MonthNavigator extends StatelessWidget {
  final DateTime month;
  final bool canGoNext;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  const _MonthNavigator({
    required this.month,
    required this.canGoNext,
    required this.onPrevious,
    required this.onNext,
  });

  static const _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left, color: RpgColors.textSecondary),
            onPressed: onPrevious,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          Expanded(
            child: Center(
              child: Text(
                '${_months[month.month - 1]} ${month.year}',
                style: const TextStyle(
                  color: RpgColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.chevron_right,
                color: canGoNext
                    ? RpgColors.textSecondary
                    : RpgColors.textMuted),
            onPressed: canGoNext ? onNext : null,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}

// ── Gauge panel ───────────────────────────────────────────────────────────────

Color _statusColor(BudgetSummary s) {
  if (s.isOverBudget) return const Color(0xFFEF5350);
  if (s.isWarning) return const Color(0xFFFF7043);
  return const Color(0xFF26A69A);
}

class _GaugePanel extends StatelessWidget {
  final BudgetSummary summary;
  final DateTime month;

  const _GaugePanel({required this.summary, required this.month});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final color = _statusColor(summary);
    final isCurrentMonth =
        month.year == now.year && month.month == now.month;

    // Daily allowance
    final endOfMonth = DateTime(now.year, now.month + 1, 1);
    final daysLeft = isCurrentMonth
        ? endOfMonth.difference(DateTime(now.year, now.month, now.day)).inDays
        : 0;
    final dailyAllowance =
        isCurrentMonth && daysLeft > 0 && !summary.isOverBudget
            ? summary.remainingEur / daysLeft
            : null;

    // Month delta
    final delta = summary.deltaVsLastMonthEur;
    final deltaStr = delta == null
        ? null
        : delta >= 0
            ? '+€${delta.toStringAsFixed(0)}'
            : '-€${delta.abs().toStringAsFixed(0)}';
    final deltaColor = delta == null
        ? RpgColors.textMuted
        : delta <= 0
            ? const Color(0xFF26A69A)
            : const Color(0xFFEF5350);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: RpgColors.border),
        gradient: RadialGradient(
          center: const Alignment(1.0, -1.0),
          radius: 1.4,
          colors: [
            Color.lerp(color, const Color(0xFF101015), 0.78)!,
            const Color(0xFF101015),
            RpgColors.panelBg,
          ],
          stops: const [0.0, 0.55, 1.0],
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
            child: Row(
              children: [
                Container(width: 6, height: 6, color: color),
                const SizedBox(width: 8),
                const Text(
                  'MONTHLY BUDGET',
                  style: TextStyle(
                    color: RpgColors.textSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2.4,
                  ),
                ),
                const Spacer(),
                if (deltaStr != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: deltaColor.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: deltaColor.withValues(alpha: 0.35)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          delta! <= 0
                              ? Icons.arrow_downward
                              : Icons.arrow_upward,
                          size: 10,
                          color: deltaColor,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '$deltaStr vs last',
                          style: TextStyle(
                            color: deltaColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
            child: BudgetGauge(summary: summary),
          ),

          // Stats row
          if (isCurrentMonth) ...[
            Container(height: 0.5, color: RpgColors.divider),
            IntrinsicHeight(
              child: Row(
                children: [
                  // Daily allowance
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'DAILY ALLOWANCE',
                            style: TextStyle(
                              color: RpgColors.textMuted,
                              fontSize: 8,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.6,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            dailyAllowance != null
                                ? '€${dailyAllowance.toStringAsFixed(2)}'
                                : summary.isOverBudget
                                    ? 'OVER BUDGET'
                                    : '—',
                            style: TextStyle(
                              color: dailyAllowance != null
                                  ? color
                                  : const Color(0xFFEF5350),
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                              height: 1.0,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$daysLeft day${daysLeft == 1 ? '' : 's'} remaining',
                            style: const TextStyle(
                              color: RpgColors.textMuted,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Divider
                  VerticalDivider(
                      width: 1, color: RpgColors.divider, thickness: 0.5),
                  // Remaining budget
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'REMAINING',
                            style: TextStyle(
                              color: RpgColors.textMuted,
                              fontSize: 8,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.6,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            summary.isOverBudget
                                ? '-€${(summary.totalSpentCents - kMonthlyBudgetCents) ~/ 100}'
                                : '€${summary.remainingEur.toStringAsFixed(2)}',
                            style: TextStyle(
                              color: color,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                              height: 1.0,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            summary.isOverBudget
                                ? 'over the €300 limit'
                                : 'of €300 budget',
                            style: const TextStyle(
                              color: RpgColors.textMuted,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Empty categories state ────────────────────────────────────────────────────

class _EmptyCategories extends StatelessWidget {
  final VoidCallback onCreateCategory;

  const _EmptyCategories({required this.onCreateCategory});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      decoration: BoxDecoration(
        color: RpgColors.panelBg,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: RpgColors.border),
      ),
      child: Column(
        children: [
          const Icon(Icons.category_outlined,
              size: 48, color: RpgColors.textMuted),
          const SizedBox(height: 16),
          const Text(
            'No categories yet',
            style: TextStyle(
              color: RpgColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Create spending categories to start\ntracking your €300 monthly budget.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: RpgColors.textMuted,
              fontSize: 12,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: onCreateCategory,
            icon: const Icon(Icons.add, size: 18),
            label: const Text(
              'CREATE CATEGORY',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 11,
                letterSpacing: 1.2,
              ),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF4FC3F7),
              foregroundColor: Colors.black,
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6)),
            ),
          ),
        ],
      ),
    );
  }
}
