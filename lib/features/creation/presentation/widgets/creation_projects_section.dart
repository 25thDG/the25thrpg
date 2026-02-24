import 'package:flutter/material.dart';

import '../../domain/entities/creation_project.dart';
import '../../domain/entities/creation_stats.dart';
import 'section_card.dart';

class CreationProjectsSection extends StatefulWidget {
  final CreationStats stats;
  final bool isBusy;
  final Future<String?> Function(String name) onCreateProject;
  final Future<String?> Function(String id, String name) onUpdateProject;
  final Future<String?> Function(String id) onCompleteProject;
  final Future<String?> Function(String id) onDeleteProject;

  const CreationProjectsSection({
    super.key,
    required this.stats,
    required this.isBusy,
    required this.onCreateProject,
    required this.onUpdateProject,
    required this.onCompleteProject,
    required this.onDeleteProject,
  });

  @override
  State<CreationProjectsSection> createState() =>
      _CreationProjectsSectionState();
}

class _CreationProjectsSectionState extends State<CreationProjectsSection> {
  bool _completedExpanded = false;

  String _fmtMinutes(int min) {
    if (min == 0) return '0 min';
    final h = min ~/ 60;
    final m = min % 60;
    if (h == 0) return '${m}min';
    if (m == 0) return '${h}h';
    return '${h}h ${m}min';
  }

  Future<void> _showNewProjectDialog() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New project'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(hintText: 'Project name'),
          onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Create'),
          ),
        ],
      ),
    );
    if (name == null || name.isEmpty || !mounted) return;
    final error = await widget.onCreateProject(name);
    if (error != null && mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
    }
  }

  Future<void> _showEditDialog(CreationProject project) async {
    final controller = TextEditingController(text: project.name);
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename project'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(hintText: 'Project name'),
          onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (name == null || name.isEmpty || !mounted) return;
    final error = await widget.onUpdateProject(project.id, name);
    if (error != null && mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
    }
  }

  Future<void> _confirmComplete(CreationProject project) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Complete project?'),
        content: Text(
            'Mark "${project.name}" as completed. This cannot be undone here.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Complete'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final error = await widget.onCompleteProject(project.id);
    if (error != null && mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
    }
  }

  Future<void> _confirmDelete(CreationProject project) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete project?'),
        content: Text('Remove "${project.name}" and all its data.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final error = await widget.onDeleteProject(project.id);
    if (error != null && mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
    }
  }

  Widget _buildProjectTile(
    BuildContext context,
    CreationProject project, {
    required bool isActive,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      project.name,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _fmtMinutes(project.totalMinutes),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
              if (isActive) ...[
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  onPressed: widget.isBusy ? null : () => _showEditDialog(project),
                  tooltip: 'Rename',
                  visualDensity: VisualDensity.compact,
                ),
                IconButton(
                  icon: const Icon(Icons.check_circle_outline, size: 18),
                  onPressed:
                      widget.isBusy ? null : () => _confirmComplete(project),
                  tooltip: 'Mark complete',
                  visualDensity: VisualDensity.compact,
                ),
              ],
              IconButton(
                icon: Icon(Icons.delete_outline,
                    size: 18, color: theme.colorScheme.error),
                onPressed: widget.isBusy ? null : () => _confirmDelete(project),
                tooltip: 'Delete',
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final active = widget.stats.activeProjects;
    final completed = widget.stats.completedProjects;

    return SectionCard(
      title: 'Projects',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Active projects
          if (active.isEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                'No active projects.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
                ),
              ),
            )
          else
            ...active.map(
              (p) => _buildProjectTile(context, p, isActive: true),
            ),

          // New project button
          OutlinedButton.icon(
            onPressed: widget.isBusy ? null : _showNewProjectDialog,
            icon: const Icon(Icons.add, size: 16),
            label: const Text('New project'),
            style: OutlinedButton.styleFrom(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),

          // Completed (collapsible)
          if (completed.isNotEmpty) ...[
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () =>
                  setState(() => _completedExpanded = !_completedExpanded),
              child: Row(
                children: [
                  Icon(
                    _completedExpanded
                        ? Icons.expand_less
                        : Icons.expand_more,
                    size: 18,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Completed (${completed.length})',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color:
                          theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
            if (_completedExpanded) ...[
              const SizedBox(height: 8),
              ...completed.map(
                (p) => _buildProjectTile(context, p, isActive: false),
              ),
            ],
          ],
        ],
      ),
    );
  }
}
