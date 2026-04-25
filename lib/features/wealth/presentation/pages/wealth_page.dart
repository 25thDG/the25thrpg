import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/theme/rpg_colors.dart';
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
import '../widgets/wealth_million_section.dart';
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
      backgroundColor: RpgColors.pageBg,
      appBar: AppBar(
        backgroundColor: RpgColors.pageBg,
        foregroundColor: RpgColors.textSecondary,
        scrolledUnderElevation: 0,
        elevation: 0,
        title: const Text(
          'WEALTH',
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

  Widget _buildBody(WealthState state) {
    if (state.status == WealthLoadStatus.initial) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF10B981),
          strokeWidth: 1.5,
        ),
      );
    }

    if (state.status == WealthLoadStatus.error && state.stats == null) {
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
                  foregroundColor: const Color(0xFF10B981),
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
      color: const Color(0xFF10B981),
      backgroundColor: RpgColors.panelBg,
      onRefresh: _controller.load,
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.only(top: 8, bottom: 40),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                if (state.stats != null &&
                    state.stats!.currentMonthSnapshot == null)
                  _MissingSnapshotBanner(),
                if (state.stats != null) ...[
                  WealthCurrentSection(stats: state.stats!),
                  const SizedBox(height: 12),
                  WealthRadarSection(stats: state.stats!),
                  const SizedBox(height: 12),
                  WealthHistoryChart(history: state.stats!.monthlyHistory),
                  const SizedBox(height: 12),
                  WealthMillionSection(stats: state.stats!),
                  const SizedBox(height: 12),
                  WealthHighestSection(stats: state.stats!),
                  const SizedBox(height: 12),
                ],
                WealthMonthlyInputSection(
                  currentMonthSnapshot: state.stats?.currentMonthSnapshot,
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

class _MissingSnapshotBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF10B981).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
            color: const Color(0xFF10B981).withValues(alpha: 0.35)),
      ),
      child: const Row(
        children: [
          Icon(Icons.warning_amber_rounded,
              color: Color(0xFF10B981), size: 18),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'No net worth logged this month. Scroll down to add a snapshot.',
              style: TextStyle(
                color: Color(0xFF10B981),
                fontSize: 12,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
