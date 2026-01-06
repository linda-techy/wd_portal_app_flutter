import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../theme/responsive_utils.dart';
import '../../widgets/components/data_card.dart';
import '../../widgets/components/status_indicator.dart';
import '../../widgets/components/enhanced_data_table.dart';
import '../../widgets/charts/chart_card.dart';
import 'package:provider/provider.dart';
import '../../providers/document_provider.dart';
import '../../models/document_models.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'project_tracking_screen.dart';
import 'view_360_list_screen.dart';
import '../../models/customer_project.dart';

/// Project Detail Screen - Single-Pane-of-Glass View
/// Displays comprehensive project information in one unified view
class ProjectDetailScreen extends StatefulWidget {
  final int projectId;
  
  const ProjectDetailScreen({
    super.key,
    required this.projectId,
  });
  
  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Column(
        children: [
          // Sticky Header
          _buildStickyHeader(context),
          
          // Main Content
          Expanded(
            child: Row(
              children: [
                // Main Content Area
                Expanded(
                  flex: 3,
                  child: _buildMainContent(context),
                ),
                
                // Sidebar (Filters/Quick Actions) - Desktop only
                if (ResponsiveUtils.isDesktop(context))
                  Container(
                    width: 300,
                    margin: const EdgeInsets.all(AppTheme.spacingMD),
                    child: _buildSidebar(context),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStickyHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingLG),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: Border(
          bottom: BorderSide(color: AppTheme.borderLight, width: 1),
        ),
        boxShadow: AppTheme.shadowSM,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Project Name and Status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Commercial Complex - Phase 2',
                      style: Theme.of(context).textTheme.displaySmall,
                    ),
                    const SizedBox(height: AppTheme.spacingSM),
                    Row(
                      children: [
                        ProjectStatusIndicator(
                          status: 'On Track',
                          isOnTrack: true,
                          progress: 65.5,
                        ),
                        const SizedBox(width: AppTheme.spacingMD),
                        Text(
                          'Project ID: #${widget.projectId}',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppTheme.textSecondary,
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Budget Utilization
              Container(
                padding: const EdgeInsets.all(AppTheme.spacingMD),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceElevated,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                  border: Border.all(color: AppTheme.borderLight),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Budget Utilization',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: AppTheme.spacingXS),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '72.5%',
                          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                                color: AppTheme.statusWarning,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(width: AppTheme.spacingXS),
                        Text(
                          '/ 100%',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppTheme.textSecondary,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.spacingXS),
                    SizedBox(
                      width: 150,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                        child: LinearProgressIndicator(
                          value: 0.725,
                          backgroundColor: AppTheme.borderLight,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppTheme.statusWarning,
                          ),
                          minHeight: 6,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildMainContent(BuildContext context) {
    return Column(
      children: [
        // Tabs
        Container(
          color: AppTheme.surface,
          child: TabBar(
            controller: _tabController,
            labelColor: AppTheme.primaryBlue,
            unselectedLabelColor: AppTheme.textSecondary,
            indicatorColor: AppTheme.primaryBlue,
            indicatorWeight: 3,
            tabs: const [
              Tab(text: 'Tasks & Timeline'),
              Tab(text: 'Financials'),
              Tab(text: 'Documents'),
              Tab(text: 'Reports & Photos'),
            ],
          ),
        ),
        
        // Tab Content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildTasksTab(context),
              _buildFinancialsTab(context),
              _buildDocumentsTab(context),
              _buildReportsTab(context),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildTasksTab(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacingLG),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quick Stats
          ResponsiveLayout(
            mobile: Column(
              children: _buildTaskStats(context),
            ),
            desktop: Row(
              children: _buildTaskStats(context),
            ),
          ),
          
          const SizedBox(height: AppTheme.spacingLG),
          
          // Gantt Chart / Timeline View
          ChartCard(
            title: 'Project Timeline',
            subtitle: 'Task progress over time',
            height: 400,
            chart: _buildTimelineChart(),
          ),
          
          const SizedBox(height: AppTheme.spacingLG),
          
          // Task List
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingLG),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(AppTheme.radiusLG),
              border: Border.all(color: AppTheme.borderLight),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Task List',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: AppTheme.spacingMD),
                _buildTaskList(),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  List<Widget> _buildTaskStats(BuildContext context) {
    return [
      Expanded(
        child: MetricCard(
          label: 'Total Tasks',
          value: '42',
          change: '+5 this week',
          isPositive: true,
          icon: Icons.assignment,
        ),
      ),
      const SizedBox(width: AppTheme.spacingMD),
      Expanded(
        child: MetricCard(
          label: 'Completed',
          value: '28',
          change: '66.7%',
          isPositive: true,
          icon: Icons.check_circle,
          accentColor: AppTheme.statusSuccess,
        ),
      ),
      const SizedBox(width: AppTheme.spacingMD),
      Expanded(
        child: MetricCard(
          label: 'In Progress',
          value: '10',
          change: '23.8%',
          isPositive: true,
          icon: Icons.hourglass_empty,
          accentColor: AppTheme.statusInfo,
        ),
      ),
      const SizedBox(width: AppTheme.spacingMD),
      Expanded(
        child: MetricCard(
          label: 'Delayed',
          value: '4',
          change: '9.5%',
          isPositive: false,
          icon: Icons.warning,
          accentColor: AppTheme.statusWarning,
        ),
      ),
    ];
  }
  
  Widget _buildTimelineChart() {
    // Placeholder for Gantt chart
    // In production, use syncfusion_flutter_charts or fl_chart
    return Container(
      color: AppTheme.surfaceElevated,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.timeline,
              size: 64,
              color: AppTheme.textTertiary,
            ),
            const SizedBox(height: AppTheme.spacingMD),
            Text(
              'Gantt Chart View',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: AppTheme.spacingSM),
            Text(
              'Integrate with syncfusion_flutter_charts or fl_chart',
              style: TextStyle(
                color: AppTheme.textTertiary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTaskList() {
    // Placeholder for task list
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 5,
      itemBuilder: (context, index) {
        return ListTile(
          leading: const Icon(Icons.circle_outlined),
          title: Text('Task ${index + 1}'),
          subtitle: Text('Due: ${DateTime.now().add(Duration(days: index)).toString().split(' ')[0]}'),
          trailing: StatusIndicator(
            label: index % 3 == 0 ? 'Completed' : 'In Progress',
            type: index % 3 == 0 ? StatusType.success : StatusType.info,
            compact: true,
          ),
        );
      },
    );
  }
  
  Widget _buildFinancialsTab(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacingLG),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Financial Overview Cards
          ResponsiveLayout(
            mobile: Column(
              children: _buildFinancialCards(context),
            ),
            desktop: Row(
              children: _buildFinancialCards(context),
            ),
          ),
          
          const SizedBox(height: AppTheme.spacingLG),
          
          // Budget Breakdown Chart
          ChartCard(
            title: 'Budget Breakdown',
            subtitle: 'By category',
            height: 300,
            chart: _buildBudgetChart(),
          ),
          
          const SizedBox(height: AppTheme.spacingLG),
          
          // Invoices and POs Table
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingLG),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(AppTheme.radiusLG),
              border: Border.all(color: AppTheme.borderLight),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Invoices & Purchase Orders',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: AppTheme.spacingMD),
                _buildFinancialTable(),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  List<Widget> _buildFinancialCards(BuildContext context) {
    return [
      Expanded(
        child: DataCard(
          title: 'Total Budget',
          valueText: '₹12,500,000',
          icon: Icons.account_balance_wallet,
          iconColor: AppTheme.primaryBlue,
        ),
      ),
      const SizedBox(width: AppTheme.spacingMD),
      Expanded(
        child: DataCard(
          title: 'Spent',
          valueText: '₹9,062,500',
          icon: Icons.payments,
          iconColor: AppTheme.statusWarning,
        ),
      ),
      const SizedBox(width: AppTheme.spacingMD),
      Expanded(
        child: DataCard(
          title: 'Remaining',
          valueText: '₹3,437,500',
          icon: Icons.savings,
          iconColor: AppTheme.statusSuccess,
        ),
      ),
    ];
  }
  
  Widget _buildBudgetChart() {
    // Placeholder for pie/bar chart
    return Container(
      color: AppTheme.surfaceElevated,
      child: Center(
        child: Text(
          'Budget Chart - Use fl_chart or syncfusion_flutter_charts',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
      ),
    );
  }
  
  Widget _buildFinancialTable() {
    return EnhancedDataTable(
      columns: const [
        DataColumn(label: Text('Date')),
        DataColumn(label: Text('Type')),
        DataColumn(label: Text('Amount')),
        DataColumn(label: Text('Status')),
      ],
      rows: List.generate(5, (index) {
        return DataRow(
          cells: [
            DataCell(Text('2024-01-${15 + index}')),
            DataCell(Text(index % 2 == 0 ? 'Invoice' : 'PO')),
            DataCell(Text('₹${(index + 1) * 50000}')),
            DataCell(
              StatusIndicator(
                label: index % 3 == 0 ? 'Paid' : 'Pending',
                type: index % 3 == 0 ? StatusType.success : StatusType.warning,
                compact: true,
              ),
            ),
          ],
        );
      }),
      showSearch: true,
      showFilters: true,
      filterOptions: [
        FilterOption(key: 'type', label: 'Type'),
        FilterOption(key: 'status', label: 'Status'),
      ],
    );
  }
  
  Widget _buildReportsTab(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacingLG),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Daily Reports
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingLG),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(AppTheme.radiusLG),
              border: Border.all(color: AppTheme.borderLight),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Daily Reports',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('New Report'),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spacingMD),
                _buildReportsList(),
              ],
            ),
          ),
          
          const SizedBox(height: AppTheme.spacingLG),
          
          // Site Photos
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingLG),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(AppTheme.radiusLG),
              border: Border.all(color: AppTheme.borderLight),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Site Photos',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.camera_alt, size: 18),
                      label: const Text('Add Photo'),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spacingMD),
                _buildPhotosGrid(),
              ],
            ),
          ),

          const SizedBox(height: AppTheme.spacingLG),

          // 360° Virtual Tours
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingLG),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(AppTheme.radiusLG),
              border: Border.all(color: AppTheme.borderLight),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '360° Virtual Tours',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => View360ListScreen(
                              projectId: widget.projectId,
                              projectName: 'Commercial Complex - Phase 2', // Use dynamic name if available
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.vibration, size: 18),
                      label: const Text('View Tours'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.coralRed,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spacingMD),
                const Text(
                  'Explore the site through immersive 360° panoramic views captured from the field.',
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildReportsList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 10,
      itemBuilder: (context, index) {
        return ListTile(
          leading: const Icon(Icons.description),
          title: Text('Daily Report - ${DateTime.now().subtract(Duration(days: index)).toString().split(' ')[0]}'),
          subtitle: Text('Reported by: Site Manager ${index + 1}'),
          trailing: IconButton(
            icon: const Icon(Icons.arrow_forward_ios, size: 16),
            onPressed: () {},
          ),
        );
      },
    );
  }
  
  Widget _buildPhotosGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: AppTheme.spacingMD,
        mainAxisSpacing: AppTheme.spacingMD,
        childAspectRatio: 1.2,
      ),
      itemCount: 8,
      itemBuilder: (context, index) {
        return Container(
          decoration: BoxDecoration(
            color: AppTheme.surfaceElevated,
            borderRadius: BorderRadius.circular(AppTheme.radiusMD),
            border: Border.all(color: AppTheme.borderLight),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.image, size: 48, color: AppTheme.textTertiary),
              const SizedBox(height: AppTheme.spacingSM),
              Text(
                'Photo ${index + 1}',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
              ),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildSidebar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMD),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Filters',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: AppTheme.spacingMD),
          
          // Filter Chips
          Wrap(
            spacing: AppTheme.spacingSM,
            runSpacing: AppTheme.spacingSM,
            children: [
              FilterChip(
                label: const Text('This Week'),
                selected: false,
                onSelected: (value) {},
              ),
              FilterChip(
                label: const Text('This Month'),
                selected: true,
                onSelected: (value) {},
              ),
              FilterChip(
                label: const Text('Overdue'),
                selected: false,
                onSelected: (value) {},
              ),
            ],
          ),
          
          const SizedBox(height: AppTheme.spacingLG),
          
          Text(
            'Quick Actions',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: AppTheme.spacingMD),
          
          // Quick Action Buttons
          Column(
            children: [
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.add_task, size: 18),
                  label: const Text('Add Task'),
                ),
              ),
              const SizedBox(height: AppTheme.spacingSM),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.receipt, size: 18),
                  label: const Text('New Invoice'),
                ),
              ),
              const SizedBox(height: AppTheme.spacingSM),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.camera_alt, size: 18),
                  label: const Text('Add Photo'),
                ),
              ),
              const SizedBox(height: AppTheme.spacingSM),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => View360ListScreen(
                          projectId: widget.projectId,
                          projectName: 'Commercial Complex - Phase 2',
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.vibration, size: 18),
                  label: const Text('360° Tours'),
                ),
              ),
              const SizedBox(height: AppTheme.spacingSM),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProjectTrackingScreen(
                          projectId: widget.projectId,
                          projectName: 'Project #${widget.projectId}',
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.analytics, size: 18),
                  label: const Text('Budget & Tracking'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentsTab(BuildContext context) {
    return Column(
      children: [
        _buildDocumentActionRow(context),
        Expanded(child: _buildDocumentList(context)),
      ],
    );
  }

  Widget _buildDocumentActionRow(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingLG),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Project Documents',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          ElevatedButton.icon(
            onPressed: () => _uploadDocument(context),
            icon: const Icon(Icons.upload, size: 18),
            label: const Text('Upload Document'),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentList(BuildContext context) {
    return Consumer<DocumentProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) return const Center(child: CircularProgressIndicator());
        
        // Initial fetch if empty
        if (provider.documents.isEmpty && !provider.isLoading) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            provider.fetchDocuments(widget.projectId);
            provider.fetchCategories(widget.projectId);
          });
        }

        if (provider.documents.isEmpty) {
          return const Center(child: Text("No documents found for this project"));
        }

        return ListView.separated(
          padding: const EdgeInsets.all(AppTheme.spacingLG),
          itemCount: provider.documents.length,
          separatorBuilder: (context, index) => const SizedBox(height: AppTheme.spacingMD),
          itemBuilder: (context, index) {
            final doc = provider.documents[index];
            return Card(
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(AppTheme.spacingSM),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                  ),
                  child: Icon(
                    _getFileIcon(doc.fileType),
                    color: AppTheme.primaryBlue,
                  ),
                ),
                title: Text(doc.filename),
                subtitle: Text(
                  "${doc.categoryName} • ${DateFormat('yyyy-MM-dd').format(DateTime.parse(doc.uploadDate))}",
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.download),
                  onPressed: () => _downloadFile(doc.downloadUrl),
                ),
                onTap: () {
                  // Show details or preview
                },
              ),
            );
          },
        );
      },
    );
  }

  IconData _getFileIcon(String type) {
    if (type.contains('pdf')) return Icons.picture_as_pdf;
    if (type.contains('image')) return Icons.image;
    if (type.contains('sheet') || type.contains('excel')) return Icons.table_view;
    if (type.contains('word') || type.contains('document')) return Icons.description;
    return Icons.insert_drive_file;
  }

  Future<void> _downloadFile(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Could not launch download URL")),
      );
    }
  }

  Future<void> _uploadDocument(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles();
    if (result == null || result.files.single.path == null) return;

    final file = File(result.files.single.path!);
    final provider = context.read<DocumentProvider>();

    if (provider.categories.isEmpty) {
      await provider.fetchCategories(widget.projectId);
    }

    if (!context.mounted) return;

    // Show simple category selection dialog
    final categoryId = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Select Category"),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: provider.categories.length,
            itemBuilder: (context, index) {
              final cat = provider.categories[index];
              return ListTile(
                title: Text(cat.name),
                onTap: () => Navigator.pop(context, cat.id),
              );
            },
          ),
        ),
      ),
    );

    if (categoryId != null && context.mounted) {
      try {
        await provider.uploadDocument(
          projectId: widget.projectId,
          file: file,
          categoryId: categoryId,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Document uploaded successfully")),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Upload failed: $e")),
        );
      }
    }
  }
}

