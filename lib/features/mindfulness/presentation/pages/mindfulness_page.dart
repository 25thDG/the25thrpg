import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../application/use_cases/add_mindfulness_session_use_case.dart';
import '../../application/use_cases/delete_mindfulness_session_use_case.dart';
import '../../application/use_cases/get_mindfulness_stats_use_case.dart';
import '../../application/use_cases/get_today_mindfulness_sessions_use_case.dart';
import '../../application/use_cases/update_mindfulness_session_use_case.dart';
import '../../data/datasources/mindfulness_supabase_datasource.dart';
import '../../data/repositories/mindfulness_repository_impl.dart';
import '../controllers/mindfulness_controller.dart';
import '../state/mindfulness_state.dart';
import '../widgets/mindfulness_category_section.dart';
import '../widgets/mindfulness_lifetime_section.dart';
import '../widgets/mindfulness_rolling_section.dart';
import '../widgets/mindfulness_today_section.dart';

class MindfulnessPage extends StatefulWidget {
  const MindfulnessPage({super.key});

  @override
  State<MindfulnessPage> createState() => _MindfulnessPageState();
}

class _MindfulnessPageState extends State<MindfulnessPage> {
  late final MindfulnessController _controller;

  @override
  void initState() {
    super.initState();
    final datasource =
        MindfulnessSupabaseDatasource(Supabase.instance.client);
    final repository = MindfulnessRepositoryImpl(datasource);

    _controller = MindfulnessController(
      getStats: GetMindfulnessStatsUseCase(repository),
      getTodaySessions: GetTodayMindfulnessSessionsUseCase(repository),
      addSession: AddMindfulnessSessionUseCase(repository),
      updateSession: UpdateMindfulnessSessionUseCase(repository),
      deleteSession: DeleteMindfulnessSessionUseCase(repository),
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
        title: const Text('Mindfulness'),
        centerTitle: false,
        actions: [
          ListenableBuilder(
            listenable: _controller,
            builder: (_, _) {
              if (_controller.state.isLoadingStats ||
                  _controller.state.isLoadingSessions) {
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

  Widget _buildBody(BuildContext context, MindfulnessState state) {
    if (state.statsStatus == MindfulnessLoadStatus.initial ||
        state.sessionsStatus == MindfulnessLoadStatus.initial) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.statsStatus == MindfulnessLoadStatus.error &&
        state.stats == null) {
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
                  // 1. Lifetime
                  MindfulnessLifetimeSection(stats: state.stats!),
                  // 2. Category breakdown
                  MindfulnessCategorySection(stats: state.stats!),
                  // 3. Last 30 days + best 30-day period
                  MindfulnessRollingSection(stats: state.stats!),
                ],
                // 4. Today logging
                MindfulnessTodaySection(
                  sessions: state.todaySessions,
                  onAdd: _controller.addSession,
                  onUpdate: _controller.updateSession,
                  onDelete: _controller.deleteSession,
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
