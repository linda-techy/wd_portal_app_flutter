import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:admin/features/projects/data/models/project_model.dart';
import 'package:admin/features/projects/presentation/providers/project_provider.dart';
import 'package:admin/providers/permission_provider.dart';
import 'package:admin/widgets/common/search_bar_widget.dart';
import 'package:admin/theme/app_theme.dart';
import 'project_detail_screen.dart';

class ProjectsListScreen extends StatelessWidget {
  const ProjectsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ProjectProvider()..fetch(),
      child: Consumer<ProjectProvider>(
        builder: (context, provider, _) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Projects'),
            ),
            body: (provider.isLoading && provider.items.isEmpty)
                ? const Center(child: CircularProgressIndicator())
                : Column(
                    children: [
                      _buildSearchBar(context, provider),
                      Expanded(child: _buildProjectList(context, provider)),
                      if (provider.totalPages > 1)
                        _buildPagination(context, provider),
                    ],
                  ),
          );
        },
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context, ProjectProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[100],
      child: SearchBarWidget(
        onSearch: (query) => provider.search(query),
        hintText: 'Search projects...',
      ),
    );
  }

  Widget _buildProjectList(BuildContext context, ProjectProvider provider) {
    if (provider.isLoading && provider.items.isEmpty) {
      return const SizedBox();
    }

    if (provider.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: ${provider.error}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => provider.fetch(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (provider.items.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.construction, size: 48, color: Colors.grey),
            SizedBox(height: 16),
            Text('No projects found', style: TextStyle(fontSize: 16)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => provider.fetch(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: provider.items.length,
        itemBuilder: (context, index) {
          final project = provider.items[index];
          return _buildProjectCard(context, project);
        },
      ),
    );
  }

  Widget _buildProjectCard(BuildContext context, ProjectModel project) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: () => _navigateToDetail(context, project),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      project.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (project.projectPhase != null)
                    _buildPhaseBadge(project.projectPhase!),
                  if (context.watch<PermissionProvider>().canDeleteProject)
                    _buildProjectActionsMenu(context, project),
                ],
              ),
              if (project.code != null) ...[
                const SizedBox(height: 4),
                Text(
                  project.code!,
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
              ],
              const SizedBox(height: 10),
              if (project.overallProgress != null) ...[
                Row(
                  children: [
                    Expanded(
                      child: LinearProgressIndicator(
                        value: (project.overallProgress! / 100).clamp(0.0, 1.0),
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _progressColor(project.overallProgress!),
                        ),
                        minHeight: 6,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${project.overallProgress!.toStringAsFixed(0)}%',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
              ],
              Row(
                children: [
                  const Icon(Icons.location_on, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      project.location,
                      style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (project.projectStatus != null)
                    _buildStatusBadge(project.projectStatus!),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProjectActionsMenu(BuildContext context, ProjectModel project) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, size: 20),
      tooltip: 'Project actions',
      onSelected: (value) {
        if (value == 'delete') {
          _confirmDelete(context, project);
        }
      },
      itemBuilder: (_) => const [
        PopupMenuItem<String>(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete_outline, size: 18, color: Colors.red),
              SizedBox(width: 8),
              Text('Delete project', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _confirmDelete(BuildContext context, ProjectModel project) async {
    final provider = context.read<ProjectProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete project?'),
        content: Text(
          'This permanently deletes "${project.name}". '
          'Related WBS, BOQ, tasks, and reports will also be removed. '
          'This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final id = project.id;
    if (id == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Cannot delete: project has no id')),
      );
      return;
    }
    try {
      await provider.deleteProject(id);
      messenger.showSnackBar(
        SnackBar(content: Text('Deleted "${project.name}"')),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text('Delete failed: $e'),
        ),
      );
    }
  }

  Widget _buildPhaseBadge(String phase) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.deepSlate,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        phase,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    final color = _statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
      case 'ongoing':
      case 'in_progress':
        return Colors.green;
      case 'completed':
      case 'handover':
        return Colors.blue;
      case 'on_hold':
      case 'paused':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _progressColor(double progress) {
    if (progress >= 75) return Colors.green;
    if (progress >= 40) return AppTheme.constructionOrange;
    return AppTheme.coralRed;
  }

  Widget _buildPagination(BuildContext context, ProjectProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, -2),
            blurRadius: 4,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Page ${provider.currentPage + 1} of ${provider.totalPages}',
            style: TextStyle(fontSize: 13, color: Colors.grey[700]),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: provider.hasPrevious ? () => provider.previousPage() : null,
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: provider.hasNext ? () => provider.nextPage() : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _navigateToDetail(BuildContext context, ProjectModel project) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProjectDetailScreen(project: project),
      ),
    );
  }
}
