import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:admin/features/projects/data/models/project_model.dart';
import 'package:admin/models/customer_project.dart';
import 'package:admin/services/customer_project_service.dart';
import 'package:admin/theme/app_theme.dart';
import 'package:admin/theme/responsive_utils.dart';
import 'gantt_screen.dart';

// Module target screens (live flow from the legacy customer_projects path,
// ported here so the new features/ detail screen offers the same module grid).
import 'package:admin/screens/customer_projects/project_documents_screen.dart';
import 'package:admin/screens/customer_projects/project_payments_screen.dart';
import 'package:admin/features/warranties/presentation/screens/warranties_screen.dart';
import 'package:admin/features/boq/presentation/screens/boq_screen.dart';
import 'package:admin/features/boq/presentation/screens/payment_schedule_screen.dart';
import 'package:admin/features/boq/presentation/screens/co_management_screen.dart';
import 'package:admin/features/boq/presentation/screens/boq_invoice_screen.dart';
import 'package:admin/features/quality/presentation/screens/quality_checks_screen.dart';
import 'package:admin/features/site_reports/presentation/screens/site_reports_screen.dart';
import 'package:admin/screens/projects/subcontract_work_orders_screen.dart';
import 'package:admin/features/delays/presentation/screens/delay_logs_screen.dart';
import 'package:admin/features/feedback/presentation/screens/feedback_screen.dart';
import 'package:admin/features/gallery/presentation/screens/gallery_screen.dart';
import 'package:admin/features/observations/presentation/screens/observations_screen.dart';
import 'package:admin/screens/projects/view_360_list_screen.dart';
import 'package:admin/features/variation_orders/presentation/screens/vo_list_screen.dart';
import 'package:admin/features/stage_payments/presentation/screens/stage_payment_screen.dart';
import 'package:admin/features/deductions/presentation/screens/deduction_register_screen.dart';
import 'package:admin/features/final_account/presentation/screens/final_account_screen.dart';

class ProjectDetailScreen extends StatefulWidget {
  final ProjectModel project;

  const ProjectDetailScreen({super.key, required this.project});

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen> {
  static const List<String> _phases = [
    'PLANNING',
    'DESIGN',
    'CONSTRUCTION',
    'COMPLETED',
    'ON_HOLD',
  ];
  static const Map<String, String> _phaseLabels = {
    'PLANNING': 'Planning',
    'DESIGN': 'Design',
    'CONSTRUCTION': 'Construction',
    'COMPLETED': 'Completed',
    'ON_HOLD': 'On Hold',
  };

  late ProjectModel project = widget.project;
  late String? _currentPhase = widget.project.projectPhase;
  bool _savingPhase = false;

  /// Adapter for legacy module screens that still accept CustomerProject.
  CustomerProject _asCustomerProject() => CustomerProject(
        id: project.id,
        name: project.name,
        location: project.location,
        startDate: project.startDate,
        endDate: project.endDate,
        progress: project.overallProgress,
        projectPhase: project.projectPhase,
        sqfeet: project.sqfeet,
        customerId: project.customerId,
        code: project.code,
        projectType: project.projectType,
      );

  Future<void> _editPhase() async {
    final selected = await showDialog<String>(
      context: context,
      builder: (ctx) {
        return SimpleDialog(
          title: const Text('Change project phase'),
          children: _phases.map((p) {
            final label = _phaseLabels[p] ?? p;
            final isCurrent = (project.projectPhase ?? '').toUpperCase() == p;
            return SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, p),
              child: Row(
                children: [
                  Icon(
                    isCurrent ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                    size: 18,
                    color: isCurrent ? AppTheme.deepSlate : Colors.grey,
                  ),
                  const SizedBox(width: 12),
                  Text(label, style: TextStyle(
                    fontWeight: isCurrent ? FontWeight.w600 : FontWeight.normal,
                  )),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
    if (selected == null || selected == (project.projectPhase ?? '').toUpperCase()) return;

    setState(() => _savingPhase = true);
    try {
      final cp = _asCustomerProject();
      // Send only the changed phase plus identifiers; the service's toUpdateJson
      // serialises the whole CustomerProject — set the new phase first.
      final updated = await CustomerProjectService().updateProject(
        project.id!,
        CustomerProject(
          id: cp.id,
          name: cp.name,
          location: cp.location,
          startDate: cp.startDate,
          endDate: cp.endDate,
          progress: cp.progress,
          projectPhase: selected,
          sqfeet: cp.sqfeet,
          customerId: cp.customerId,
          code: cp.code,
          projectType: cp.projectType,
        ),
      );
      if (!mounted) return;
      setState(() {
        _currentPhase = updated.projectPhase ?? selected;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Phase changed to ${_phaseLabels[selected] ?? selected}'),
        backgroundColor: Colors.green,
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Failed to change phase: $e'),
        backgroundColor: Colors.red,
      ));
    } finally {
      if (mounted) setState(() => _savingPhase = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(project.code ?? project.name),
        actions: [
          if (project.id != null)
            IconButton(
              icon: const Icon(Icons.view_timeline_outlined),
              tooltip: 'Gantt Timeline',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => GanttScreen(
                    projectId: project.id!,
                    projectName: project.name,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderCard(context),
            const SizedBox(height: 16),
            if (project.overallProgress != null) ...[
              _buildProgressCard(context),
              const SizedBox(height: 16),
            ],
            _buildDetailsCard(context),
            if (project.budget != null || project.sqfeet != null) ...[
              const SizedBox(height: 16),
              _buildFinancialsCard(context),
            ],
            if (project.id != null) ...[
              const SizedBox(height: 24),
              _buildModulesSection(context),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              project.name,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            if (project.code != null) ...[
              const SizedBox(height: 4),
              Text(project.code!, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                // Tappable: opens phase picker. Edit icon hints at it; while
                // saving, the chip swaps to a small spinner so users don't
                // double-tap.
                InkWell(
                  onTap: _savingPhase ? null : _editPhase,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.deepSlate,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _phaseLabels[(_currentPhase ?? '').toUpperCase()] ??
                              _currentPhase ?? 'Set phase',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(width: 6),
                        if (_savingPhase)
                          const SizedBox(
                            width: 12, height: 12,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        else
                          const Icon(Icons.edit, size: 12, color: Colors.white70),
                      ],
                    ),
                  ),
                ),
                if (project.projectStatus != null)
                  _buildChip(
                    label: project.projectStatus!,
                    backgroundColor: _statusColor(project.projectStatus!).withOpacity(0.15),
                    textColor: _statusColor(project.projectStatus!),
                    borderColor: _statusColor(project.projectStatus!),
                  ),
                if (project.projectType != null)
                  _buildChip(
                    label: project.projectType!,
                    backgroundColor: Colors.grey[200]!,
                    textColor: Colors.grey[800]!,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressCard(BuildContext context) {
    final progress = project.overallProgress!;
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Overall Progress', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                Text(
                  '${progress.toStringAsFixed(1)}%',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: _progressColor(progress)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (progress / 100).clamp(0.0, 1.0),
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(_progressColor(progress)),
                minHeight: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsCard(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy');
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Project Details', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            const Divider(height: 20),
            _buildDetailRow(icon: Icons.location_on, label: 'Location', value: project.location),
            if (project.customerName != null) ...[
              const SizedBox(height: 12),
              _buildDetailRow(icon: Icons.person, label: 'Customer', value: project.customerName!),
            ],
            if (project.startDate != null) ...[
              const SizedBox(height: 12),
              _buildDetailRow(icon: Icons.calendar_today, label: 'Start Date', value: dateFormat.format(project.startDate!)),
            ],
            if (project.endDate != null) ...[
              const SizedBox(height: 12),
              _buildDetailRow(icon: Icons.event, label: 'End Date', value: dateFormat.format(project.endDate!)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFinancialsCard(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 0);
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Financials & Specs', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            const Divider(height: 20),
            if (project.budget != null)
              _buildDetailRow(icon: Icons.currency_rupee, label: 'Budget', value: currencyFormat.format(project.budget!)),
            if (project.sqfeet != null) ...[
              if (project.budget != null) const SizedBox(height: 12),
              _buildDetailRow(icon: Icons.square_foot, label: 'Area', value: '${project.sqfeet!.toStringAsFixed(0)} sq.ft'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow({required IconData icon, required String label, required String value}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.grey[600]),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontSize: 14)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChip({
    required String label,
    required Color backgroundColor,
    required Color textColor,
    Color? borderColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: borderColor != null ? Border.all(color: borderColor) : null,
      ),
      child: Text(label, style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }

  // ─── Project Modules grid ──────────────────────────────────────────────────

  Widget _buildModulesSection(BuildContext context) {
    final modules = <_ModuleTile>[
      _ModuleTile(title: 'Documents',        icon: Icons.description_outlined,    color: AppTheme.primaryBlue,        onTap: () => _navigateToModule(context, 'Documents')),
      _ModuleTile(title: 'Payments',         icon: Icons.payment_outlined,        color: AppTheme.statusSuccess,      onTap: () => _navigateToModule(context, 'Payments')),
      _ModuleTile(title: 'BoQ',              icon: Icons.receipt_long_outlined,   color: AppTheme.safetyOrange,       onTap: () => _navigateToModule(context, 'BoQ')),
      _ModuleTile(title: 'Payment Schedule', icon: Icons.calendar_month_outlined, color: AppTheme.statusSuccess,      onTap: () => _navigateToModule(context, 'Payment Schedule')),
      _ModuleTile(title: 'BOQ Invoices',     icon: Icons.receipt_outlined,        color: AppTheme.primaryBlue,        onTap: () => _navigateToModule(context, 'BOQ Invoices')),
      _ModuleTile(title: 'Change Orders',    icon: Icons.edit_note_outlined,      color: AppTheme.coralRed,           onTap: () => _navigateToModule(context, 'Change Orders')),
      _ModuleTile(title: 'Warranties',       icon: Icons.verified_user_outlined,  color: AppTheme.primaryBlue,        onTap: () => _navigateToModule(context, 'Warranties')),
      _ModuleTile(title: 'Delay Logs',       icon: Icons.timer_off_outlined,      color: AppTheme.safetyOrange,       onTap: () => _navigateToModule(context, 'Delay Logs')),
      _ModuleTile(title: 'Quality Check',    icon: Icons.verified_outlined,       color: AppTheme.safetyYellow,       onTap: () => _navigateToModule(context, 'Quality Check')),
      _ModuleTile(title: 'Feedback',         icon: Icons.feedback_outlined,       color: AppTheme.skyBlue,            onTap: () => _navigateToModule(context, 'Feedback')),
      _ModuleTile(title: 'Gallery',          icon: Icons.photo_library_outlined,  color: AppTheme.coralRed,           onTap: () => _navigateToModule(context, 'Gallery')),
      _ModuleTile(title: 'Snags',            icon: Icons.warning_amber_rounded,   color: AppTheme.constructionOrange, onTap: () => _navigateToModule(context, 'Snags')),
      _ModuleTile(title: '360° Views',       icon: Icons.vrpano_outlined,         color: AppTheme.primaryBlue,        onTap: () => _navigateToModule(context, '360 Views')),
      _ModuleTile(title: 'Site Reports',     icon: Icons.assignment_outlined,     color: AppTheme.primaryBlue,        onTap: () => _navigateToModule(context, 'Site Reports')),
      _ModuleTile(title: 'Subcontracts',     icon: Icons.handshake_outlined,      color: AppTheme.skyBlue,            onTap: () => _navigateToModule(context, 'Subcontracts')),
      _ModuleTile(title: 'Variation Orders', icon: Icons.edit_note_outlined,      color: AppTheme.safetyOrange,       onTap: () => _navigateToModule(context, 'Variation Orders')),
      _ModuleTile(title: 'Stage Payments',   icon: Icons.payments_outlined,       color: AppTheme.primaryBlue,        onTap: () => _navigateToModule(context, 'Stage Payments')),
      _ModuleTile(title: 'Deductions',       icon: Icons.remove_circle_outline,   color: AppTheme.coralRed,           onTap: () => _navigateToModule(context, 'Deductions')),
      _ModuleTile(title: 'Final Account',    icon: Icons.account_balance_outlined,color: AppTheme.safetyYellow,       onTap: () => _navigateToModule(context, 'Final Account')),
    ];

    final cross = ResponsiveUtils.isLargeDesktop(context)
        ? 4
        : (ResponsiveUtils.isDesktop(context) ? 3 : 2);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Text('Project Modules', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cross,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.4,
          ),
          itemCount: modules.length,
          itemBuilder: (_, i) => modules[i],
        ),
      ],
    );
  }

  void _navigateToModule(BuildContext context, String moduleName) {
    final id = project.id;
    if (id == null) return;

    MaterialPageRoute<dynamic>? route;
    switch (moduleName) {
      case 'Documents':
        route = MaterialPageRoute(builder: (_) => ProjectDocumentsScreen(project: _asCustomerProject())); break;
      case 'Payments':
        route = MaterialPageRoute(builder: (_) => ProjectPaymentsScreen(project: _asCustomerProject())); break;
      case 'Payment Schedule':
        route = MaterialPageRoute(builder: (_) => PaymentScheduleScreen(projectId: id)); break;
      case 'BOQ Invoices':
        route = MaterialPageRoute(builder: (_) => BoqInvoiceScreen(projectId: id)); break;
      case 'Warranties':
        route = MaterialPageRoute(builder: (_) => Scaffold(
          appBar: AppBar(title: const Text('Warranties')),
          body: WarrantiesScreen(projectId: id),
        )); break;
      case 'Delay Logs':
        route = MaterialPageRoute(builder: (_) => Scaffold(
          appBar: AppBar(title: const Text('Delay Logs')),
          body: DelayLogsScreen(projectId: id),
        )); break;
      case 'Change Orders':
        route = MaterialPageRoute(builder: (_) => CoManagementScreen(projectId: id)); break;
      case 'Subcontracts':
        route = MaterialPageRoute(builder: (_) => SubcontractWorkOrdersScreen(projectId: id, projectName: project.name)); break;
      case 'BoQ':
        route = MaterialPageRoute(builder: (_) => BoqScreen(projectId: id)); break;
      case 'Site Reports':
        route = MaterialPageRoute(builder: (_) => SiteReportsScreen(projectId: id)); break;
      case 'Quality Check':
        route = MaterialPageRoute(builder: (_) => QualityChecksScreen(projectId: id)); break;
      case 'Feedback':
        route = MaterialPageRoute(builder: (_) => FeedbackScreen(projectId: id)); break;
      case 'Gallery':
        route = MaterialPageRoute(builder: (_) => GalleryScreen(projectId: id)); break;
      case 'Snags':
        route = MaterialPageRoute(builder: (_) => ObservationsScreen(projectId: id)); break;
      case '360 Views':
        route = MaterialPageRoute(builder: (_) => View360ListScreen(projectId: id, projectName: project.name)); break;
      case 'Variation Orders':
        route = MaterialPageRoute(builder: (_) => VOListScreen(projectId: id, projectName: project.name)); break;
      case 'Stage Payments':
        route = MaterialPageRoute(builder: (_) => StagePaymentScreen(projectId: id, projectName: project.name)); break;
      case 'Deductions':
        route = MaterialPageRoute(builder: (_) => DeductionRegisterScreen(projectId: id, projectName: project.name)); break;
      case 'Final Account':
        route = MaterialPageRoute(builder: (_) => FinalAccountScreen(projectId: id, projectName: project.name)); break;
    }

    if (route != null) {
      Navigator.push(context, route);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$moduleName is coming soon.'),
          backgroundColor: AppTheme.primaryBlue,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
      case 'ongoing':
      case 'in_progress':
        return Colors.green;
      case 'completed':
      case 'handover':
        return Colors.blue;
      case 'on_hold':
      case 'paused':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _progressColor(double progress) {
    if (progress >= 75) return Colors.green;
    if (progress >= 40) return AppTheme.constructionOrange;
    return AppTheme.coralRed;
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
            border: Border.all(color: AppTheme.borderLight, width: 1),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2)),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
                  child: Icon(icon, size: 28, color: color),
                ),
                const SizedBox(height: 10),
                Text(
                  title,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
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
