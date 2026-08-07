import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/theme/rpg_colors.dart';
import '../../application/use_cases/add_sport_session_use_case.dart';
import '../../application/use_cases/delete_sport_session_use_case.dart';
import '../../application/use_cases/get_sport_stats_use_case.dart';
import '../../application/use_cases/get_today_sport_sessions_use_case.dart';
import '../../application/use_cases/update_sport_session_use_case.dart';
import '../../data/datasources/sport_supabase_datasource.dart';
import '../../data/repositories/sport_repository_impl.dart';
import '../controllers/sport_controller.dart';
import '../state/sport_state.dart';
import '../widgets/sport_category_section.dart';
import '../widgets/sport_lifetime_section.dart';
import '../widgets/sport_today_section.dart';

const _colorSport = Color(0xFFFF7043);

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
          'SPORT',
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
        builder: (context, _) => _buildBody(context, _controller.state),
      ),
    );
  }

  Widget _buildBody(BuildContext context, SportState state) {
    if (state.statsStatus == SportLoadStatus.initial ||
        state.statsStatus == SportLoadStatus.loading && state.stats == null) {
      return const Center(
        child: CircularProgressIndicator(
          color: _colorSport,
          strokeWidth: 1.5,
        ),
      );
    }

    if (state.statsStatus == SportLoadStatus.error && state.stats == null) {
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
                  foregroundColor: _colorSport,
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
      color: _colorSport,
      backgroundColor: RpgColors.panelBg,
      onRefresh: _controller.load,
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.only(top: 8, bottom: 32),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                if (state.stats != null) ...[
                  SportLifetimeSection(stats: state.stats!),
                  const SizedBox(height: 14),
                  SportCategorySection(stats: state.stats!),
                  const SizedBox(height: 14),
                ],
                SportTodaySection(
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
