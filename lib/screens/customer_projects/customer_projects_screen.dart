import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../theme/responsive_utils.dart';
import '../../models/customer_project.dart';
import '../../services/crm_service.dart';
import '../../widgets/components/status_indicator.dart';
import 'add_customer_project_screen.dart';
import 'edit_customer_project_screen.dart';
import 'package:intl/intl.dart';

class CustomerProjectsScreen extends StatefulWidget {
  const CustomerProjectsScreen({super.key});

  @override
  State<CustomerProjectsScreen> createState() => _CustomerProjectsScreenState();
}

class _CustomerProjectsScreenState extends State<CustomerProjectsScreen> {
  List<CustomerProject> projects = [];
  bool isLoading = true;
  String? errorMessage;
  final CRMService _crmService = CRMService();

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  Future<void> _loadProjects() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      final loadedProjects = await _crmService.getAllCustomerProjects();

      if (mounted) {
        setState(() {
          projects = loadedProjects;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
          errorMessage = _getErrorMessage(e);
        });
      }
    }
  }

  String _getErrorMessage(dynamic error) {
    if (error.toString().contains('SocketException') ||
        error.toString().contains('HandshakeException')) {
      return 'Network error. Please check your internet connection.';
    } else if (error.toString().contains('TimeoutException')) {
      return 'Request timed out. Please try again.';
    } else if (error.toString().contains('FormatException')) {
      return 'Invalid data received from server.';
    } else if (error.toString().contains('500')) {
      return 'Server error. Please try again later.';
    } else if (error.toString().contains('404')) {
      return 'Service not found. Please contact support.';
    } else {
      return 'Failed to load projects. Please try again.';
    }
  }

  Future<void> _refreshProjects() async {
    await _loadProjects();
  }

  Future<void> _deleteProject(CustomerProject project) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Project'),
        content: Text('Are you sure you want to delete "${project.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.statusError),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true && project.id != null) {
      try {
        await _crmService.deleteCustomerProject(project.id!);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Project deleted successfully'),
              backgroundColor: AppTheme.statusSuccess,
            ),
          );
          _loadProjects();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete project: ${e.toString()}'),
              backgroundColor: AppTheme.statusError,
            ),
          );
        }
      }
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return DateFormat('MMM dd, yyyy').format(date);
  }

  String _formatProgress(double? progress) {
    if (progress == null) return 'N/A';
    return '${progress.toStringAsFixed(1)}%';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: AdaptiveContainer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Customer Projects',
                  style: Theme.of(context).textTheme.displaySmall,
                ),
                ElevatedButton.icon(
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AddCustomerProjectScreen(),
                      ),
                    );
                    if (result == true) {
                      _loadProjects();
                    }
                  },
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Project'),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingLG),

            // Error Message
            if (errorMessage != null)
              Container(
                padding: const EdgeInsets.all(AppTheme.spacingMD),
                margin: const EdgeInsets.only(bottom: AppTheme.spacingMD),
                decoration: BoxDecoration(
                  color: AppTheme.statusErrorBg,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                  border:
                      Border.all(color: AppTheme.statusError.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: AppTheme.statusError),
                    const SizedBox(width: AppTheme.spacingMD),
                    Expanded(child: Text(errorMessage!)),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        setState(() {
                          errorMessage = null;
                        });
                      },
                    ),
                  ],
                ),
              ),

            // Projects Table
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : projects.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.folder_open,
                                size: 64,
                                color: AppTheme.textTertiary,
                              ),
                              const SizedBox(height: AppTheme.spacingMD),
                              Text(
                                'No projects found',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.copyWith(
                                      color: AppTheme.textSecondary,
                                    ),
                              ),
                              const SizedBox(height: AppTheme.spacingSM),
                              ElevatedButton.icon(
                                onPressed: () async {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const AddCustomerProjectScreen(),
                                    ),
                                  );
                                  if (result == true) {
                                    _loadProjects();
                                  }
                                },
                                icon: const Icon(Icons.add),
                                label: const Text('Add First Project'),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _refreshProjects,
                          child: _buildProjectsTable(),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectsTable() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Code')),
            DataColumn(label: Text('Name')),
            DataColumn(label: Text('Location')),
            DataColumn(label: Text('Phase')),
            DataColumn(label: Text('Progress')),
            DataColumn(label: Text('Start Date')),
            DataColumn(label: Text('End Date')),
            DataColumn(label: Text('Sq. Feet')),
            DataColumn(label: Text('Actions'), numeric: false),
          ],
          rows: projects.map((project) {
            return DataRow(
              cells: [
                DataCell(Text(project.code ?? 'N/A')),
                DataCell(
                  Tooltip(
                    message: project.name,
                    child: SizedBox(
                      width: 150,
                      child: Text(
                        project.name,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
                DataCell(
                  Tooltip(
                    message: project.location,
                    child: SizedBox(
                      width: 150,
                      child: Text(
                        project.location,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
                DataCell(
                  project.projectPhase != null
                      ? StatusIndicator(
                          label: project.projectPhase!,
                          type: _getPhaseType(project.projectPhase!),
                          compact: true,
                        )
                      : const Text('N/A'),
                ),
                DataCell(
                  project.progress != null
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 60,
                              child: LinearProgressIndicator(
                                value:
                                    (project.progress! / 100).clamp(0.0, 1.0),
                                backgroundColor: AppTheme.borderLight,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  _getProgressColor(project.progress!),
                                ),
                                minHeight: 6,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(_formatProgress(project.progress)),
                          ],
                        )
                      : const Text('N/A'),
                ),
                DataCell(Text(_formatDate(project.startDate))),
                DataCell(Text(_formatDate(project.endDate))),
                DataCell(Text(
                  project.sqfeet != null
                      ? '${project.sqfeet!.toStringAsFixed(0)} sqft'
                      : 'N/A',
                )),
                DataCell(
                  Wrap(
                    spacing: 4,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, size: 18),
                        color: AppTheme.primaryBlue,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EditCustomerProjectScreen(
                                project: project,
                              ),
                            ),
                          );
                          if (result == true) {
                            _loadProjects();
                          }
                        },
                        tooltip: 'Edit',
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, size: 18),
                        color: AppTheme.statusError,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => _deleteProject(project),
                        tooltip: 'Delete',
                      ),
                    ],
                  ),
                ),
              ],
            );
          }).toList(),
          headingRowHeight: 56,
          dataRowMinHeight: 52,
          dataRowMaxHeight: 72,
          headingRowColor: WidgetStateProperty.all(AppTheme.surfaceElevated),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            border: Border.all(color: AppTheme.borderLight, width: 1),
            borderRadius: BorderRadius.circular(AppTheme.radiusMD),
          ),
        ),
      ),
    );
  }

  StatusType _getPhaseType(String phase) {
    final lowerPhase = phase.toLowerCase();
    if (lowerPhase.contains('planning') || lowerPhase.contains('design')) {
      return StatusType.info;
    } else if (lowerPhase.contains('progress') ||
        lowerPhase.contains('ongoing')) {
      return StatusType.primary;
    } else if (lowerPhase.contains('complete') ||
        lowerPhase.contains('finished')) {
      return StatusType.success;
    } else if (lowerPhase.contains('hold') || lowerPhase.contains('pause')) {
      return StatusType.warning;
    }
    return StatusType.neutral;
  }

  Color _getProgressColor(double progress) {
    if (progress >= 80) return AppTheme.statusSuccess;
    if (progress >= 50) return AppTheme.safetyOrange;
    if (progress >= 25) return AppTheme.safetyYellow;
    return AppTheme.statusError;
  }
}
