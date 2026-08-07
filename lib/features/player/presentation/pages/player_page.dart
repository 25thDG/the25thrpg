import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/notifications/reminder_service.dart';
import '../../../../core/notifications/reminder_settings_sheet.dart';
import '../../application/use_cases/get_player_stats_use_case.dart';
import '../../data/datasources/player_supabase_datasource.dart';
import '../../data/repositories/player_repository_impl.dart';
import '../controllers/player_controller.dart';
import '../state/player_state.dart';
import '../widgets/player_hero.dart';
import '../widgets/player_insights_panel.dart';
import '../widgets/rpg_colors.dart';
import '../widgets/skills_window.dart';
import '../widgets/today_checkin_strip.dart';

class PlayerPage extends StatefulWidget {
  const PlayerPage({super.key});

  @override
  State<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage> {
  late final PlayerController _controller;

  @override
  void initState() {
    super.initState();
    final datasource =
        PlayerSupabaseDatasource(Supabase.instance.client);
    final repository = PlayerRepositoryImpl(datasource);

    _controller = PlayerController(
      getPlayerStats: GetPlayerStatsUseCase(repository),
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
          'CHARACTER',
          style: TextStyle(
            color: RpgColors.textMuted,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 2.8,
          ),
        ),
        centerTitle: false,
        actions: [
          // Bell fills in when a daily reminder is armed.
          ListenableBuilder(
            listenable: ReminderService.instance,
            builder: (context, _) {
              final on = ReminderService.instance.isEnabled;
              return IconButton(
                icon: Icon(
                  on ? Icons.notifications_active : Icons.notifications_none,
                  size: 18,
                ),
                color: on ? const Color(0xFFF59E0B) : RpgColors.textMuted,
                onPressed: () => ReminderSettingsSheet.show(context),
                tooltip: 'Daily reminder',
              );
            },
          ),
          ListenableBuilder(
            listenable: _controller,
            builder: (_, _) {
              if (_controller.state.isLoading) {
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

  Widget _buildBody(PlayerState state) {
    if (state.status == PlayerLoadStatus.initial ||
        state.status == PlayerLoadStatus.loading && state.stats == null) {
      return const Center(
        child: CircularProgressIndicator(
          color: RpgColors.accent,
          strokeWidth: 1.5,
        ),
      );
    }

    if (state.status == PlayerLoadStatus.error && state.stats == null) {
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
                  foregroundColor: RpgColors.accent,
                  side: const BorderSide(color: RpgColors.border),
                ),
                child: const Text('RETRY'),
              ),
            ],
          ),
        ),
      );
    }

    final stats = state.stats!;

    return RefreshIndicator(
      color: RpgColors.accent,
      backgroundColor: RpgColors.panelBg,
      onRefresh: _controller.load,
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.only(top: 8, bottom: 40),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // The character, and nothing competing with it.
                PlayerHero(stats: stats),
                PlayerStatLine(stats: stats),
                // Everything below supports the figure above.
                PlayerInsightsPanel(stats: stats),
                SkillsWindow(skills: stats.skills),
                // Quick-access dock lives last.
                const TodayCheckInStrip(),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
