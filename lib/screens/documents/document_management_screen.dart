import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../theme/responsive_utils.dart';
import '../../services/crm_service.dart';
import '../../models/customer_project.dart';
import 'create_document_screen.dart';
import 'design_agreement_screen.dart';
import 'approval_center_screen.dart';
import 'package:provider/provider.dart';
import '../../providers/approval_provider.dart';

class DocumentManagementScreen extends StatefulWidget {
  const DocumentManagementScreen({super.key});

  @override
  State<DocumentManagementScreen> createState() =>
      _DocumentManagementScreenState();
}

class _DocumentManagementScreenState extends State<DocumentManagementScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // In a real app, you'd get the actual user ID
      // For now, we'll rely on the provider having the data or fetching it
    });
  }

  final List<Map<String, dynamic>> _documentTypes = [
    {
      'title': 'Design Agreement',
      'icon': Icons.brush_outlined,
      'color': Colors.blue,
    },
    {
      'title': 'Construction Agreement',
      'icon': Icons.construction_outlined,
      'color': Colors.orange,
    },
    {
      'title': 'Site Handover',
      'icon': Icons.handshake_outlined,
      'color': Colors.green,
    },
    {
      'title': 'Completion Certificate',
      'icon': Icons.verified_outlined,
      'color': Colors.purple,
    },
    {
      'title': 'Detailed Project Costing',
      'icon': Icons.receipt_long_outlined,
      'color': Color(0xFFEF5D4A),
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: AdaptiveContainer(
        child: SingleChildScrollView(
          padding: ResponsiveUtils.responsivePadding(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                'Document Management',
                style: Theme.of(context).textTheme.displaySmall,
              ),
              const SizedBox(height: AppTheme.spacingLG),

              // Approval Pending Tile
              _buildApprovalPendingTile(),
              const SizedBox(height: AppTheme.spacingXL),

              // Create New Document Section
              Text(
                'Create New Document',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: AppTheme.spacingMD),
              _buildDocumentCreationGrid(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildApprovalPendingTile() {
    return Consumer<ApprovalProvider>(
      builder: (context, provider, child) {
        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMD),
            side: const BorderSide(color: AppTheme.borderLight),
          ),
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const ApprovalCenterScreen()),
              );
            },
            borderRadius: BorderRadius.circular(AppTheme.radiusMD),
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spacingLG),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppTheme.spacingMD),
                    decoration: const BoxDecoration(
                      color: AppTheme.statusWarningBg,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.pending_actions_outlined,
                      color: AppTheme.statusWarning,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingMD),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Approval Pending',
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${provider.totalElements} documents waiting for approval',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppTheme.textSecondary,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios,
                    color: AppTheme.textTertiary,
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDocumentCreationGrid() {
    return ResponsiveLayout(
      mobile: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: AppTheme.spacingMD,
          mainAxisSpacing: AppTheme.spacingMD,
          childAspectRatio: 1.0,
        ),
        itemCount: _documentTypes.length,
        itemBuilder: (context, index) {
          return _buildDocumentTypeCard(_documentTypes[index]);
        },
      ),
      desktop: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          crossAxisSpacing: AppTheme.spacingMD,
          mainAxisSpacing: AppTheme.spacingMD,
          childAspectRatio: 1.2,
        ),
        itemCount: _documentTypes.length,
        itemBuilder: (context, index) {
          return _buildDocumentTypeCard(_documentTypes[index]);
        },
      ),
    );
  }

  /// Show a list of projects so the user can pick which project's DPC to
  /// open. Navigates to /dpc/builder/{projectId} on tap.
  Future<void> _openDpcProjectPicker() async {
    final crm = CRMService();
    List<CustomerProject> projects = const [];
    String? loadError;
    try {
      projects = await crm.getAllCustomerProjects();
    } catch (e) {
      loadError = e.toString();
    }
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600, maxHeight: 560),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.receipt_long_outlined,
                        color: Color(0xFFEF5D4A), size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text('Detailed Project Costing',
                          style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold)),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Pick a project — the DPC builder opens with a draft '
                  'pre-filled from that project\'s approved BoQ.',
                  style: TextStyle(color: Colors.black54, fontSize: 13),
                ),
                const Divider(height: 24),
                Expanded(
                  child: loadError != null
                      ? Center(
                          child: Text('Failed to load projects: $loadError',
                              style: const TextStyle(color: Colors.red)))
                      : projects.isEmpty
                          ? const Center(
                              child: Text('No projects found.',
                                  style: TextStyle(color: Colors.black54)))
                          : ListView.separated(
                              itemCount: projects.length,
                              separatorBuilder: (_, __) =>
                                  const Divider(height: 1),
                              itemBuilder: (_, i) {
                                final p = projects[i];
                                return ListTile(
                                  leading: const CircleAvatar(
                                    backgroundColor: Color(0xFFFEE2E2),
                                    child: Icon(Icons.home_work_outlined,
                                        color: Color(0xFFEF5D4A)),
                                  ),
                                  title: Text(
                                    p.projectName.isNotEmpty
                                        ? p.projectName
                                        : 'Project #${p.id}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600),
                                  ),
                                  subtitle: Text(
                                    [
                                      if ((p.code ?? '').isNotEmpty) p.code!,
                                      if (p.location.isNotEmpty) p.location,
                                    ].join('  ·  '),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  trailing: const Icon(Icons.arrow_forward_ios,
                                      size: 16),
                                  onTap: () {
                                    Navigator.pop(ctx);
                                    if (p.id != null) {
                                      context
                                          .go('/dpc/builder/${p.id}');
                                    }
                                  },
                                );
                              },
                            ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDocumentTypeCard(Map<String, dynamic> docType) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        side: const BorderSide(color: AppTheme.borderLight),
      ),
      child: InkWell(
        onTap: () {
          if (docType['title'] == 'Design Agreement') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const DesignAgreementScreen(),
              ),
            );
          } else if (docType['title'] == 'Detailed Project Costing') {
            _openDpcProjectPicker();
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CreateDocumentScreen(
                  documentType: (docType['title'] as String?) ?? '',
                ),
              ),
            );
          }
        },
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingMD),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(AppTheme.spacingMD),
                decoration: BoxDecoration(
                  color: (docType['color'] as Color).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  docType['icon'] as IconData,
                  color: docType['color'] as Color,
                  size: 32,
                ),
              ),
              const SizedBox(height: AppTheme.spacingMD),
              Text(
                (docType['title'] as String?) ?? '',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
