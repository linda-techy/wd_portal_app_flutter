import 'package:flutter/material.dart';
import 'package:admin/models/task.dart';
import 'package:admin/services/task_service.dart';
import 'package:admin/theme/app_theme.dart';
import 'package:admin/theme/responsive_utils.dart';

class TaskDetailScreen extends StatefulWidget {
  final int taskId;

  const TaskDetailScreen({super.key, required this.taskId});

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  final TaskService _taskService = TaskService();
  Task? _task;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTask();
  }

  Future<void> _loadTask() async {
    setState(() => _isLoading = true);
    try {
      final task = await _taskService.getTaskById(widget.taskId);
      setState(() {
        _task = task;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading task: $e')),
        );
      }
    }
  }

  Future<void> _updateStatus(String newStatus) async {
    if (_task == null) return;

    try {
      final updatedTask = _task!.copyWith(status: newStatus);
      await _taskService.updateTask(widget.taskId, updatedTask);
      setState(() => _task = updatedTask);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Task status updated')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating task: $e')),
        );
      }
    }
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
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Task Details'),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _task == null
              ? const Center(child: Text('Task not found'))
              : SingleChildScrollView(
                  padding: ResponsiveUtils.responsivePadding(context),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title and Priority
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(AppTheme.spacingMD),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Text(
                                      _task!.title,
                                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppTheme.spacingSM,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _getPriorityColor(_task!.priority).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                                      border: Border.all(
                                        color: _getPriorityColor(_task!.priority),
                                      ),
                                    ),
                                    child: Text(
                                      _task!.priority,
                                      style: TextStyle(
                                        color: _getPriorityColor(_task!.priority),
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (_task!.description != null && _task!.description!.isNotEmpty) ...[
                                const SizedBox(height: AppTheme.spacingMD),
                                Text(
                                  _task!.description!,
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: AppTheme.textSecondary,
                                      ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingMD),

                      // Status Update
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(AppTheme.spacingMD),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Status',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                              const SizedBox(height: AppTheme.spacingSM),
                              Wrap(
                                spacing: AppTheme.spacingSM,
                                children: [
                                  ChoiceChip(
                                    label: Text(_formatStatus('PENDING')),
                                    selected: _task!.status == 'PENDING',
                                    onSelected: (selected) => _updateStatus('PENDING'),
                                    selectedColor: _getStatusColor('PENDING'),
                                    backgroundColor: AppTheme.surfaceElevated,
                                  ),
                                  ChoiceChip(
                                    label: Text(_formatStatus('IN_PROGRESS')),
                                    selected: _task!.status == 'IN_PROGRESS',
                                    onSelected: (selected) => _updateStatus('IN_PROGRESS'),
                                    selectedColor: _getStatusColor('IN_PROGRESS'),
                                    backgroundColor: AppTheme.surfaceElevated,
                                  ),
                                  ChoiceChip(
                                    label: Text(_formatStatus('COMPLETED')),
                                    selected: _task!.status == 'COMPLETED',
                                    onSelected: (selected) => _updateStatus('COMPLETED'),
                                    selectedColor: _getStatusColor('COMPLETED'),
                                    backgroundColor: AppTheme.surfaceElevated,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingMD),

                      // Task Information
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(AppTheme.spacingMD),
                          child: Column(
                            children: [
                              if (_task!.projectName != null)
                                _buildInfoRow(Icons.folder, 'Project', _task!.projectName!),
                              if (_task!.assignedToName != null)
                                _buildInfoRow(Icons.person, 'Assigned To', _task!.assignedToName!),
                              if (_task!.createdByName != null)
                                _buildInfoRow(Icons.person_outline, 'Created By', _task!.createdByName!),
                              if (_task!.dueDate != null)
                                _buildInfoRow(
                                  Icons.calendar_today,
                                  'Due Date',
                                  '${_task!.dueDate!.day}/${_task!.dueDate!.month}/${_task!.dueDate!.year}',
                                ),
                              if (_task!.createdAt != null)
                                _buildInfoRow(
                                  Icons.access_time,
                                  'Created',
                                  '${_task!.createdAt!.day}/${_task!.createdAt!.month}/${_task!.createdAt!.year}',
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingSM),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppTheme.textTertiary),
          const SizedBox(width: AppTheme.spacingSM),
          Text(
            '$label:',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: AppTheme.spacingSM),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
