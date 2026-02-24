import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../application/use_cases/add_general_creation_session_use_case.dart';
import '../../application/use_cases/add_project_creation_session_use_case.dart';
import '../../application/use_cases/complete_project_use_case.dart';
import '../../application/use_cases/create_project_use_case.dart';
import '../../application/use_cases/delete_creation_session_use_case.dart';
import '../../application/use_cases/delete_project_use_case.dart';
import '../../application/use_cases/get_creation_stats_use_case.dart';
import '../../application/use_cases/get_today_creation_sessions_use_case.dart';
import '../../application/use_cases/update_creation_session_use_case.dart';
import '../../application/use_cases/update_project_use_case.dart';
import '../../data/datasources/creation_supabase_datasource.dart';
import '../../data/repositories/creation_repository_impl.dart';
import '../controllers/creation_controller.dart';
import '../state/creation_state.dart';
import '../widgets/creation_add_session_sheet.dart';
import '../widgets/creation_lifetime_section.dart';
import '../widgets/creation_projects_section.dart';
import '../widgets/creation_rolling_section.dart';
import '../widgets/creation_today_section.dart';

class CreationPage extends StatefulWidget {
  const CreationPage({super.key});

  @override
  State<CreationPage> createState() => _CreationPageState();
}

class _CreationPageState extends State<CreationPage> {
  late final CreationController _controller;

  @override
  void initState() {
    super.initState();
    final datasource = CreationSupabaseDatasource(Supabase.instance.client);
    final repository = CreationRepositoryImpl(datasource);

    _controller = CreationController(
      getStats: GetCreationStatsUseCase(repository),
      getTodaySessions: GetTodayCreationSessionsUseCase(repository),
      addGeneral: AddGeneralCreationSessionUseCase(repository),
      addProject: AddProjectCreationSessionUseCase(repository),
      updateSession: UpdateCreationSessionUseCase(repository),
      deleteSession: DeleteCreationSessionUseCase(repository),
      createProject: CreateProjectUseCase(repository),
      updateProject: UpdateProjectUseCase(repository),
      completeProject: CompleteProjectUseCase(repository),
      deleteProject: DeleteProjectUseCase(repository),
    );

    _controller.load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _openAddSheet(BuildContext context, CreationState state) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => CreationAddSessionSheet(
        activeProjects: state.stats?.activeProjects ?? [],
        isBusy: state.isBusy,
        onAddGeneral: _controller.addGeneralSession,
        onAddProject: _controller.addProjectSession,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Creation'),
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

  Widget _buildBody(BuildContext context, CreationState state) {
    if (state.statsStatus == CreationLoadStatus.initial) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.statsStatus == CreationLoadStatus.error && state.stats == null) {
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
                  // 1. Lifetime hours
                  CreationLifetimeSection(stats: state.stats!),
                  // 2. Rolling window
                  CreationRollingSection(stats: state.stats!),
                  // 3. Projects (active + collapsible completed)
                  CreationProjectsSection(
                    stats: state.stats!,
                    isBusy: state.isBusy,
                    onCreateProject: _controller.createProject,
                    onUpdateProject: _controller.updateProject,
                    onCompleteProject: _controller.completeProject,
                    onDeleteProject: _controller.deleteProject,
                  ),
                ],
                // 4. Today's sessions
                CreationTodaySection(
                  sessions: state.todaySessions,
                  isBusy: state.isBusy,
                  onUpdate: (id, minutes, type) =>
                      _controller.updateSession(id, minutes, type),
                  onDelete: (id, type) => _controller.deleteSession(id, type),
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
