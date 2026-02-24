import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../application/use_cases/add_japanese_session_use_case.dart';
import '../../application/use_cases/delete_japanese_session_use_case.dart';
import '../../application/use_cases/get_japanese_stats_use_case.dart';
import '../../application/use_cases/get_today_japanese_sessions_use_case.dart';
import '../../application/use_cases/update_japanese_session_use_case.dart';
import '../../data/datasources/japanese_supabase_datasource.dart';
import '../../data/repositories/japanese_repository_impl.dart';
import '../controllers/japanese_controller.dart';
import '../state/japanese_state.dart';
import '../widgets/category_breakdown_section.dart';
import '../widgets/lifetime_stats_section.dart';
import '../widgets/rolling_window_section.dart';
import '../widgets/today_sessions_section.dart';

class JapanesePage extends StatefulWidget {
  const JapanesePage({super.key});

  @override
  State<JapanesePage> createState() => _JapanesePageState();
}

class _JapanesePageState extends State<JapanesePage> {
  late final JapaneseController _controller;

  @override
  void initState() {
    super.initState();
    final datasource =
        JapaneseSupabaseDatasource(Supabase.instance.client);
    final repository = JapaneseRepositoryImpl(datasource);

    _controller = JapaneseController(
      getStats: GetJapaneseStatsUseCase(repository),
      getTodaySessions: GetTodayJapaneseSessionsUseCase(repository),
      addSession: AddJapaneseSessionUseCase(repository),
      updateSession: UpdateJapaneseSessionUseCase(repository),
      deleteSession: DeleteJapaneseSessionUseCase(repository),
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
        title: const Text('JAPANESE'),
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

  Widget _buildBody(BuildContext context, JapaneseState state) {
    // Initial load placeholder
    if (state.statsStatus == LoadStatus.initial ||
        state.sessionsStatus == LoadStatus.initial) {
      return const Center(child: CircularProgressIndicator());
    }

    // Full-page error only on first load failure
    if (state.statsStatus == LoadStatus.error && state.stats == null) {
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
                  LifetimeStatsSection(stats: state.stats!),
                  RollingWindowSection(stats: state.stats!),
                  CategoryBreakdownSection(stats: state.stats!),
                ],
                TodaySessionsSection(
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
