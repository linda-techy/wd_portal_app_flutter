import 'package:flutter/material.dart';
import 'package:admin/models/task_models.dart';
import 'package:admin/services/task_service.dart';
import 'package:admin/theme/app_theme.dart';
import 'package:admin/theme/responsive_utils.dart';
import 'package:intl/intl.dart';

class TaskDetailScreen extends StatefulWidget {
  final int taskId;

  const TaskDetailScreen({super.key, required this.taskId});

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  final TaskService _taskService = TaskService();
  TaskModel? _task;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTask();
  }

  Future<void> _loadTask() async {
    if (mounted) setState(() => _isLoading = true);
    try {
      final task = await _taskService.getTaskById(widget.taskId);
      if (mounted) {
        setState(() {
          _task = task;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading task: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _onStatusChange(String newStatus) async {
    if (_task == null || _task!.status.toApiString() == newStatus) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Status?'),
        content: Text('Are you sure you want to change the status to ${_formatStatus(newStatus)}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.coralRed, foregroundColor: Colors.white),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _updateStatus(newStatus);
    }
  }

  Future<void> _updateStatus(String newStatus) async {
    try {
      final updateRequest = UpdateTaskRequest(
        title: _task!.title,
        status: newStatus,
      );
      await _taskService.updateTask(widget.taskId, updateRequest);
      await _loadTask();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Task status updated'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating task: $e'), backgroundColor: Colors.red),
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
        title: const Text('Task Details'),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        actions: [
           IconButton(
             icon: const Icon(Icons.refresh),
             onPressed: _loadTask,
           ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.coralRed))
          : _task == null
              ? const Center(child: Text('Task not found'))
              : SingleChildScrollView(
                  padding: ResponsiveUtils.responsivePadding(context),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeaderCard(),
                      const SizedBox(height: AppTheme.spacingMD),
                      _buildStatusUpdateCard(),
                      const SizedBox(height: AppTheme.spacingMD),
                      _buildInfoGrid(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildHeaderCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
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
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getPriorityColor(_task!.priority.toApiString()).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _getPriorityColor(_task!.priority.toApiString())),
                  ),
                  child: Text(
                    _task!.priority.toApiString(),
                    style: TextStyle(
                      color: _getPriorityColor(_task!.priority.toApiString()),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            if (_task!.description != null && _task!.description!.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text("Description", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textSecondary)),
              const SizedBox(height: 4),
              Text(
                _task!.description!,
                style: const TextStyle(fontSize: 15, color: AppTheme.textPrimary, height: 1.5),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusUpdateCard() {
    final currentStatus = _task!.status.toApiString();
    
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingMD),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.change_circle_outlined, size: 20, color: AppTheme.textSecondary),
                const SizedBox(width: 8),
                Text(
                  'Task Status',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ['PENDING', 'IN_PROGRESS', 'COMPLETED', 'CANCELLED'].map((status) {
                final isSelected = currentStatus == status;
                return ChoiceChip(
                  label: Text(_formatStatus(status)),
                  selected: isSelected,
                  onSelected: (selected) => _onStatusChange(status),
                  selectedColor: _getStatusColor(status).withOpacity(0.2),
                  labelStyle: TextStyle(
                    color: isSelected ? _getStatusColor(status) : AppTheme.textSecondary,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 13,
                  ),
                  backgroundColor: Colors.grey.shade50,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoGrid() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingMD),
        child: Column(
          children: [
            if (_task!.projectName != null)
              _buildInfoRow(Icons.business_center_outlined, 'Project', _task!.projectName!),
            _buildInfoRow(Icons.person_outline, 'Assigned To', _task!.assignedToName ?? 'Unassigned'),
            _buildInfoRow(Icons.edit_note_outlined, 'Created By', _task!.createdByName ?? 'System'),
            if (_task!.dueDate != null)
              _buildInfoRow(
                Icons.calendar_month_outlined,
                'Due Date',
                DateFormat('dd MMM, yyyy').format(_task!.dueDate!),
                valueColor: _task!.dueDate!.isBefore(DateTime.now()) && _task!.status.toApiString() != 'COMPLETED'
                    ? Colors.red
                    : AppTheme.textPrimary,
              ),
            _buildInfoRow(
              Icons.schedule_outlined,
              'Created At',
              DateFormat('dd MMM, yyyy').format(_task!.createdAt),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, size: 20, color: AppTheme.textTertiary),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  color: valueColor ?? AppTheme.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

