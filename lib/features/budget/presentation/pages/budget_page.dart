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
      appBar: AppBar(
        title: const Text('BUDGET'),
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
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  if (summary != null)
                    IconButton(
                      icon: const Icon(Icons.category_outlined, size: 20),
                      tooltip: 'Manage categories',
                      onPressed: () => _showCategories(context, summary),
                    ),
                  IconButton(
                    icon: const Icon(Icons.refresh, size: 20),
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
      return const Center(child: CircularProgressIndicator());
    }

    if (state.status == BudgetLoadStatus.error && state.summary == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline,
                  size: 48, color: Theme.of(context).colorScheme.error),
              const SizedBox(height: 12),
              Text(state.errorMessage ?? 'Something went wrong.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: RpgColors.textSecondary)),
              const SizedBox(height: 16),
              FilledButton(
                  onPressed: _controller.load,
                  child: const Text('Retry')),
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
                  _GaugePanel(summary: summary),
                  const SizedBox(height: 12),

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

class _GaugePanel extends StatelessWidget {
  final BudgetSummary summary;

  const _GaugePanel({required this.summary});

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
        children: [
          // Header
          Container(
            width: double.infinity,
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: RpgColors.divider)),
            ),
            child: const Text(
              'MONTHLY BUDGET',
              style: TextStyle(
                color: RpgColors.textMuted,
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 2.4,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: BudgetGauge(summary: summary),
          ),
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
