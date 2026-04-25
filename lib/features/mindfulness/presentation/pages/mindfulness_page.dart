import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/theme/rpg_colors.dart';
import '../../application/use_cases/add_mindfulness_session_use_case.dart';
import '../../application/use_cases/delete_mindfulness_session_use_case.dart';
import '../../application/use_cases/get_mindfulness_stats_use_case.dart';
import '../../application/use_cases/get_today_mindfulness_sessions_use_case.dart';
import '../../application/use_cases/update_mindfulness_session_use_case.dart';
import '../../data/datasources/mindfulness_supabase_datasource.dart';
import '../../data/repositories/mindfulness_repository_impl.dart';
import '../controllers/mindfulness_controller.dart';
import '../state/mindfulness_state.dart';
import '../widgets/mindfulness_addiction_section.dart';
import '../widgets/mindfulness_category_section.dart';
import '../widgets/mindfulness_lifetime_section.dart';
import '../widgets/mindfulness_today_section.dart';

const _colorTeal = Color(0xFF26A69A);

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
      backgroundColor: RpgColors.pageBg,
      appBar: AppBar(
        backgroundColor: RpgColors.pageBg,
        foregroundColor: RpgColors.textSecondary,
        scrolledUnderElevation: 0,
        elevation: 0,
        title: const Text(
          'MINDFULNESS',
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
              if (_controller.state.isLoadingStats ||
                  _controller.state.isLoadingSessions) {
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

  Widget _buildBody(BuildContext context, MindfulnessState state) {
    if (state.statsStatus == MindfulnessLoadStatus.initial ||
        state.sessionsStatus == MindfulnessLoadStatus.initial) {
      return const Center(
        child: CircularProgressIndicator(
          color: _colorTeal,
          strokeWidth: 1.5,
        ),
      );
    }

    if (state.statsStatus == MindfulnessLoadStatus.error &&
        state.stats == null) {
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
                  foregroundColor: _colorTeal,
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
      color: _colorTeal,
      backgroundColor: RpgColors.panelBg,
      onRefresh: _controller.load,
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.only(top: 8, bottom: 32),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                if (state.stats != null) ...[
                  MindfulnessLifetimeSection(stats: state.stats!),
                  const SizedBox(height: 14),
                ],
                MindfulnessTodaySection(
                  sessions: state.todaySessions,
                  onAdd: _controller.addSession,
                  onUpdate: _controller.updateSession,
                  onDelete: _controller.deleteSession,
                ),
                if (state.stats != null) ...[
                  const SizedBox(height: 14),
                  MindfulnessCategorySection(stats: state.stats!),
                  const SizedBox(height: 14),
                  MindfulnessAddictionSection(
                    stats: state.stats!,
                    onLog: _controller.logAddictionDay,
                    onLogForDate: _controller.logAddictionForDate,
                  ),
                  const SizedBox(height: 14),
                ],
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
