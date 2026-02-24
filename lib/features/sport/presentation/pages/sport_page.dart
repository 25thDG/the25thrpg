import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../application/use_cases/add_sport_session_use_case.dart';
import '../../application/use_cases/delete_sport_session_use_case.dart';
import '../../application/use_cases/get_sport_stats_use_case.dart';
import '../../application/use_cases/get_today_sport_sessions_use_case.dart';
import '../../application/use_cases/update_sport_session_use_case.dart';
import '../../data/datasources/sport_supabase_datasource.dart';
import '../../data/repositories/sport_repository_impl.dart';
import '../controllers/sport_controller.dart';
import '../state/sport_state.dart';
import '../widgets/sport_add_session_sheet.dart';
import '../widgets/sport_best_section.dart';
import '../widgets/sport_category_section.dart';
import '../widgets/sport_last30_section.dart';
import '../widgets/sport_lifetime_section.dart';
import '../widgets/sport_today_section.dart';

class SportPage extends StatefulWidget {
  const SportPage({super.key});

  @override
  State<SportPage> createState() => _SportPageState();
}

class _SportPageState extends State<SportPage> {
  late final SportController _controller;

  @override
  void initState() {
    super.initState();
    final datasource = SportSupabaseDatasource(Supabase.instance.client);
    final repository = SportRepositoryImpl(datasource);

    _controller = SportController(
      getStats: GetSportStatsUseCase(repository),
      getTodaySessions: GetTodaySportSessionsUseCase(repository),
      addSession: AddSportSessionUseCase(repository),
      updateSession: UpdateSportSessionUseCase(repository),
      deleteSession: DeleteSportSessionUseCase(repository),
    );

    _controller.load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _openAddSheet(BuildContext context, SportState state) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SportAddSessionSheet(
        isBusy: state.isBusy,
        onSave: _controller.addSession,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sport'),
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

  Widget _buildBody(BuildContext context, SportState state) {
    if (state.statsStatus == SportLoadStatus.initial) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.statsStatus == SportLoadStatus.error && state.stats == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: Theme.of(context).colorScheme.error,
              ),
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
                  SportLifetimeSection(stats: state.stats!),
                  SportCategorySection(stats: state.stats!),
                  SportLast30Section(stats: state.stats!),
                  SportBestSection(stats: state.stats!),
                ],
                SportTodaySection(
                  sessions: state.todaySessions,
                  isBusy: state.isBusy,
                  onUpdate: _controller.updateSession,
                  onDelete: _controller.deleteSession,
                  onAdd: () => _openAddSheet(context, state),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
