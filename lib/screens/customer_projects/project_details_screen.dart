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

import 'package:admin/screens/projects/subcontract_work_orders_screen.dart';
import 'package:admin/models/project_summary.dart';
import 'package:admin/features/change_orders/presentation/screens/change_orders_screen.dart';
import 'package:admin/features/delays/presentation/screens/delay_logs_screen.dart';
import 'package:admin/models/team_member.dart';
import 'package:admin/widgets/animations/entrance_animation.dart';
import 'package:admin/widgets/animations/motion_button.dart';

class ProjectDetailsScreen extends StatefulWidget {
  final CustomerProject project;
  const ProjectDetailsScreen({super.key, required this.project});

  @override
  State<ProjectDetailsScreen> createState() => _ProjectDetailsScreenState();
}

class _ProjectDetailsScreenState extends State<ProjectDetailsScreen> {
  Lead? customerLead;
  ProjectSummary? _projectSummary;
  bool isLoadingLead = true;
  bool isLoadingSummary = true;
  final CRMService _crmService = CRMService();

  @override
  void initState() {
    super.initState();
    _loadCustomerLead();
    _loadProjectSummary();
  }

  Future<void> _loadProjectSummary() async {
    try {
      final summary = await _crmService.getProject360(widget.project.id!);
      if (mounted) {
        setState(() {
          _projectSummary = summary;
          isLoadingSummary = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoadingSummary = false;
        });
        // Optionally show error snackbar
      }
    }
  }

  Future<void> _loadCustomerLead() async {
    if (widget.project.leadId == null) {
      setState(() {
        isLoadingLead = false;
      });
      return;
    }

    try {
      final leads = await _crmService.getAllLeads();
      final lead = leads.firstWhere(
        (l) => int.tryParse(l.leadId) == widget.project.leadId,
        orElse: () => leads.first,
      );
      if (mounted) {
        setState(() {
          customerLead = lead;
          isLoadingLead = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoadingLead = false;
        });
      }
    }
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
      body: AdaptiveContainer(
        padding: ResponsiveUtils.responsivePadding(context),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 360 Dashboard
              if (_projectSummary != null) ...[
                _build360Dashboard(),
                const SizedBox(height: 24),
              ],
              if (isLoadingSummary)
                 const Center(child: CircularProgressIndicator()),
                 
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
    final progress = widget.project.progress ?? 0.0;
    
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
            if (isLoadingLead)
              const LinearProgressIndicator()
            else if (customerLead != null)
              Row(
                children: [
                  Icon(Icons.person_outline, 
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
                          Icon(Icons.manage_accounts_outlined, 
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
                Icon(Icons.location_on_outlined,
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
                  Icon(Icons.gps_fixed_outlined,
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
                  Icon(Icons.tag_outlined,
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
                  Icon(Icons.handshake_outlined,
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
                        Icon(Icons.square_foot,
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
                          Icon(Icons.layers,
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
                          Icon(Icons.compass_calibration,
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
                          Icon(Icons.approval,
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
                        _formatProgress(widget.project.progress),
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
                    Icon(Icons.construction_outlined,
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
        title: 'Change Orders',
         icon: Icons.edit_note_outlined,
         color: AppTheme.coralRed,
         onTap: () {
           _navigateToModule('Change Orders', widget.project);
         },
        projectSummary: _projectSummary,
      ),
      _ModuleTile(
        title: 'Warranties',
        icon: Icons.verified_user_outlined,
        color: AppTheme.primaryBlue,
        onTap: () {
          _navigateToModule('Warranties', widget.project);
        },
        projectSummary: _projectSummary,
      ),
      _ModuleTile(
        title: 'Delay Logs',
        icon: Icons.timer_off_outlined,
        color: AppTheme.safetyOrange,
        onTap: () {
          _navigateToModule('Delay Logs', widget.project);
        },
        projectSummary: _projectSummary,
      ),
      _ModuleTile(
        title: 'Quality Check',
        icon: Icons.verified_outlined,
        color: AppTheme.safetyYellow,
        onTap: () {
          _navigateToModule('Quality Check', widget.project);
        },
        projectSummary: _projectSummary,
      ),
      _ModuleTile(
        title: 'Site Reports',
        icon: Icons.assignment_outlined,
        color: AppTheme.primaryBlue,
        onTap: () {
          _navigateToModule('Site Reports', widget.project);
        },
        projectSummary: _projectSummary,
      ),
      _ModuleTile(
        title: 'Subcontracts',
        icon: Icons.handshake_outlined,
        color: AppTheme.skyBlue,
        onTap: () {
          _navigateToModule('Subcontracts', widget.project);
        },
        projectSummary: _projectSummary,
      ),
    ];

    return ResponsiveLayout(
      mobile: Column(
        children: modules.asMap().entries.map((entry) {
          final index = entry.key;
          final module = entry.value;
          return EntranceAnimation(
            delay: Duration(milliseconds: 150 + (index * 50)),
            child: Padding(
              padding: EdgeInsets.only(
                bottom: ResponsiveUtils.responsiveValue(
                  context: context,
                  mobile: AppTheme.spacingMD,
                  tablet: AppTheme.spacingLG,
                  desktop: AppTheme.spacingMD,
                ),
              ),
              child: module,
            ),
          );
        }).toList(),
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
    } else if (moduleName == 'Warranties') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => Scaffold(
             appBar: AppBar(title: Text('Warranties')),
             body: WarrantiesScreen(projectId: widget.project.id!),
          ),
        ),
      );
    } else if (moduleName == 'Delay Logs') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => Scaffold(
             appBar: AppBar(title: Text('Delay Logs')),
             body: DelayLogsScreen(projectId: widget.project.id!),
          ),
        ),
      );
    } else if (moduleName == 'Change Orders') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => Scaffold(
             appBar: AppBar(title: Text('Change Orders')),
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
    } else {
      // Show a placeholder dialog for other modules
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(moduleName),
          content: Text('${moduleName} module for "${project.name}" will be implemented soon.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  Widget _build360Dashboard() {
    final stats = _projectSummary!.executionStats;
    final finance = _projectSummary!.financialSnapshot;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Project 360° View',
            style: AppTheme.headlineMedium.copyWith(color: AppTheme.primaryBlue),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildStatCard('Tasks', '${stats.completedTasks}/${stats.totalTasks}', Icons.check_circle_outline, Colors.green)),
              const SizedBox(width: 8),
              Expanded(child: _buildStatCard('Delays', '${stats.activeDelays}', Icons.warning_amber_rounded, Colors.red)),
              const SizedBox(width: 8),
              Expanded(child: _buildStatCard('Budget', '\$${companyFormat(finance.totalBudget)}', Icons.attach_money, Colors.blue)),
            ],
          ),
        ],
      ),
    );
  }

  String companyFormat(double value) {
    return value.toStringAsFixed(2);
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color)),
          Text(title, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
        ],
      ),
    );
  }
}

class _ModuleTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final ProjectSummary? projectSummary;

  const _ModuleTile({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
    this.projectSummary,
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

