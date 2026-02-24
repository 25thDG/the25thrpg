import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../application/use_cases/add_social_session_use_case.dart';
import '../../application/use_cases/delete_social_session_use_case.dart';
import '../../application/use_cases/get_social_stats_use_case.dart';
import '../../application/use_cases/get_today_social_sessions_use_case.dart';
import '../../application/use_cases/update_social_session_use_case.dart';
import '../../data/datasources/social_supabase_datasource.dart';
import '../../data/repositories/social_repository_impl.dart';
import '../controllers/social_controller.dart';
import '../state/social_state.dart';
import '../widgets/social_add_session_sheet.dart';
import '../widgets/social_best_section.dart';
import '../widgets/social_last30_section.dart';
import '../widgets/social_lifetime_section.dart';
import '../widgets/social_today_section.dart';

class SocialPage extends StatefulWidget {
  const SocialPage({super.key});

  @override
  State<SocialPage> createState() => _SocialPageState();
}

class _SocialPageState extends State<SocialPage> {
  late final SocialController _controller;

  @override
  void initState() {
    super.initState();
    final datasource = SocialSupabaseDatasource(Supabase.instance.client);
    final repository = SocialRepositoryImpl(datasource);

    _controller = SocialController(
      getStats: GetSocialStatsUseCase(repository),
      getTodaySessions: GetTodaySocialSessionsUseCase(repository),
      addSession: AddSocialSessionUseCase(repository),
      updateSession: UpdateSocialSessionUseCase(repository),
      deleteSession: DeleteSocialSessionUseCase(repository),
    );

    _controller.load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _openAddSheet(BuildContext context, SocialState state) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SocialAddSessionSheet(
        isBusy: state.isBusy,
        onSave: _controller.addSession,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Social'),
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

  Widget _buildBody(BuildContext context, SocialState state) {
    if (state.statsStatus == SocialLoadStatus.initial) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.statsStatus == SocialLoadStatus.error && state.stats == null) {
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
                  // 1 + 2. Lifetime total + initiation breakdown
                  SocialLifetimeSection(stats: state.stats!),
                  // 3 + 4. Last 30 days + initiation breakdown
                  SocialLast30Section(stats: state.stats!),
                  // 5. Best 30-day period
                  SocialBestSection(stats: state.stats!),
                ],
                // 6. Today logging
                SocialTodaySection(
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
