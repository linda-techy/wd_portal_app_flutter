import 'package:flutter/material.dart';
import 'package:admin/constants.dart';
import '../../../../../../models/task_models.dart';
import '../../../../../../services/task_service.dart';
import '../../../../../../utils/error_handler.dart';

class LeadTasksTab extends StatefulWidget {
  final String leadId;
  const LeadTasksTab({Key? key, required this.leadId}) : super(key: key);

  @override
  _LeadTasksTabState createState() => _LeadTasksTabState();
}

class _LeadTasksTabState extends State<LeadTasksTab> {
  final TaskService _taskService = TaskService();
  bool _isLoading = true;
  List<TaskModel> _tasks = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchTasks();
  }

  Future<void> _fetchTasks() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final leadIdVal = int.tryParse(widget.leadId);
      if (leadIdVal == null) {
        throw Exception('Invalid Lead ID: ${widget.leadId}');
      }
      final tasks = await _taskService.getTasksByLead(leadIdVal);
      if (mounted) {
        setState(() {
          _isLoading = false;
          _tasks = tasks;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Failed to load tasks: ${e.toString()}';
        });
        ErrorHandler.handleApiError(context, e,
            defaultMessage: 'Failed to load tasks');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(defaultPadding),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Tasks",
                        style: Theme.of(context).textTheme.titleLarge),
                    ElevatedButton.icon(
                      onPressed: () {
                        // Open Add Task Modal
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text("Add Task Implemented Next")));
                      },
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text("New Task"),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor),
                    )
                  ],
                ),
              ),
              Expanded(
                child: _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline,
                                size: 48, color: Colors.red[300]),
                            const SizedBox(height: 16),
                            Text(_error!,
                                style: TextStyle(color: Colors.red[600])),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _fetchTasks,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : _tasks.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.check_circle_outline,
                                    size: 48, color: Colors.grey[400]),
                                const SizedBox(height: 16),
                                Text("No tasks found for this lead",
                                    style: TextStyle(color: Colors.grey[600])),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: _tasks.length,
                            itemBuilder: (context, index) {
                              final task = _tasks[index];
                              return ListTile(
                                leading: Icon(
                                  Icons.task,
                                  color: _getStatusColor(task.status.name),
                                ),
                                title: Text(task.title),
                                subtitle: Text(
                                  '${task.status.displayName}${task.dueDate != null ? ' • Due: ${_formatDate(task.dueDate!)}' : ''}',
                                ),
                                trailing: const Icon(Icons.chevron_right),
                                onTap: () {
                                  // Navigate to task detail if needed
                                },
                              );
                            },
                          ),
              ),
            ],
          );
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return Colors.orange;
      case 'IN_PROGRESS':
        return Colors.blue;
      case 'COMPLETED':
        return Colors.green;
      case 'CANCELLED':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
