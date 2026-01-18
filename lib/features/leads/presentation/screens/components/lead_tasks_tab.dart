import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
                      onPressed: () => _showAddTaskDialog(context),
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

  Future<void> _showAddTaskDialog(BuildContext context) async {
    final leadIdVal = int.tryParse(widget.leadId);
    if (leadIdVal == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid Lead ID')),
      );
      return;
    }

    await showDialog(
      context: context,
      builder: (ctx) => _AddTaskDialog(leadId: leadIdVal, onSave: _fetchTasks),
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
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

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
              const SizedBox(height: 16),
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
                ],
              )
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: _save,
          child: _isSaving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Create Task'),
        ),
      ],
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
