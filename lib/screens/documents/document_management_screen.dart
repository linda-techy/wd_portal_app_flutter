import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../theme/responsive_utils.dart';
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
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CreateDocumentScreen(
                  documentType: docType['title'] as String,
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
                docType['title'] as String,
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
