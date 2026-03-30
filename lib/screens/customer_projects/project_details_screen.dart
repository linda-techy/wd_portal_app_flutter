import 'package:flutter/material.dart';
import 'package:admin/theme/app_theme.dart';
import 'package:admin/theme/responsive_utils.dart';
import 'package:intl/intl.dart';
import 'package:admin/models/customer_project.dart';
import 'package:admin/features/leads/data/models/lead.dart';
import 'package:admin/services/crm_service.dart';
import 'project_documents_screen.dart';
import 'project_payments_screen.dart';
import 'design_package_selection_screen.dart';
import 'package:admin/features/warranties/presentation/screens/warranties_screen.dart';
import '../../features/boq/presentation/screens/boq_screen.dart';
import '../../features/quality/presentation/screens/quality_checks_screen.dart';
import '../../features/site_reports/presentation/screens/site_reports_screen.dart';

import 'package:admin/screens/projects/subcontract_work_orders_screen.dart';
import 'package:admin/features/finance/presentation/screens/billing_dashboard_screen.dart';
import 'package:admin/features/change_orders/presentation/screens/change_orders_screen.dart';
import 'package:admin/features/delays/presentation/screens/delay_logs_screen.dart';
import 'package:admin/features/feedback/presentation/screens/feedback_screen.dart';
import 'package:admin/features/gallery/presentation/screens/gallery_screen.dart';
import 'package:admin/features/observations/presentation/screens/observations_screen.dart';
import 'package:admin/screens/projects/view_360_list_screen.dart';
import 'package:admin/models/team_member.dart';
import 'package:admin/widgets/animations/entrance_animation.dart';
import 'package:admin/widgets/animations/motion_button.dart';
import 'package:admin/utils/error_handler.dart';
import 'package:admin/services/customer_project_service.dart';
import 'package:admin/features/customers/data/services/customer_service.dart';
import 'package:admin/features/customers/data/models/customer.dart';

class ProjectDetailsScreen extends StatefulWidget {
  final CustomerProject project;
  const ProjectDetailsScreen({super.key, required this.project});

  @override
  State<ProjectDetailsScreen> createState() => _ProjectDetailsScreenState();
}

class _ProjectDetailsScreenState extends State<ProjectDetailsScreen> {
  Lead? customerLead;

  // Master loading flag for Data-First pattern
  bool _isPageLoading = true;
  final CRMService _crmService = CRMService();
  final CustomerProjectService _projectService = CustomerProjectService();
  final CustomerService _customerService = CustomerService();

  List<Map<String, dynamic>> _projectMembers = [];
  bool _membersLoading = false;
  bool _isRecalculating = false;
  // Mutable copy so we can reflect refreshed progress without full page reload
  late CustomerProject _currentProject;

  @override
  void initState() {
    super.initState();
    _currentProject = widget.project;
    _loadCustomerLead();
    _loadProjectMembers();
  }

  Future<void> _recalculateProgress() async {
    if (widget.project.id == null || _isRecalculating) return;
    setState(() => _isRecalculating = true);
    try {
      final updated = await _projectService.recalculateProgress(widget.project.id!);
      if (mounted) {
        setState(() {
          _currentProject = updated;
          _isRecalculating = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Progress updated: ${updated.progress?.toStringAsFixed(1) ?? 0}%',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isRecalculating = false);
        ErrorHandler.showErrorSnackBar(context, e);
      }
    }
  }

  Future<void> _loadCustomerLead() async {
    if (widget.project.leadId == null) {
      setState(() {
        _isPageLoading = false;
      });
      return;
    }

    try {
      // Use optimized getLeadById instead of getAllLeads
      final lead = await _crmService.getLeadById(widget.project.leadId.toString());
      if (mounted) {
        setState(() {
          customerLead = lead;
          _isPageLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isPageLoading = false;
        });
        await ErrorHandler.handleApiError(context, e, defaultMessage: 'Failed to load lead details', showToast: false);
      }
    }
  }

  Future<void> _loadProjectMembers() async {
    if (widget.project.id == null) return;
    setState(() => _membersLoading = true);
    try {
      final members = await _projectService.getProjectMembers(widget.project.id!);
      if (mounted) {
        setState(() {
          _projectMembers = members;
          _membersLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _membersLoading = false);
    }
  }

  Future<void> _removeMember(int membershipId) async {
    if (widget.project.id == null) return;
    try {
      await _projectService.removeProjectMember(widget.project.id!, membershipId);
      _loadProjectMembers();
    } catch (e) {
      if (mounted) {
        ErrorHandler.showErrorSnackBar(context, e);
      }
    }
  }

  Future<void> _showAddMemberDialog() async {
    if (widget.project.id == null) return;

    final roleOptions = ['ARCHITECT', 'INTERIOR_DESIGNER', 'SITE_ENGINEER', 'VIEWER'];
    String selectedRole = roleOptions.first;
    Customer? selectedCustomer;
    List<Customer> allCustomers = [];
    String searchQuery = '';

    try {
      allCustomers = await _customerService.getAllCustomers();
    } catch (_) {}

    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final filtered = allCustomers
              .where((c) =>
                  searchQuery.isEmpty ||
                  c.fullName.toLowerCase().contains(searchQuery.toLowerCase()) ||
                  c.email.toLowerCase().contains(searchQuery.toLowerCase()))
              .toList();

          return AlertDialog(
            title: const Text('Add External Member'),
            content: SizedBox(
              width: 400,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<String>(
                    value: selectedRole,
                    decoration: const InputDecoration(labelText: 'Role'),
                    items: roleOptions
                        .map((r) => DropdownMenuItem(value: r, child: Text(r.replaceAll('_', ' '))))
                        .toList(),
                    onChanged: (v) => setDialogState(() => selectedRole = v ?? selectedRole),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Search Customer',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (v) => setDialogState(() => searchQuery = v),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 200,
                    child: ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (_, i) {
                        final c = filtered[i];
                        final isSelected = selectedCustomer?.id == c.id;
                        return ListTile(
                          selected: isSelected,
                          selectedTileColor: AppTheme.primaryBlue.withOpacity(0.1),
                          title: Text(c.fullName),
                          subtitle: Text(c.email),
                          onTap: () => setDialogState(() => selectedCustomer = c),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: selectedCustomer == null
                    ? null
                    : () async {
                        Navigator.pop(ctx);
                        try {
                          await _projectService.addProjectMember(
                              widget.project.id!, selectedCustomer!.id!, selectedRole);
                          _loadProjectMembers();
                        } catch (e) {
                          if (mounted) {
                            ErrorHandler.showErrorSnackBar(context, e);
                          }
                        }
                      },
                child: const Text('Add'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildExternalMembersSection() {
    return Card(
      elevation: 2,
      margin: EdgeInsets.symmetric(
        horizontal: ResponsiveUtils.responsiveValue(
          context: context,
          mobile: 0,
          tablet: AppTheme.spacingSM,
          desktop: AppTheme.spacingMD,
        ),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingMD),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'External Members',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                IconButton(
                  icon: const Icon(Icons.person_add_outlined, color: AppTheme.primaryBlue),
                  tooltip: 'Add External Member',
                  onPressed: _showAddMemberDialog,
                ),
              ],
            ),
            const Divider(),
            if (_membersLoading)
              const Center(child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ))
            else if (_projectMembers.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'No external members yet. Tap + to add architects, designers, or other 3rd-party viewers.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                ),
              )
            else
              ..._projectMembers.map((m) {
                final membershipId = m['id'] as int?;
                final name = m['fullName'] as String? ?? '';
                final email = m['email'] as String? ?? '';
                final role = (m['roleInProject'] as String? ?? '').replaceAll('_', ' ');
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: AppTheme.primaryBlue.withOpacity(0.1),
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                      style: const TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.bold),
                    ),
                  ),
                  title: Text(name),
                  subtitle: Text('$email\n$role'),
                  isThreeLine: true,
                  trailing: IconButton(
                    icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                    tooltip: 'Remove',
                    onPressed: membershipId != null ? () => _removeMember(membershipId) : null,
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return DateFormat('MMM dd, yyyy').format(date);
  }

  String _formatProgress(double? progress) {
    if (progress == null) return '0%';
    return '${progress.toStringAsFixed(1)}%';
  }

  Color _getProgressColor(double progress) {
    if (progress >= 80) return AppTheme.statusSuccess;
    if (progress >= 50) return AppTheme.safetyOrange;
    if (progress >= 25) return AppTheme.safetyYellow;
    return AppTheme.statusError;
  }

  String _getContractTypeLabel(String? type) {
    if (type == null) return 'N/A';
    switch (type) {
      case 'TURNKEY':
        return 'Turnkey (Material + Labor)';
      case 'LABOR_ONLY':
        return 'Labor Only';
      case 'ITEM_RATE':
        return 'Item Rate';
      case 'COST_PLUS':
        return 'Cost Plus';
      default:
        return type;
    }
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
        title: Text(
          widget.project.name,
          style: TextStyle(
            fontSize: ResponsiveUtils.responsiveFontSize(
              context,
              mobile: 18,
              tablet: 20,
              desktop: 22,
            ),
          ),
        ),
        elevation: 0,
        backgroundColor: AppTheme.surface,
      ),

      body: _isPageLoading 
          ? const Center(child: CircularProgressIndicator())
          : AdaptiveContainer(
        padding: ResponsiveUtils.responsivePadding(context),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: ResponsiveUtils.responsiveValue(
                context: context,
                mobile: AppTheme.spacingMD,
                tablet: AppTheme.spacingLG,
                desktop: AppTheme.spacingXL,
              )),
              
              // Project Overview Card
              EntranceAnimation(
                delay: const Duration(milliseconds: 0),
                child: _buildProjectOverviewCard(),
              ),
              
              SizedBox(height: ResponsiveUtils.responsiveValue(
                context: context,
                mobile: AppTheme.spacingLG,
                tablet: AppTheme.spacingXL,
                desktop: AppTheme.spacingXL,
              )),
              
              // Section Title
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: ResponsiveUtils.responsiveValue(
                    context: context,
                    mobile: 0,
                    tablet: AppTheme.spacingSM,
                    desktop: AppTheme.spacingMD,
                  ),
                ),
                child: EntranceAnimation(
                  delay: const Duration(milliseconds: 100),
                  child: Text(
                    'Project Modules',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: ResponsiveUtils.responsiveFontSize(
                            context,
                            mobile: 20,
                            tablet: 22,
                            desktop: 24,
                          ),
                        ),
                  ),
                ),
              ),
              
              SizedBox(height: ResponsiveUtils.responsiveValue(
                context: context,
                mobile: AppTheme.spacingMD,
                tablet: AppTheme.spacingLG,
                desktop: AppTheme.spacingLG,
              )),
              
              // External Members Section
              EntranceAnimation(
                delay: const Duration(milliseconds: 150),
                child: _buildExternalMembersSection(),
              ),

              SizedBox(height: ResponsiveUtils.responsiveValue(
                context: context,
                mobile: AppTheme.spacingLG,
                tablet: AppTheme.spacingXL,
                desktop: AppTheme.spacingXL,
              )),

              // Clickable Tiles Grid
              _buildModulesGrid(),

              SizedBox(height: ResponsiveUtils.responsiveValue(
                context: context,
                mobile: AppTheme.spacingXL,
                tablet: AppTheme.spacingXL,
                desktop: AppTheme.spacingXL * 1.5,
              )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProjectOverviewCard() {
    final progress = _currentProject.progress ?? 0.0;
    
    return Card(
      elevation: 2,
      margin: EdgeInsets.symmetric(
        horizontal: ResponsiveUtils.responsiveValue(
          context: context,
          mobile: 0,
          tablet: AppTheme.spacingSM,
          desktop: AppTheme.spacingMD,
        ),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
      ),
      child: Padding(
        padding: EdgeInsets.all(ResponsiveUtils.responsiveValue(
          context: context,
          mobile: AppTheme.spacingMD,
          tablet: AppTheme.spacingLG,
          desktop: AppTheme.spacingXL,
        )),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Project Name
            Text(
              widget.project.name,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: ResponsiveUtils.responsiveFontSize(
                      context,
                      mobile: 20,
                      tablet: 22,
                      desktop: 24,
                    ),
                  ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: ResponsiveUtils.responsiveValue(
              context: context,
              mobile: AppTheme.spacingSM,
              tablet: AppTheme.spacingMD,
              desktop: AppTheme.spacingMD,
            )),
            
            // Customer Name
             if (customerLead != null)
              Row(
                children: [
                  const Icon(Icons.person_outline, 
                    size: 20, 
                    color: AppTheme.primaryBlue,
                  ),
                  const SizedBox(width: AppTheme.spacingSM),
                  Text(
                    customerLead!.name,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            const SizedBox(height: AppTheme.spacingMD),

            // Project Manager
            if (widget.project.projectManagerId != null && widget.project.teamMembers != null) ...[
              Builder(
                builder: (context) {
                  TeamMember? projectManager;
                   try {
                    projectManager = widget.project.teamMembers!.firstWhere(
                      (m) => m.id == widget.project.projectManagerId.toString() && m.type == 'PORTAL',
                    );
                  } catch (_) {}
                  
                  if (projectManager == null) return const SizedBox.shrink();

                  return Column(
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.manage_accounts_outlined, 
                            size: 20, 
                            color: AppTheme.primaryBlue,
                          ),
                          const SizedBox(width: AppTheme.spacingSM),
                          Text(
                            'Manager: ${projectManager.firstName} ${projectManager.lastName}',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppTheme.textSecondary,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppTheme.spacingMD),
                    ],
                  );
                }
              ),
            ],

            
            // Location
            Row(
              children: [
                const Icon(Icons.location_on_outlined,
                  size: 20,
                  color: AppTheme.textSecondary,
                ),
                const SizedBox(width: AppTheme.spacingSM),
                Expanded(
                  child: Text(
                    widget.project.location,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingMD),

            // GPS Coordinates
            if (widget.project.latitude != null && widget.project.longitude != null)
              Row(
                children: [
                  const Icon(Icons.gps_fixed_outlined,
                    size: 20,
                    color: AppTheme.textSecondary,
                  ),
                  const SizedBox(width: AppTheme.spacingSM),
                  Text(
                    'GPS: ${widget.project.latitude!.toStringAsFixed(6)}, ${widget.project.longitude!.toStringAsFixed(6)}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                  ),
                ],
              ),
            if (widget.project.latitude != null && widget.project.longitude != null)
              const SizedBox(height: AppTheme.spacingMD),
            
            // Project Code
            if (widget.project.code != null && widget.project.code!.isNotEmpty)
              Row(
                children: [
                  const Icon(Icons.tag_outlined,
                    size: 20,
                    color: AppTheme.textSecondary,
                  ),
                  const SizedBox(width: AppTheme.spacingSM),
                  Text(
                    'Code: ${widget.project.code}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                  ),
                ],
              ),
            if (widget.project.code != null && widget.project.code!.isNotEmpty)
              const SizedBox(height: AppTheme.spacingMD),

            // Contract Type
            if (widget.project.contractType != null)
              Row(
                children: [
                  const Icon(Icons.handshake_outlined,
                    size: 20,
                    color: AppTheme.textSecondary,
                  ),
                  const SizedBox(width: AppTheme.spacingSM),
                  Text(
                    'Contract: ${_getContractTypeLabel(widget.project.contractType)}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                  ),
                ],
              ),
            if (widget.project.contractType != null)
              const SizedBox(height: AppTheme.spacingMD),

            // Construction Details
            if (widget.project.plotArea != null || widget.project.floors != null)
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(Icons.square_foot,
                          size: 20,
                          color: AppTheme.textSecondary,
                        ),
                        const SizedBox(width: AppTheme.spacingSM),
                        Text(
                          'Plot: ${widget.project.plotArea ?? '-'} sq ft',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppTheme.textSecondary,
                              ),
                        ),
                      ],
                    ),
                  ),
                  if (widget.project.floors != null)
                    Expanded(
                      child: Row(
                        children: [
                          const Icon(Icons.layers,
                            size: 20,
                            color: AppTheme.textSecondary,
                          ),
                          const SizedBox(width: AppTheme.spacingSM),
                          Text(
                            'Floors: ${widget.project.floors}',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppTheme.textSecondary,
                                ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            if (widget.project.plotArea != null || widget.project.floors != null)
              const SizedBox(height: AppTheme.spacingMD),

            if (widget.project.facing != null || widget.project.permitStatus != null)
              Row(
                children: [
                  if (widget.project.facing != null)
                    Expanded(
                      child: Row(
                        children: [
                          const Icon(Icons.compass_calibration,
                            size: 20,
                            color: AppTheme.textSecondary,
                          ),
                          const SizedBox(width: AppTheme.spacingSM),
                          Text(
                            'Facing: ${widget.project.facing}',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppTheme.textSecondary,
                                ),
                          ),
                        ],
                      ),
                    ),
                  if (widget.project.permitStatus != null)
                    Expanded(
                      child: Row(
                        children: [
                          const Icon(Icons.approval,
                            size: 20,
                            color: AppTheme.textSecondary,
                          ),
                          const SizedBox(width: AppTheme.spacingSM),
                          Text(
                            'Permit: ${widget.project.permitStatus}',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppTheme.textSecondary,
                                ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            if (widget.project.facing != null || widget.project.permitStatus != null)
              const SizedBox(height: AppTheme.spacingMD),

            if (widget.project.projectDescription != null &&
                widget.project.projectDescription!.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Description',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: AppTheme.spacingXS),
                  Text(
                    widget.project.projectDescription!,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: AppTheme.spacingMD),
                ],
              ),
            
            // Dates - Responsive layout
            ResponsiveLayout(
              mobile: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Start Date',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                      ),
                      const SizedBox(height: AppTheme.spacingXS),
                      Text(
                        _formatDate(widget.project.startDate),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                  SizedBox(height: ResponsiveUtils.responsiveValue(
                    context: context,
                    mobile: AppTheme.spacingMD,
                    tablet: AppTheme.spacingMD,
                    desktop: 0,
                  )),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'End Date',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                      ),
                      const SizedBox(height: AppTheme.spacingXS),
                      Text(
                        _formatDate(widget.project.endDate),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                ],
              ),
              desktop: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Start Date',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppTheme.textSecondary,
                              ),
                        ),
                        const SizedBox(height: AppTheme.spacingXS),
                        Text(
                          _formatDate(widget.project.startDate),
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'End Date',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppTheme.textSecondary,
                              ),
                        ),
                        const SizedBox(height: AppTheme.spacingXS),
                        Text(
                          _formatDate(widget.project.endDate),
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.spacingMD),
            
            if (widget.project.isDesignAgreementSigned)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Progress',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      Text(
                        _formatProgress(_currentProject.progress),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: _getProgressColor(progress),
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacingSM),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                    child: LinearProgressIndicator(
                      value: (progress / 100).clamp(0.0, 1.0),
                      minHeight: 10,
                      backgroundColor: AppTheme.borderLight,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _getProgressColor(progress),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingSM),
                  // Recalculate Progress Button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _isRecalculating ? null : _recalculateProgress,
                      icon: _isRecalculating
                          ? const SizedBox(
                              width: 16, height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.refresh, size: 18),
                      label: Text(_isRecalculating ? 'Recalculating...' : 'Recalculate Progress'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        side: const BorderSide(color: AppTheme.primaryBlue),
                        foregroundColor: AppTheme.primaryBlue,
                      ),
                    ),
                  ),
                ],
              )
            else if (widget.project.projectPhase?.toLowerCase() == 'design')
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DesignPackageSelectionScreen(
                          project: widget.project,
                        ),
                      ),
                    );
                    if (result == true) {
                      // Optionally reload data if needed
                      if (mounted) setState(() {});
                    }
                  },
                  icon: const Icon(Icons.design_services, size: 18),
                  label: const Text('Action Required: Select Package & Sign Agreement'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: const BorderSide(color: AppTheme.coralRed),
                    foregroundColor: AppTheme.coralRed,
                  ),
                ),
              )
            else
              const SizedBox(height: 20), // Placeholder if neither applies
            
            // Project Phase
            if (widget.project.projectPhase != null && 
                widget.project.projectPhase!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: AppTheme.spacingMD),
                child: Row(
                  children: [
                    const Icon(Icons.construction_outlined,
                      size: 20,
                      color: AppTheme.textSecondary,
                    ),
                    const SizedBox(width: AppTheme.spacingSM),
                    Text(
                      'Phase: ${widget.project.projectPhase}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildModulesGrid() {
    final modules = [
      _ModuleTile(
        title: 'Documents',
        icon: Icons.description_outlined,
        color: AppTheme.primaryBlue,
        onTap: () {
          _navigateToModule('Documents', widget.project);
        },
      ),
      _ModuleTile(
        title: 'Payments',
        icon: Icons.payment_outlined,
        color: AppTheme.statusSuccess,
        onTap: () {
          _navigateToModule('Payments', widget.project);
        },
      ),
      _ModuleTile(
        title: 'BoQ',
        icon: Icons.receipt_long_outlined,
        color: AppTheme.safetyOrange,
        onTap: () {
          _navigateToModule('BoQ', widget.project);
        },
      ),
      _ModuleTile(
        title: 'Billing',
        icon: Icons.attach_money,
        color: AppTheme.primaryBlue,
        onTap: () {
          _navigateToModule('Billing', widget.project);
        },
      ),
      _ModuleTile(
        title: 'Change Orders',
         icon: Icons.edit_note_outlined,
         color: AppTheme.coralRed,
         onTap: () {
           _navigateToModule('Change Orders', widget.project);
         },

      ),
      _ModuleTile(
        title: 'Warranties',
        icon: Icons.verified_user_outlined,
        color: AppTheme.primaryBlue,
        onTap: () {
          _navigateToModule('Warranties', widget.project);
        },

      ),
      _ModuleTile(
        title: 'Delay Logs',
        icon: Icons.timer_off_outlined,
        color: AppTheme.safetyOrange,
        onTap: () {
          _navigateToModule('Delay Logs', widget.project);
        },

      ),
      _ModuleTile(
        title: 'Quality Check',
        icon: Icons.verified_outlined,
        color: AppTheme.safetyYellow,
        onTap: () {
          _navigateToModule('Quality Check', widget.project);
        },

      ),
      _ModuleTile(
        title: 'Feedback',
        icon: Icons.feedback_outlined,
        color: AppTheme.skyBlue,
        onTap: () {
          _navigateToModule('Feedback', widget.project);
        },
      ),
      _ModuleTile(
        title: 'Gallery',
        icon: Icons.photo_library_outlined,
        color: AppTheme.coralRed,
        onTap: () {
          _navigateToModule('Gallery', widget.project);
        },
      ),
      _ModuleTile(
        title: 'Snags',
        icon: Icons.warning_amber_rounded,
        color: AppTheme.constructionOrange,
        onTap: () {
          _navigateToModule('Snags', widget.project);
        },
      ),
      _ModuleTile(
        title: '360° Views',
        icon: Icons.vrpano_outlined,
        color: AppTheme.primaryBlue,
        onTap: () {
          _navigateToModule('360 Views', widget.project);
        },
      ),
      _ModuleTile(
        title: 'Site Reports',
        icon: Icons.assignment_outlined,
        color: AppTheme.primaryBlue,
        onTap: () {
          _navigateToModule('Site Reports', widget.project);
        },

      ),
      _ModuleTile(
        title: 'Subcontracts',
        icon: Icons.handshake_outlined,
        color: AppTheme.skyBlue,
        onTap: () {
          _navigateToModule('Subcontracts', widget.project);
        },

      ),
    ];

    return ResponsiveLayout(
      mobile: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: ResponsiveUtils.responsiveValue(
            context: context,
            mobile: AppTheme.spacingSM,
            tablet: 0,
            desktop: 0,
          ),
        ),
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: ResponsiveUtils.responsiveValue(
              context: context,
              mobile: AppTheme.spacingMD,
              tablet: AppTheme.spacingLG,
              desktop: AppTheme.spacingMD,
            ),
            mainAxisSpacing: ResponsiveUtils.responsiveValue(
              context: context,
              mobile: AppTheme.spacingMD,
              tablet: AppTheme.spacingLG,
              desktop: AppTheme.spacingMD,
            ),
            childAspectRatio: 1.4,
          ),
          itemCount: modules.length,
          itemBuilder: (context, index) => EntranceAnimation(
            delay: Duration(milliseconds: 150 + (index * 50)),
            child: modules[index],
          ),
        ),
      ),
      tablet: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: ResponsiveUtils.responsiveValue(
            context: context,
            mobile: 0,
            tablet: AppTheme.spacingSM,
            desktop: 0,
          ),
        ),
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: ResponsiveUtils.responsiveValue(
              context: context,
              mobile: AppTheme.spacingMD,
              tablet: AppTheme.spacingLG,
              desktop: AppTheme.spacingMD,
            ),
            mainAxisSpacing: ResponsiveUtils.responsiveValue(
              context: context,
              mobile: AppTheme.spacingMD,
              tablet: AppTheme.spacingLG,
              desktop: AppTheme.spacingMD,
            ),
            childAspectRatio: ResponsiveUtils.responsiveValue(
              context: context,
              mobile: 1.5,
              tablet: 1.4,
              desktop: 1.5,
            ),
          ),
          itemCount: modules.length,
          itemBuilder: (context, index) => EntranceAnimation(
            delay: Duration(milliseconds: 150 + (index * 50)),
            child: modules[index],
          ),
        ),
      ),
      desktop: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: ResponsiveUtils.responsiveValue(
            context: context,
            mobile: 0,
            tablet: 0,
            desktop: AppTheme.spacingSM,
          ),
        ),
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: ResponsiveUtils.isLargeDesktop(context) ? 4 : 3,
            crossAxisSpacing: ResponsiveUtils.responsiveValue(
              context: context,
              mobile: AppTheme.spacingMD,
              tablet: AppTheme.spacingMD,
              desktop: AppTheme.spacingLG,
            ),
            mainAxisSpacing: ResponsiveUtils.responsiveValue(
              context: context,
              mobile: AppTheme.spacingMD,
              tablet: AppTheme.spacingMD,
              desktop: AppTheme.spacingLG,
            ),
            childAspectRatio: ResponsiveUtils.responsiveValue(
              context: context,
              mobile: 1.5,
              tablet: 1.5,
              desktop: ResponsiveUtils.isLargeDesktop(context) ? 1.3 : 1.5,
            ),
          ),
          itemCount: modules.length,
          itemBuilder: (context, index) => EntranceAnimation(
            delay: Duration(milliseconds: 150 + (index * 50)),
            child: modules[index],
          ),
        ),
      ),
    );
  }

  void _navigateToModule(String moduleName, CustomerProject project) {
    if (moduleName == 'Documents') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProjectDocumentsScreen(project: project),
        ),
      );
    } else if (moduleName == 'Payments') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProjectPaymentsScreen(project: project),
        ),
      );
    } else if (moduleName == 'Billing') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => Scaffold(
            appBar: AppBar(title: const Text('Billing Dashboard')),
            body: BillingDashboardScreen(projectId: widget.project.id!),
          ),
        ),
      );
    } else if (moduleName == 'Warranties') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => Scaffold(
             appBar: AppBar(title: const Text('Warranties')),
             body: WarrantiesScreen(projectId: widget.project.id!),
          ),
        ),
      );
    } else if (moduleName == 'Delay Logs') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => Scaffold(
             appBar: AppBar(title: const Text('Delay Logs')),
             body: DelayLogsScreen(projectId: widget.project.id!),
          ),
        ),
      );
    } else if (moduleName == 'Change Orders') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => Scaffold(
             appBar: AppBar(title: const Text('Change Orders')),
             body: ChangeOrdersScreen(projectId: widget.project.id!),
          ),
        ),
      );
    } else if (moduleName == 'Subcontracts') {
       Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SubcontractWorkOrdersScreen(
             projectId: widget.project.id!,
             projectName: widget.project.name,
          ),
        ),
      );
    } else if (moduleName == 'BoQ') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => BoqScreen(projectId: widget.project.id!),
        ),
      );
    } else if (moduleName == 'Site Reports') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SiteReportsScreen(projectId: widget.project.id!),
        ),
      );
    } else if (moduleName == 'Quality Check') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => QualityChecksScreen(projectId: widget.project.id!),
        ),
      );
    } else if (moduleName == 'Feedback') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FeedbackScreen(projectId: widget.project.id!),
        ),
      );
    } else if (moduleName == 'Gallery') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => GalleryScreen(projectId: widget.project.id!),
        ),
      );
    } else if (moduleName == 'Snags') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ObservationsScreen(projectId: widget.project.id!),
        ),
      );
    } else if (moduleName == '360 Views') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => View360ListScreen(
            projectId: widget.project.id!,
            projectName: widget.project.name,
          ),
        ),
      );
    } else {
      // Show a "Coming Soon" SnackBar for unimplemented modules
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '$moduleName is coming soon! This feature is being developed and will be available shortly.',
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
          backgroundColor: AppTheme.primaryBlue,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }


}

class _ModuleTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ModuleTile({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return MotionButton(
      onPressed: onTap,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.radiusMD),
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(AppTheme.radiusMD),
              border: Border.all(
                color: AppTheme.borderLight,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.all(ResponsiveUtils.responsiveValue(
                context: context,
                mobile: AppTheme.spacingMD,
                tablet: AppTheme.spacingLG,
                desktop: AppTheme.spacingXL,
              )),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.all(ResponsiveUtils.responsiveValue(
                      context: context,
                      mobile: AppTheme.spacingSM,
                      tablet: AppTheme.spacingMD,
                      desktop: AppTheme.spacingMD,
                    )),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      size: ResponsiveUtils.responsiveFontSize(
                        context,
                        mobile: 28,
                        tablet: 32,
                        desktop: 36,
                      ),
                      color: color,
                    ),
                  ),
                  SizedBox(height: ResponsiveUtils.responsiveValue(
                    context: context,
                    mobile: AppTheme.spacingSM,
                    tablet: AppTheme.spacingMD,
                    desktop: AppTheme.spacingMD,
                  )),
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: ResponsiveUtils.responsiveFontSize(
                            context,
                            mobile: 14,
                            tablet: 16,
                            desktop: 18,
                          ),
                        ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}


