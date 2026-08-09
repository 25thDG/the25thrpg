import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/notifications/reminder_service.dart';
import '../../../../core/notifications/reminder_settings_sheet.dart';
import '../../application/use_cases/get_activity_history_use_case.dart';
import '../../application/use_cases/get_player_stats_use_case.dart';
import '../../data/datasources/player_supabase_datasource.dart';
import '../../data/repositories/player_repository_impl.dart';
import '../controllers/player_controller.dart';
import '../state/player_state.dart';
import '../widgets/level_up_overlay.dart';
import 'history_page.dart';
import 'radar_gallery_page.dart'; // TEMP-GALLERY
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

  /// Guards against a rebuild re-opening the celebration mid-animation.
  bool _celebrating = false;

  @override
  void initState() {
    super.initState();
    final datasource =
        PlayerSupabaseDatasource(Supabase.instance.client);
    final repository = PlayerRepositoryImpl(datasource);

    _controller = PlayerController(
      getPlayerStats: GetPlayerStatsUseCase(repository),
      getActivityHistory: GetActivityHistoryUseCase(repository),
    );

    _controller.addListener(_onStateChanged);
    _controller.load();
  }

  /// A level gain is announced the moment the new number arrives, not on the
  /// next frame the user happens to look at.
  void _onStateChanged() {
    final events = _controller.state.pendingLevelUps;
    if (events.isEmpty || _celebrating) return;

    _celebrating = true;
    _controller.clearLevelUps();

    ReminderService.instance.notifyLevelUp(
      title: levelUpNotificationTitle(events),
      body: levelUpNotificationBody(events),
      id: events.first.to,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await LevelUpOverlay.show(context, events);
      _celebrating = false;
    });
  }

  @override
  void dispose() {
    _controller.removeListener(_onStateChanged);
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
          // The long view — every day logged, on one screen.
          ListenableBuilder(
            listenable: _controller,
            builder: (context, _) {
              final history = _controller.state.history;
              return IconButton(
                icon: const Icon(Icons.calendar_month_outlined, size: 18),
                color: RpgColors.textMuted,
                onPressed: history == null
                    ? null
                    : () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => HistoryPage(history: history),
                          ),
                        ),
                tooltip: 'History',
              );
            },
          ),
          // TEMP-GALLERY — radar style picker, remove once one is chosen.
          ListenableBuilder(
            listenable: _controller,
            builder: (context, _) {
              final stats = _controller.state.stats;
              return IconButton(
                icon: const Icon(Icons.auto_awesome_mosaic_outlined, size: 18),
                color: RpgColors.textMuted,
                onPressed: stats == null
                    ? null
                    : () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) =>
                                RadarGalleryPage(skills: stats.skills),
                          ),
                        ),
                tooltip: 'Radar styles',
              );
            },
          ),
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
                PlayerInsightsPanel(
                  stats: stats,
                  weeklyReview: state.weeklyReview,
                ),
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
