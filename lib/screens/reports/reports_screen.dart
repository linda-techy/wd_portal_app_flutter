import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants.dart';
import '../../models/site_report_models.dart';
import '../../models/customer_project.dart';
import '../../services/site_report_service.dart';
import '../../services/crm_service.dart';
import '../../theme/app_theme.dart';
import '../../config/app_config.dart';
import './add_site_report_screen.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  _ReportsScreenState createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final _siteReportService = SiteReportService();
  List<CustomerProject> _projects = [];
  List<SiteReport> _reports = [];
  bool _isLoading = true;
  CustomerProject? _selectedProject;



  void _showPhotoPreview(String photoUrl, String title) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(AppTheme.spacingMD),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 30),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            Flexible(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  photoUrl,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                            : null,
                        color: Colors.white,
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) => Container(
                    padding: const EdgeInsets.all(20),
                    color: Colors.white,
                    child: const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.broken_image, color: Colors.red, size: 48),
                        SizedBox(height: 12),
                        Text("Failed to load image"),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  String _getPhotoUrl(String path) {
    if (path.startsWith('http')) return path;
    // Standardize to use /api/storage if not already present
    String cleanPath = path;
    if (!path.startsWith('/api/storage/') && !path.startsWith('api/storage/')) {
        cleanPath = '/api/storage/${path.startsWith('/') ? path.substring(1) : path}';
    } else if (!path.startsWith('/')) {
        cleanPath = '/$path';
    }
    return '${AppConfig.fullApiUrl}$cleanPath';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text("Site Reports"),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchReports,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddSiteReportScreen(initialProject: _selectedProject),
            ),
          );
          if (result == true) _fetchReports();
        },
        label: const Text('New Report'),
        icon: const Icon(Icons.add),
        backgroundColor: AppTheme.coralRed,
      ),
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.coralRed))
                : _reports.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.all(defaultPadding),
                        itemCount: _reports.length,
                        itemBuilder: (context, index) => _buildReportCard(_reports[index]),
                      ),
          ),
        ],
      ),
    );
  }


  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final projects = await CRMService().getAllCustomerProjects();
      
      List<SiteReport> reports;
      if (_selectedProject == null) {
        reports = await _siteReportService.getMyReports();
      } else {
        reports = await _siteReportService.getReportsByProject(_selectedProject!.id!);
      }

      setState(() {
        _projects = projects;
        _reports = reports;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error loading data: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _fetchReports() async {
     setState(() => _isLoading = true);
    try {
      final reports = _selectedProject == null
          ? await _siteReportService.getMyReports()
          : await _siteReportService.getReportsByProject(_selectedProject!.id!);
      setState(() {
        _reports = reports;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error fetching reports: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  // ... (keep _showPhotoPreview and _getPhotoUrl)

  // ... (keep build method)
  
  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: defaultPadding, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.filter_list, size: 20, color: AppTheme.textSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButton<CustomerProject>(
              hint: const Text("All Projects"),
              value: _selectedProject,
              isExpanded: true,
              underline: const SizedBox(),
              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
              items: [
                const DropdownMenuItem<CustomerProject>(
                  value: null,
                  child: Text("All Projects"),
                ),
                ..._projects.map((p) => DropdownMenuItem(
                      value: p,
                      child: Text(p.projectName),
                    )),
              ],
              onChanged: (val) {
                setState(() => _selectedProject = val);
                _fetchReports();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.assignment_outlined, size: 64, color: Colors.grey.shade400),
          ),
          const SizedBox(height: 24),
          const Text(
            "No Reports Found",
            style: TextStyle(fontSize: 18, color: AppTheme.textPrimary, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            "Submit your first site progress report",
            style: TextStyle(color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildReportCard(SiteReport report) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        title: Text(report.title, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            children: [
              _buildTypeBadge(report.reportType),
              const SizedBox(width: 8),
              Text(report.formattedDate, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
            ],
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (report.description != null && report.description!.isNotEmpty) ...[
                  Text(report.description!, style: const TextStyle(color: AppTheme.textSecondary, height: 1.5)),
                  const SizedBox(height: 16),
                ],
                if (report.photos.isNotEmpty) ...[
                  const Text("Photos", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textPrimary)),
                  const SizedBox(height: 8),
                  _buildPhotoGrid(report),
                ],
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Icon(Icons.person_outline, size: 14, color: Colors.grey.shade500),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              "By: ${report.submittedByName ?? 'Unknown'}",
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (report.siteVisitId != null) 
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.link, size: 12, color: Colors.blue.shade700),
                            const SizedBox(width: 4),
                            Text("Linked to Visit", style: TextStyle(fontSize: 10, color: Colors.blue.shade700, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeBadge(ReportType type) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.coralRed.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        type.label,
        style: const TextStyle(color: AppTheme.coralRed, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildPhotoGrid(SiteReport report) {
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: report.photos.length,
        itemBuilder: (context, index) {
          final photo = report.photos[index];
          final fullUrl = _getPhotoUrl(photo.photoUrl);
          
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: InkWell(
              onTap: () => _showPhotoPreview(fullUrl, report.title),
              borderRadius: BorderRadius.circular(8),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      fullUrl,
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          width: 100,
                          height: 100,
                          color: Colors.grey.shade100,
                          child: const Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.coralRed)),
                        );
                      },
                      errorBuilder: (_, __, ___) => Container(
                        width: 100,
                        height: 100,
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.broken_image, size: 24, color: Colors.grey),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 4,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.zoom_in, color: Colors.white, size: 14),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

