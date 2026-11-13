import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/theme/rpg_colors.dart';
import '../../application/use_cases/delete_car_snapshot_use_case.dart';
import '../../application/use_cases/get_car_stats_use_case.dart';
import '../../application/use_cases/save_car_snapshot_use_case.dart';
import '../../data/datasources/car_supabase_datasource.dart';
import '../../data/repositories/car_repository_impl.dart';
import '../controllers/car_controller.dart';
import '../state/car_state.dart';
import '../widgets/car_budget_section.dart';
import '../widgets/car_history_section.dart';
import '../widgets/car_log_section.dart';
import '../widgets/car_pace_section.dart';
import '../widgets/car_term_section.dart';
import '../widgets/car_usage_section.dart';
import '../widgets/car_year_chart.dart';

class CarPage extends StatefulWidget {
  const CarPage({super.key});

  @override
  State<CarPage> createState() => _CarPageState();
}

class _CarPageState extends State<CarPage> {
  late final CarController _controller;

  @override
  void initState() {
    super.initState();
    final datasource = CarSupabaseDatasource(Supabase.instance.client);
    final repository = CarRepositoryImpl(datasource);

    _controller = CarController(
      getStats: GetCarStatsUseCase(repository),
      save: SaveCarSnapshotUseCase(repository),
      delete: DeleteCarSnapshotUseCase(repository),
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
      backgroundColor: RpgColors.pageBg,
      appBar: AppBar(
        backgroundColor: RpgColors.pageBg,
        foregroundColor: RpgColors.textSecondary,
        scrolledUnderElevation: 0,
        elevation: 0,
        title: const Text(
          'CAR',
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
              if (_controller.state.isBusy) {
                return const Padding(
                  padding: EdgeInsets.only(right: 16),
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      color: RpgColors.textMuted,
                    ),
                  ),
                );
              }
              return IconButton(
                icon: const Icon(Icons.refresh, size: 18),
                color: RpgColors.textMuted,
                onPressed: _controller.load,
                tooltip: 'Refresh',
              );
            },
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) => _buildBody(_controller.state),
      ),
    );
  }

  Widget _buildBody(CarState state) {
    final stats = state.stats;

    if (stats == null) {
      if (state.status != CarLoadStatus.error) {
        return const Center(
          child: CircularProgressIndicator(
            color: RpgColors.textSecondary,
            strokeWidth: 1.5,
          ),
        );
      }

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
                  foregroundColor: RpgColors.textPrimary,
                  side: const BorderSide(color: RpgColors.border),
                ),
                child: const Text('RETRY'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: RpgColors.textPrimary,
      backgroundColor: RpgColors.panelBg,
      onRefresh: _controller.load,
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.only(top: 8, bottom: 40),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                CarUsageSection(stats: stats),
                const SizedBox(height: 14),
                CarBudgetSection(stats: stats),
                const SizedBox(height: 14),
                CarLogSection(
                  stats: stats,
                  isBusy: state.isBusy,
                  onSave: _controller.saveSnapshot,
                ),
                const SizedBox(height: 14),
                CarPaceSection(stats: stats),
                const SizedBox(height: 14),
                CarYearChart(stats: stats),
                const SizedBox(height: 14),
                CarTermSection(stats: stats),
                const SizedBox(height: 14),
                CarHistorySection(
                  contract: stats.contract,
                  history: stats.history,
                  isBusy: state.isBusy,
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
