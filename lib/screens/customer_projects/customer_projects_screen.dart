import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../theme/responsive_utils.dart';
import '../../models/customer_project.dart';
import '../../models/lead.dart';
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
  List<Lead> leads = [];
  bool isLoading = true;
  String? errorMessage;
  final CRMService _crmService = CRMService();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      // Load projects and leads in parallel
      final results = await Future.wait([
        _crmService.getAllCustomerProjects(),
        _crmService.getAllLeads(),
      ]);

      if (mounted) {
        setState(() {
          projects = results[0] as List<CustomerProject>;
          leads = results[1] as List<Lead>;
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

  Future<void> _loadProjects() async {
    await _loadData();
  }

  String _getCustomerName(int? leadId) {
    if (leadId == null) return 'N/A';
    try {
      final lead = leads.firstWhere(
        (l) => int.tryParse(l.leadId) == leadId,
      );
      return lead.name;
    } catch (e) {
      return 'N/A';
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
                          child: _buildProjectsCards(),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectsCards() {
    if (projects.isEmpty) {
      return const SizedBox.shrink();
    }

    return ResponsiveLayout(
      mobile: ListView.builder(
        padding: const EdgeInsets.all(AppTheme.spacingMD),
        itemCount: projects.length,
        itemBuilder: (context, index) {
          return _buildProjectCard(projects[index]);
        },
      ),
      desktop: GridView.builder(
        padding: const EdgeInsets.all(AppTheme.spacingMD),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: AppTheme.spacingMD,
          mainAxisSpacing: AppTheme.spacingMD,
          childAspectRatio: 1.2,
        ),
        itemCount: projects.length,
        itemBuilder: (context, index) {
          return _buildProjectCard(projects[index]);
        },
      ),
    );
  }

  Widget _buildProjectCard(CustomerProject project) {
    final customerName = _getCustomerName(project.leadId);
    final progress = project.progress ?? 0.0;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        side: BorderSide(color: AppTheme.borderLight, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingMD),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Customer Name
            Row(
              children: [
                Icon(
                  Icons.person_outline,
                  size: 20,
                  color: AppTheme.primaryBlue,
                ),
                const SizedBox(width: AppTheme.spacingSM),
                Expanded(
                  child: Text(
                    customerName,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingMD),

            // Location
            Row(
              children: [
                Icon(
                  Icons.location_on_outlined,
                  size: 18,
                  color: AppTheme.textSecondary,
                ),
                const SizedBox(width: AppTheme.spacingSM),
                Expanded(
                  child: Text(
                    project.location,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingLG),

            // Progress Bar
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Progress',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                    ),
                    Text(
                      _formatProgress(project.progress),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: _getProgressColor(progress),
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spacingXS),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                  child: LinearProgressIndicator(
                    value: (progress / 100).clamp(0.0, 1.0),
                    minHeight: 8,
                    backgroundColor: AppTheme.borderLight,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _getProgressColor(progress),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingMD),

            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, size: 20),
                  color: AppTheme.primaryBlue,
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
                  icon: const Icon(Icons.delete, size: 20),
                  color: AppTheme.statusError,
                  onPressed: () => _deleteProject(project),
                  tooltip: 'Delete',
                ),
              ],
            ),
          ],
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
