import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../models/task_models.dart';
import '../../../../services/task_service.dart';
import '../../data/models/lead.dart';
import '../../../../providers/portal_auth_provider.dart';
import '../../../../utils/error_handler.dart';

class LeadTasksScreen extends StatefulWidget {
  final Lead lead;

  const LeadTasksScreen({super.key, required this.lead});

  @override
  State<LeadTasksScreen> createState() => _LeadTasksScreenState();
}

class _LeadTasksScreenState extends State<LeadTasksScreen> {
  final TaskService _taskService = TaskService();
  List<TaskModel> _tasks = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _verifyAuthAndLoadData();
  }

  Future<void> _verifyAuthAndLoadData() async {
    final authProvider = Provider.of<PortalAuthProvider>(context, listen: false);
    if (!authProvider.isAuthenticated) {
      if (mounted) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
             Navigator.of(context).pushReplacementNamed('/login');
          }
        });
      }
      return;
    }
    await _loadTasks();
  }

  Future<void> _loadTasks() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final leadIdVal = int.tryParse(widget.lead.leadId);
      if (leadIdVal == null) {
        throw Exception('Invalid Lead ID: ${widget.lead.leadId}');
      }
      final tasks = await _taskService.getTasksByLead(leadIdVal);
      setState(() {
        // Sort by due date (ascending)
        tasks.sort((a, b) {
            if (a.dueDate == null) return 1;
            if (b.dueDate == null) return -1;
            return a.dueDate!.compareTo(b.dueDate!);
        });
        _tasks = tasks;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        await ErrorHandler.handleApiError(context, e, defaultMessage: 'Failed to load tasks');
      }
    }
  }

  Future<void> _addTask() async {
     final leadIdVal = int.tryParse(widget.lead.leadId);
     if (leadIdVal == null) return;

     await showDialog(
         context: context,
         builder: (ctx) => _AddTaskDialog(leadId: leadIdVal, onSave: _loadTasks)
     );
  }

  Future<void> _updateTaskStatus(TaskModel task, String newStatus) async {
      try {
          await _taskService.updateTask(task.id, UpdateTaskRequest(status: newStatus));
          await _loadTasks();
      } catch (e) {
          if (mounted) {
            await ErrorHandler.handleApiError(context, e, defaultMessage: 'Failed to update task status');
          }
      }
  }

  Future<void> _deleteTask(TaskModel task) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Task'),
        content: Text('Are you sure you want to delete "${task.title}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _taskService.deleteTask(task.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Task deleted successfully')),
          );
          await _loadTasks();
        }
      } catch (e) {
        if (mounted) {
          await ErrorHandler.handleApiError(context, e, defaultMessage: 'Failed to delete task');
        }
      }
    }
  }

  Color _getStatusColor(String status) {
      switch (status) {
          case 'PENDING': return Colors.orange;
          case 'IN_PROGRESS': return Colors.blue;
          case 'COMPLETED': return Colors.green;
          case 'CANCELLED': return Colors.red;
          default: return Colors.grey;
      }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Tasks: ${widget.lead.name}')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text('Error: $_errorMessage'))
              : _tasks.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check_circle_outline, size: 64, color: Colors.grey),
                          const SizedBox(height: 16),
                          const Text('No tasks found for this lead.'),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                              onPressed: _addTask,
                              icon: const Icon(Icons.add),
                              label: const Text('Add Task')
                          )
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _tasks.length,
                      itemBuilder: (context, index) {
                        final task = _tasks[index];
                        final isOverdue = task.dueDate != null && 
                                          task.dueDate!.isBefore(DateTime.now()) && 
                                          task.status != TaskStatus.completed;

                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                                backgroundColor: _getStatusColor(task.status.toApiString()),
                                child: const Icon(Icons.assignment, color: Colors.white, size: 20)
                            ),
                            title: Text(
                                task.title,
                                style: TextStyle(
                                    decoration: task.status == TaskStatus.completed ? TextDecoration.lineThrough : null
                                )
                            ),
                            subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                    if (task.description.isNotEmpty) Text(task.description, maxLines: 1, overflow: TextOverflow.ellipsis),
                                    const SizedBox(height: 4),
                                    Row(
                                        children: [
                                            Icon(Icons.calendar_today, size: 12, color: isOverdue ? Colors.red : Colors.grey),
                                            const SizedBox(width: 4),
                                            Text(
                                                task.dueDateFormatted,
                                                style: TextStyle(
                                                    fontSize: 12, 
                                                    color: isOverdue ? Colors.red : Colors.grey,
                                                    fontWeight: isOverdue ? FontWeight.bold : FontWeight.normal
                                                )
                                            ),
                                            const SizedBox(width: 8),
                                            const Icon(Icons.flag, size: 12, color: Colors.grey),
                                            const SizedBox(width: 4),
                                            Text(task.priority.displayName, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                        ]
                                    )
                                ]
                            ),
                            trailing: PopupMenuButton<String>(
                                onSelected: (value) async {
                                    if (value == 'DELETE') {
                                        await _deleteTask(task);
                                    } else {
                                        await _updateTaskStatus(task, value);
                                    }
                                },
                                itemBuilder: (context) => [
                                    if (task.status != TaskStatus.pending)
                                        const PopupMenuItem(value: 'PENDING', child: Text('Mark Pending')),
                                    if (task.status != TaskStatus.inProgress)
                                        const PopupMenuItem(value: 'IN_PROGRESS', child: Text('Mark In Progress')),
                                    if (task.status != TaskStatus.completed)
                                        const PopupMenuItem(value: 'COMPLETED', child: Text('Mark Completed')),
                                    if (task.status != TaskStatus.cancelled)
                                        const PopupMenuItem(value: 'CANCELLED', child: Text('Mark Cancelled')),
                                    // const PopupMenuDivider(),
                                    // const PopupMenuItem(value: 'DELETE', child: Text('Delete', style: TextStyle(color: Colors.red))),
                                ]
                            ),
                          ),
                        );
                      },
                    ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addTask,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _AddTaskDialog extends StatefulWidget {
  final int leadId;
  final VoidCallback onSave;
  const _AddTaskDialog({required this.leadId, required this.onSave});

  @override
  State<_AddTaskDialog> createState() => _AddTaskDialogState();
}

class _AddTaskDialogState extends State<_AddTaskDialog> {
    final _formKey = GlobalKey<FormState>();
    final _titleController = TextEditingController();
    final _descController = TextEditingController();
    DateTime? _dueDate;
    String _priority = 'MEDIUM';
    bool _isSaving = false;

    @override
    Widget build(BuildContext context) {
        return AlertDialog(
            title: const Text('New Task'),
            content: SizedBox(
                width: 400,
                child: Form(
                    key: _formKey,
                    child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                            TextFormField(
                                controller: _titleController,
                                decoration: const InputDecoration(labelText: 'Title *'),
                                validator: (v) => v!.isEmpty ? 'Required' : null,
                            ),
                            TextFormField(
                                controller: _descController,
                                decoration: const InputDecoration(labelText: 'Description'),
                                maxLines: 2,
                            ),
                            const SizedBox(height: 16),
                            Row(
                                children: [
                                    Expanded(
                                        child: InkWell(
                                            onTap: () async {
                                                final date = await showDatePicker(
                                                    context: context,
                                                    initialDate: DateTime.now().add(const Duration(days: 1)),
                                                    firstDate: DateTime.now(),
                                                    lastDate: DateTime.now().add(const Duration(days: 365)),
                                                );
                                                if (date != null) setState(() => _dueDate = date);
                                            },
                                            child: InputDecorator(
                                                decoration: const InputDecoration(labelText: 'Due Date *'),
                                                child: Text(
                                                    _dueDate != null ? DateFormat('yyyy-MM-dd').format(_dueDate!) : 'Select Date',
                                                ),
                                            ),
                                        ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                        child: DropdownButtonFormField<String>(
                                            value: _priority,
                                            decoration: const InputDecoration(labelText: 'Priority'),
                                            items: ['LOW', 'MEDIUM', 'HIGH', 'URGENT'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                                            onChanged: (v) => setState(() => _priority = v!),
                                        ),
                                    ),
                                ]
                            )
                        ]
                    )
                ),
            ),
            actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                ElevatedButton(
                    onPressed: _save, 
                    child: _isSaving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Create Task')
                ),
            ]
        );
    }

    Future<void> _save() async {
        if (!_formKey.currentState!.validate()) return;
        if (_dueDate == null) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Due Date is mandatory')));
            return;
        }
        
        setState(() => _isSaving = true);
        try {
            // NOTE: Backend requires ISO8601 string for LocalDate (YYYY-MM-DD usually works, but DateTime.toIso8601String() includes time)
            // TaskController uses standard Jackson deserialization to LocalDate.
            // If I send "2023-10-27T10:00:00" it might fail if expecting "yyyy-MM-dd".
            // Task.java line 61 uses LocalDate.
            // CreateTaskRequest (DART) uses String? dueDate.
            // I should format it as yyyy-MM-dd.
            
            final dateStr = DateFormat('yyyy-MM-dd').format(_dueDate!);
            
            await TaskService().createTask(CreateTaskRequest(
                title: _titleController.text,
                description: _descController.text,
                leadId: widget.leadId,
                dueDate: dateStr,
                priority: _priority,
            ));
            widget.onSave();
            if (mounted) Navigator.pop(context);
        } catch (e) {
            setState(() => _isSaving = false);
            if (mounted) {
              await ErrorHandler.handleApiError(context, e, defaultMessage: 'Failed to create task');
            }
        }
    }
}

