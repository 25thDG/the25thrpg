import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../application/use_cases/add_or_update_monthly_snapshot_use_case.dart';
import '../../application/use_cases/delete_wealth_snapshot_use_case.dart';
import '../../application/use_cases/get_wealth_stats_use_case.dart';
import '../../data/datasources/wealth_supabase_datasource.dart';
import '../../data/repositories/wealth_repository_impl.dart';
import '../controllers/wealth_controller.dart';
import '../state/wealth_state.dart';
import '../widgets/wealth_current_section.dart';
import '../widgets/wealth_highest_section.dart';
import '../widgets/wealth_history_chart.dart';
import '../widgets/wealth_monthly_input_section.dart';
import '../widgets/wealth_radar_section.dart';

class WealthPage extends StatefulWidget {
  const WealthPage({super.key});

  @override
  State<WealthPage> createState() => _WealthPageState();
}

class _WealthPageState extends State<WealthPage> {
  late final WealthController _controller;

  @override
  void initState() {
    super.initState();
    final datasource = WealthSupabaseDatasource(Supabase.instance.client);
    final repository = WealthRepositoryImpl(datasource);

    _controller = WealthController(
      getStats: GetWealthStatsUseCase(repository),
      addOrUpdate: AddOrUpdateMonthlySnapshotUseCase(repository),
      delete: DeleteWealthSnapshotUseCase(repository),
    );

    _controller.load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wealth'),
        centerTitle: false,
        actions: [
          ListenableBuilder(
            listenable: _controller,
            builder: (_, _) {
              if (_controller.state.isBusy) {
                return const Padding(
                  padding: EdgeInsets.only(right: 16),
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                );
              }
              return IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _controller.load,
                tooltip: 'Refresh',
              );
            },
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) => _buildBody(context, _controller.state),
      ),
    );
  }

  Widget _buildBody(BuildContext context, WealthState state) {
    if (state.status == WealthLoadStatus.initial) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.status == WealthLoadStatus.error && state.stats == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline,
                  size: 48, color: Theme.of(context).colorScheme.error),
              const SizedBox(height: 12),
              Text(
                state.errorMessage ?? 'Something went wrong.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _controller.load,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _controller.load,
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.only(top: 8, bottom: 32),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                if (state.stats != null) ...[
                  // 1. Current net worth
                  WealthCurrentSection(stats: state.stats!),
                  // 2. Radar progress
                  WealthRadarSection(stats: state.stats!),
                  // 3. History chart
                  WealthHistoryChart(history: state.stats!.monthlyHistory),
                  // 4. All-time high
                  WealthHighestSection(stats: state.stats!),
                ],
                // 5. Monthly input
                WealthMonthlyInputSection(
                  currentMonthSnapshot:
                      state.stats?.currentMonthSnapshot,
                  isBusy: state.isBusy,
                  onSave: _controller.saveSnapshot,
                  onDelete: _controller.deleteSnapshot,
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
