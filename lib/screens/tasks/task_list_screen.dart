import 'package:flutter/material.dart';
import 'package:admin/models/task.dart';
import 'package:admin/services/task_service.dart';
import 'package:admin/theme/app_theme.dart';
import 'package:admin/theme/responsive_utils.dart';
import 'package:admin/providers/portal_auth_provider.dart';
import 'package:provider/provider.dart';
import 'task_detail_screen.dart';
import 'task_create_screen.dart';

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  final TaskService _taskService = TaskService();
  List<Task> _tasks = [];
  List<Task> _filteredTasks = [];
  bool _isLoading = true;
  String _selectedFilter = 'ALL';

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    if (mounted) setState(() => _isLoading = true);
    try {
      final tasks = await _taskService.getMyTasks();
      if (mounted) {
        setState(() {
          _tasks = tasks;
          _applyFilter();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading tasks: $e')),
        );
      }
    }
  }

  void _applyFilter() {
    if (_selectedFilter == 'ALL') {
      _filteredTasks = _tasks;
    } else {
      _filteredTasks = _tasks.where((task) => task.status == _selectedFilter).toList();
    }
  }

  void _onFilterChanged(String filter) {
    setState(() {
      _selectedFilter = filter;
      _applyFilter();
    });
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'URGENT':
        return AppTheme.statusError;
      case 'HIGH':
        return AppTheme.safetyOrange;
      case 'MEDIUM':
        return AppTheme.safetyYellow;
      case 'LOW':
        return AppTheme.statusSuccess;
      default:
        return AppTheme.textSecondary;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'COMPLETED':
        return AppTheme.statusSuccess;
      case 'IN_PROGRESS':
        return AppTheme.statusInfo;
      case 'PENDING':
        return AppTheme.safetyOrange;
      case 'CANCELLED':
        return AppTheme.textTertiary;
      default:
        return AppTheme.textSecondary;
    }
  }

  String _formatStatus(String status) {
    return status.replaceAll('_', ' ').toLowerCase().split(' ').map((word) => word[0].toUpperCase() + word.substring(1)).join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<PortalAuthProvider>(context);
    final isAdmin = authProvider.currentUser?.role == 'ADMIN';

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Column(
        children: [
          // Header with filters
          Container(
            padding: ResponsiveUtils.responsivePadding(context),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'My Tasks',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    if (isAdmin)
                      ElevatedButton.icon(
                        onPressed: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const TaskCreateScreen(),
                            ),
                          );
                          if (result == true) _loadTasks();
                        },
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Create Task'),
                      ),
                  ],
                ),
                const SizedBox(height: AppTheme.spacingMD),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('ALL', _filteredTasks.length),
                      _buildFilterChip('PENDING', _tasks.where((t) => t.status == 'PENDING').length),
                      _buildFilterChip('IN_PROGRESS', _tasks.where((t) => t.status == 'IN_PROGRESS').length),
                      _buildFilterChip('COMPLETED', _tasks.where((t) => t.status == 'COMPLETED').length),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Task list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredTasks.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.task_alt,
                              size: 64,
                              color: AppTheme.textTertiary,
                            ),
                            const SizedBox(height: AppTheme.spacingMD),
                            Text(
                              'No tasks found',
                              style: TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadTasks,
                        child: ListView.builder(
                          padding: ResponsiveUtils.responsivePadding(context),
                          itemCount: _filteredTasks.length,
                          itemBuilder: (context, index) {
                            final task = _filteredTasks[index];
                            return _buildTaskCard(task);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String filter, int count) {
    final isSelected = _selectedFilter == filter;
    return Padding(
      padding: const EdgeInsets.only(right: AppTheme.spacingSM),
      child: FilterChip(
        label: Text(
          '${_formatStatus(filter)} ($count)',
          style: TextStyle(
            color: isSelected ? Colors.white : AppTheme.textPrimary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        selected: isSelected,
        onSelected: (selected) => _onFilterChanged(filter),
        selectedColor: AppTheme.primaryBlue,
        backgroundColor: AppTheme.surfaceElevated,
      ),
    );
  }

  Widget _buildTaskCard(Task task) {
    final isOverdue = task.dueDate != null && task.dueDate!.isBefore(DateTime.now()) && task.status != 'COMPLETED';

    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingMD),
      child: InkWell(
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TaskDetailScreen(taskId: task.id!),
            ),
          );
          if (result == true) _loadTasks();
        },
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingMD),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      task.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacingSM,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getPriorityColor(task.priority).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                      border: Border.all(
                        color: _getPriorityColor(task.priority),
                      ),
                    ),
                    child: Text(
                      task.priority,
                      style: TextStyle(
                        color: _getPriorityColor(task.priority),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              if (task.description != null && task.description!.isNotEmpty) ...[
                const SizedBox(height: AppTheme.spacingSM),
                Text(
                  task.description!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: AppTheme.spacingMD),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacingSM,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(task.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                    ),
                    child: Text(
                      _formatStatus(task.status),
                      style: TextStyle(
                        color: _getStatusColor(task.status),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingSM),
                  if (task.dueDate != null) ...[
                    Icon(
                      Icons.calendar_today,
                      size: 14,
                      color: isOverdue ? AppTheme.statusError : AppTheme.textTertiary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${task.dueDate!.day}/${task.dueDate!.month}/${task.dueDate!.year}',
                      style: TextStyle(
                        color: isOverdue ? AppTheme.statusError : AppTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                  if (task.projectName != null) ...[
                    const Spacer(),
                    Icon(
                      Icons.folder,
                      size: 14,
                      color: AppTheme.textTertiary,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        task.projectName!,
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
