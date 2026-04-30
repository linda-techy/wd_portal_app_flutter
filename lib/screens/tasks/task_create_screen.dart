import 'package:flutter/material.dart';
import 'package:admin/utils/error_handler.dart';
import 'package:admin/models/task_models.dart';
import 'package:admin/services/task_service.dart';
import 'package:admin/services/crm_service.dart';
import 'package:admin/models/customer_project.dart';
import 'package:admin/models/team_member_simple.dart';
import 'package:admin/theme/app_theme.dart';
import 'package:admin/theme/responsive_utils.dart';

class TaskCreateScreen extends StatefulWidget {
  const TaskCreateScreen({super.key});

  @override
  State<TaskCreateScreen> createState() => _TaskCreateScreenState();
}

class _TaskCreateScreenState extends State<TaskCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final TaskService _taskService = TaskService();
  final CRMService _crmService = CRMService();
  
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  String _selectedPriority = 'MEDIUM';
  String _selectedStatus = 'PENDING';
  int? _selectedProjectId;
  int? _selectedAssigneeId;
  DateTime? _selectedDueDate;
  
  List<CustomerProject> _projects = [];
  List<TeamMemberSimple> _teamMembers = [];
  bool _isLoading = false;
  bool _isLoadingData = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final projects = await _crmService.getAllCustomerProjects();
      final teamMembers = await _crmService.getTeamMembersForAssignment();
      setState(() {
        _projects = projects;
        _teamMembers = teamMembers;
        _isLoadingData = false;
      });
    } catch (e) {
      setState(() => _isLoadingData = false);
      if (mounted) {
        ErrorHandler.showErrorSnackBar(context, e);
      }
    }
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDueDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(() => _selectedDueDate = date);
    }
  }

  Future<void> _createTask() async {
    if (!_formKey.currentState!.validate() || _selectedDueDate == null) {
      if (_selectedDueDate == null) {
        setState(() {}); // Trigger rebuild to show error on due date field
      }
      return;
    }

    setState(() => _isLoading = true);

    try {
      final task = CreateTaskRequest(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        priority: _selectedPriority,
        status: _selectedStatus,
        assignedToId: _selectedAssigneeId,
        projectId: _selectedProjectId,
        dueDate: _selectedDueDate?.toIso8601String().split('T')[0],
      );

      await _taskService.createTask(task);
      
      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Task created successfully')),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ErrorHandler.showErrorSnackBar(context, e);
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
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
        title: const Text('Create Task'),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
      ),
      body: _isLoadingData
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: ResponsiveUtils.responsivePadding(context),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Title
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Task Title *',
                        hintText: 'Enter task title',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a task title';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppTheme.spacingMD),

                    // Description
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        hintText: 'Enter task description',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 4,
                    ),
                    const SizedBox(height: AppTheme.spacingMD),

                    // Priority
                    DropdownButtonFormField<String>(
                      value: _selectedPriority,
                      decoration: const InputDecoration(
                        labelText: 'Priority *',
                        border: OutlineInputBorder(),
                      ),
                      items: ['LOW', 'MEDIUM', 'HIGH', 'URGENT']
                          .map((priority) => DropdownMenuItem(
                                value: priority,
                                child: Text(priority),
                              ))
                          .toList(),
                      onChanged: (value) => setState(() => _selectedPriority = value!),
                    ),
                    const SizedBox(height: AppTheme.spacingMD),

                    // Status
                    DropdownButtonFormField<String>(
                      value: _selectedStatus,
                      decoration: const InputDecoration(
                        labelText: 'Status *',
                        border: OutlineInputBorder(),
                      ),
                      items: ['PENDING', 'IN_PROGRESS', 'COMPLETED']
                          .map((status) => DropdownMenuItem(
                                value: status,
                                child: Text(status.replaceAll('_', ' ')),
                              ))
                          .toList(),
                      onChanged: (value) => setState(() => _selectedStatus = value!),
                    ),
                    const SizedBox(height: AppTheme.spacingMD),

                    // Project
                    DropdownButtonFormField<int>(
                      value: _selectedProjectId,
                      decoration: const InputDecoration(
                        labelText: 'Project (Optional)',
                        border: OutlineInputBorder(),
                      ),
                      hint: _isLoadingData
                          ? const Text('Loading projects...')
                          : _projects.isEmpty
                              ? const Text('No projects available')
                              : const Text('Select a project'),
                      items: _projects
                          .map((project) => DropdownMenuItem(
                                value: project.id!,
                                child: Text(
                                  project.code != null && project.code!.isNotEmpty
                                      ? '[${project.code}] ${project.name}'
                                      : project.name,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ))
                          .toList(),
                      onChanged: (value) => setState(() => _selectedProjectId = value),
                    ),
                    const SizedBox(height: AppTheme.spacingMD),

                    // Assign To
                    DropdownButtonFormField<int>(
                      value: _selectedAssigneeId,
                      decoration: const InputDecoration(
                        labelText: 'Assign To (Optional)',
                        border: OutlineInputBorder(),
                      ),
                      hint: _isLoadingData
                          ? const Text('Loading staff...')
                          : _teamMembers.isEmpty
                              ? const Text('No staff available')
                              : const Text('Select team member'),
                      items: _teamMembers
                          .map((member) => DropdownMenuItem(
                                value: member.id,
                                child: Text(
                                  member.fullName.isNotEmpty
                                      ? member.fullName
                                      : '${member.firstName} ${member.lastName}'.trim(),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ))
                          .toList(),
                      onChanged: (value) => setState(() => _selectedAssigneeId = value),
                    ),
                    const SizedBox(height: AppTheme.spacingMD),

                    // Due Date
                    InkWell(
                      onTap: _selectDate,
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Due Date *',
                          border: const OutlineInputBorder(),
                          suffixIcon: const Icon(Icons.calendar_today),
                          errorText: _selectedDueDate == null && _formKey.currentState?.validate() == false 
                              ? 'Please select a due date' 
                              : null,
                        ),
                        child: Text(
                          _selectedDueDate == null
                              ? 'Select due date'
                              : '${_selectedDueDate!.day}/${_selectedDueDate!.month}/${_selectedDueDate!.year}',
                        ),
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingXL),

                    // Submit Button
                    ElevatedButton(
                      onPressed: _isLoading ? null : _createTask,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(AppTheme.spacingMD),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Create Task'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

