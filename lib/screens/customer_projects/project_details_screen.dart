import 'package:flutter/material.dart';
import 'package:admin/theme/app_theme.dart';
import 'package:admin/theme/responsive_utils.dart';
import 'package:admin/models/customer_project.dart';
import 'package:admin/features/leads/data/models/lead.dart';
import 'package:admin/services/crm_service.dart';
import 'project_documents_screen.dart';
import 'package:intl/intl.dart';

class ProjectDetailsScreen extends StatefulWidget {
  final CustomerProject project;

  const ProjectDetailsScreen({
    super.key,
    required this.project,
  });

  @override
  State<ProjectDetailsScreen> createState() => _ProjectDetailsScreenState();
}

class _ProjectDetailsScreenState extends State<ProjectDetailsScreen> {
  Lead? customerLead;
  bool isLoadingLead = true;
  final CRMService _crmService = CRMService();

  @override
  void initState() {
    super.initState();
    _loadCustomerLead();
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
              SizedBox(height: ResponsiveUtils.responsiveValue(
                context: context,
                mobile: AppTheme.spacingMD,
                tablet: AppTheme.spacingLG,
                desktop: AppTheme.spacingXL,
              )),
              
              // Project Overview Card
              _buildProjectOverviewCard(),
              
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
                    color: AppTheme.textSecondary,
                  ),
                  const SizedBox(width: AppTheme.spacingSM),
                  Text(
                    customerLead!.name,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            const SizedBox(height: AppTheme.spacingMD),
            
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
            
            // Progress
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
            ),
            
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
        title: 'Quality Check',
        icon: Icons.verified_outlined,
        color: AppTheme.safetyYellow,
        onTap: () {
          _navigateToModule('Quality Check', widget.project);
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
    ];

    return ResponsiveLayout(
      mobile: Column(
        children: modules.map((module) => Padding(
          padding: EdgeInsets.only(
            bottom: ResponsiveUtils.responsiveValue(
              context: context,
              mobile: AppTheme.spacingMD,
              tablet: AppTheme.spacingLG,
              desktop: AppTheme.spacingMD,
            ),
          ),
          child: module,
        )).toList(),
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
          itemBuilder: (context, index) => modules[index],
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
          itemBuilder: (context, index) => modules[index],
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
    return Material(
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
    );
  }
}

