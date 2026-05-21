import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:admin/models/task_models.dart';
import 'package:admin/models/customer_project.dart';
import 'package:admin/providers/task_provider.dart';
import 'package:admin/services/customer_project_service.dart';
import 'package:admin/widgets/common/search_bar_widget.dart';
import 'package:admin/theme/app_theme.dart';
import 'task_detail_screen.dart';
import 'task_create_screen.dart';
import '../../providers/permission_provider.dart';

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  final _projectService = CustomerProjectService();
  List<CustomerProject> _projects = [];
  bool _loadingProjects = true;

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  Future<void> _loadProjects() async {
    try {
      // Load a reasonable page of projects for the filter dropdown.
      // Sorted by id desc so the most recent projects appear first.
      final page = await _projectService.getProjects(size: 200);
      if (!mounted) return;
      setState(() {
        _projects = page.content;
        _loadingProjects = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingProjects = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => TaskProvider()..fetch(),
      child: Consumer<TaskProvider>(
        builder: (context, provider, _) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Tasks'),
              actions: [
                Consumer<PermissionProvider>(
                  builder: (context, permissionProvider, _) {
                    if (permissionProvider.canCreateTask) {
                      return IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () => _navigateToCreate(context),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ],
            ),
            body: Column(
              children: [
                _buildSearchAndFilters(context, provider),
                Expanded(child: _buildTaskList(context, provider)),
                if (provider.totalPages > 1)
                  _buildPagination(context, provider),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSearchAndFilters(BuildContext context, TaskProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[100],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SearchBarWidget(
            onSearch: (query) => provider.search(query),
            hintText: 'Search tasks...',
          ),
          const SizedBox(height: 12),
          _buildProjectFilter(context, provider),
          const SizedBox(height: 12),
          _buildFilterChips(context, provider),
        ],
      ),
    );
  }

  Widget _buildProjectFilter(BuildContext context, TaskProvider provider) {
    final selectedId = provider.filters['projectId'] as int?;
    if (_loadingProjects) {
      return Row(
        children: [
          const SizedBox(
              width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)),
          const SizedBox(width: 8),
          Text('Loading projects…',
              style: TextStyle(color: Colors.grey.shade700, fontSize: 12)),
        ],
      );
    }
    return Row(
      children: [
        Icon(Icons.folder_outlined, size: 16, color: Colors.grey.shade700),
        const SizedBox(width: 6),
        Text('Project:',
            style: TextStyle(color: Colors.grey.shade800, fontSize: 13)),
        const SizedBox(width: 8),
        Expanded(
          child: DropdownButtonFormField<int?>(
            value: selectedId,
            isDense: true,
            isExpanded: true,
            decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              filled: true,
              fillColor: Colors.white,
            ),
            items: [
              const DropdownMenuItem<int?>(value: null, child: Text('All projects')),
              ..._projects.map((p) => DropdownMenuItem<int?>(
                    value: p.id,
                    child: Text(
                      p.name.isNotEmpty ? p.name : 'Project #${p.id}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  )),
            ],
            onChanged: (id) => provider.filterByProjectId(id),
          ),
        ),
        if (selectedId != null) ...[
          const SizedBox(width: 6),
          IconButton(
            tooltip: 'Clear project filter',
            icon: const Icon(Icons.close, size: 18),
            onPressed: () => provider.filterByProjectId(null),
          ),
        ],
      ],
    );
  }

  Widget _buildFilterChips(BuildContext context, TaskProvider provider) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        // Status filters
        _buildFilterChip(
          context,
          label: 'All',
          isSelected: provider.filters['status'] == null,
          onTap: () => provider.clearFilters(),
        ),
        _buildFilterChip(
          context,
          label: 'Pending',
          isSelected: provider.filters['status'] == 'PENDING',
          onTap: () => provider.updateFilter('status', 'PENDING'),
        ),
        _buildFilterChip(
          context,
          label: 'In Progress',
          isSelected: provider.filters['status'] == 'IN_PROGRESS',
          onTap: () => provider.updateFilter('status', 'IN_PROGRESS'),
        ),
        _buildFilterChip(
          context,
          label: 'Completed',
          isSelected: provider.filters['status'] == 'COMPLETED',
          onTap: () => provider.updateFilter('status', 'COMPLETED'),
        ),
        const SizedBox(width: 16),
        // Priority filters
        _buildFilterChip(
          context,
          label: 'Urgent',
          isSelected: provider.filters['priority'] == 'URGENT',
          onTap: () => provider.updateFilter('priority', 'URGENT'),
          color: AppTheme.statusError,
        ),
        _buildFilterChip(
          context,
          label: 'High',
          isSelected: provider.filters['priority'] == 'HIGH',
          onTap: () => provider.updateFilter('priority', 'HIGH'),
          color: AppTheme.safetyOrange,
        ),
        _buildFilterChip(
          context,
          label: 'Medium',
          isSelected: provider.filters['priority'] == 'MEDIUM',
          onTap: () => provider.updateFilter('priority', 'MEDIUM'),
          color: AppTheme.safetyYellow,
        ),
        _buildFilterChip(
          context,
          label: 'Low',
          isSelected: provider.filters['priority'] == 'LOW',
          onTap: () => provider.updateFilter('priority', 'LOW'),
        ),
      ],
    );
  }

  Widget _buildFilterChip(
    BuildContext context, {
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    Color? color,
  }) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
      backgroundColor: color?.withOpacity(0.1),
      selectedColor: color ?? Theme.of(context).primaryColor,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : (color ?? Colors.black87),
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildTaskList(BuildContext context, TaskProvider provider) {
    if (provider.isLoading && provider.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
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
            Icon(Icons.task_alt, size: 48, color: Colors.grey),
            SizedBox(height: 16),
            Text('No tasks found', style: TextStyle(fontSize: 16)),
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
          final task = provider.items[index];
          return _buildTaskCard(context, task);
        },
      ),
    );
  }

  Widget _buildTaskCard(BuildContext context, TaskModel task) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: () => _navigateToDetail(context, task),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      task.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _buildPriorityBadge(task.priority.toApiString()),
                ],
              ),
              ...[
                const SizedBox(height: 8),
                Text(
                  task.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  _buildInfoChip(
                    icon: Icons.circle,
                    label: task.status.displayName,
                    color: _getStatusColor(task.status.toApiString()),
                  ),
                  if (task.assignedToName != null)
                    _buildInfoChip(
                      icon: Icons.person,
                      label: task.assignedToName!,
                    ),
                  if (task.projectName != null)
                    _buildInfoChip(
                      icon: Icons.business,
                      label: task.projectName!,
                    ),
                  if (task.dueDate != null)
                    _buildInfoChip(
                      icon: Icons.calendar_today,
                      label: _formatDate(task.dueDate!),
                      color: _getDueDateColor(task.dueDate!),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPriorityBadge(String priority) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getPriorityColor(priority),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        priority,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    Color? color,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color ?? Colors.grey[600]),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: color ?? Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildPagination(BuildContext context, TaskProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Page ${provider.currentPage + 1} of ${provider.totalPages}',
            style: const TextStyle(fontSize: 14),
          ),
          Row(
            children: [
              IconButton(
                onPressed: provider.currentPage > 0
                    ? () => provider.goToPage(provider.currentPage - 1)
                    : null,
                icon: const Icon(Icons.chevron_left),
              ),
              IconButton(
                onPressed: provider.currentPage < provider.totalPages - 1
                    ? () => provider.goToPage(provider.currentPage + 1)
                    : null,
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toUpperCase()) {
      case 'URGENT':
        return AppTheme.statusError;
      case 'HIGH':
        return AppTheme.safetyOrange;
      case 'MEDIUM':
        return AppTheme.safetyYellow;
      case 'LOW':
      default:
        return Colors.blue;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'COMPLETED':
        return AppTheme.statusSuccess;
      case 'IN_PROGRESS':
        return AppTheme.statusWarning;
      case 'CANCELLED':
        return AppTheme.statusError;
      case 'PENDING':
      default:
        return Colors.grey;
    }
  }

  Color _getDueDateColor(DateTime dueDate) {
    final now = DateTime.now();
    final diff = dueDate.difference(now).inDays;
    if (diff < 0) return AppTheme.statusError;
    if (diff <= 3) return AppTheme.safetyOrange;
    return Colors.grey;
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _navigateToDetail(BuildContext context, TaskModel task) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TaskDetailScreen(taskId: task.id),
      ),
    );
  }

  void _navigateToCreate(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const TaskCreateScreen(),
      ),
    );
  }
}
