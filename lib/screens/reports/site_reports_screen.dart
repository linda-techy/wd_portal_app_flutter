import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:admin/models/site_report_models.dart';
import 'package:admin/providers/site_report_provider.dart';
import 'package:admin/screens/reports/add_site_report_screen.dart';
import 'package:admin/screens/reports/site_report_detail_screen.dart';
import 'package:admin/widgets/common/search_bar_widget.dart';
import 'package:admin/theme/app_theme.dart';
import 'package:admin/providers/permission_provider.dart';

class SiteReportsScreen extends StatefulWidget {
  const SiteReportsScreen({super.key});

  @override
  State<SiteReportsScreen> createState() => _SiteReportsScreenState();
}

class _SiteReportsScreenState extends State<SiteReportsScreen> {
  bool _isTimelineView = true;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SiteReportProvider()..fetch(),
      child: Consumer<SiteReportProvider>(
        builder: (context, provider, _) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Site Reports'),
              actions: [
                IconButton(
                  icon: Icon(_isTimelineView ? Icons.view_list : Icons.timeline),
                  onPressed: () {
                    setState(() {
                      _isTimelineView = !_isTimelineView;
                    });
                  },
                  tooltip: _isTimelineView ? 'Card View' : 'Timeline View',
                ),
                Consumer<PermissionProvider>(
                  builder: (context, permissionProvider, _) {
                    if (permissionProvider.hasPermission('report:create')) {
                      return IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () => _navigateToCreate(context),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ],
            ),
            body: Column(
              children: [
                _buildSearchAndFilters(context, provider),
                Expanded(
                  child: _isTimelineView
                      ? _buildTimelineView(context, provider)
                      : _buildReportList(context, provider),
                ),
                if (provider.totalPages > 1)
                  _buildPagination(context, provider),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSearchAndFilters(BuildContext context, SiteReportProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[100],
      child: Column(
        children: [
          SearchBarWidget(
            onSearch: (query) => provider.search(query),
            hintText: 'Search site reports...',
          ),
          const SizedBox(height: 12),
          _buildFilterChips(context, provider),
        ],
      ),
    );
  }

  Widget _buildFilterChips(BuildContext context, SiteReportProvider provider) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildFilterChip(
          context,
          label: 'All Types',
          isSelected: provider.filters['reportType'] == null,
          onTap: () => provider.clearFilters(),
        ),
        _buildFilterChip(
          context,
          label: 'Daily',
          isSelected: provider.filters['reportType'] == 'DAILY',
          onTap: () => provider.updateFilter('reportType', 'DAILY'),
        ),
        _buildFilterChip(
          context,
          label: 'Weekly',
          isSelected: provider.filters['reportType'] == 'WEEKLY',
          onTap: () => provider.updateFilter('reportType', 'WEEKLY'),
        ),
        _buildFilterChip(
          context,
          label: 'Incident',
          isSelected: provider.filters['reportType'] == 'INCIDENT',
          onTap: () => provider.updateFilter('reportType', 'INCIDENT'),
          color: AppTheme.statusError,
        ),
      ],
    );
  }

  Widget _buildFilterChip(
    BuildContext context, {
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    Color? color,
  }) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
      backgroundColor: color?.withOpacity(0.1),
      selectedColor: color ?? Theme.of(context).primaryColor,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : (color ?? Colors.black87),
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildTimelineView(BuildContext context, SiteReportProvider provider) {
    if (provider.isLoading && provider.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: ${provider.error}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => provider.fetch(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (provider.items.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.timeline, size: 48, color: Colors.grey),
            SizedBox(height: 16),
            Text('No site reports found', style: TextStyle(fontSize: 16)),
          ],
        ),
      );
    }

    // Group reports by date
    final groupedReports = <DateTime, List<SiteReport>>{};
    for (final report in provider.items) {
      final date = DateTime(
        report.reportDate.year,
        report.reportDate.month,
        report.reportDate.day,
      );
      groupedReports.putIfAbsent(date, () => []).add(report);
    }

    final sortedDates = groupedReports.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    return RefreshIndicator(
      onRefresh: () => provider.fetch(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: sortedDates.length,
        itemBuilder: (context, index) {
          final date = sortedDates[index];
          final reports = groupedReports[date]!;
          return _buildDateGroup(context, date, reports);
        },
      ),
    );
  }

  Widget _buildDateGroup(BuildContext context, DateTime date, List<SiteReport> reports) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    
    final isToday = date.isAtSameMomentAs(today);
    final isYesterday = date.isAtSameMomentAs(yesterday);

    String dateLabel;
    if (isToday) {
      dateLabel = 'Today';
    } else if (isYesterday) {
      dateLabel = 'Yesterday';
    } else {
      dateLabel = DateFormat('EEEE, MMMM d, y').format(date);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date Header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isToday 
                        ? Theme.of(context).primaryColor.withOpacity(0.1) 
                        : Colors.grey[100],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 14,
                        color: isToday 
                            ? Theme.of(context).primaryColor 
                            : Colors.grey[600],
                      ),
                      const SizedBox(width: 6),
                      Text(
                        dateLabel,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isToday 
                              ? Theme.of(context).primaryColor 
                              : Colors.grey[800],
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Text(
                  '${reports.length} ${reports.length == 1 ? 'report' : 'reports'}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Timeline items
          ...reports.asMap().entries.map((entry) {
            final index = entry.key;
            final report = entry.value;
            final isLast = index == reports.length - 1;
            return _buildTimelineItem(context, report, isLast);
          }),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(BuildContext context, SiteReport report, bool isLast) {
    final dateStr = DateFormat('MMM d, yyyy').format(report.reportDate);
    final timeStr = DateFormat('h:mm a').format(report.reportDate);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date label and timeline
          SizedBox(
            width: 100,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 12, top: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        dateStr,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        timeStr,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Timeline line and dot
          SizedBox(
            width: 24,
            child: Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).primaryColor.withOpacity(0.3),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: Colors.grey[300],
                    ),
                  ),
              ],
            ),
          ),
          // Content
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(left: 12, bottom: isLast ? 0 : 20),
              child: _buildTimelineCard(context, report),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineCard(BuildContext context, SiteReport report) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: () => _navigateToDetail(context, report),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      report.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (report.reportType == ReportType.safetyIncident)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.statusError,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'INCIDENT',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              if (report.projectName != null) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.business, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        report.projectName!,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
              if (report.summary != null && report.summary!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  report.summary!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                ),
              ],
              // Photos Preview
              if (report.photos.isNotEmpty) ...[
                const SizedBox(height: 10),
                SizedBox(
                  height: 70,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: report.photos.length > 4 ? 4 : report.photos.length,
                    itemBuilder: (context, photoIndex) {
                      final photo = report.photos[photoIndex];
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: GestureDetector(
                          onTap: () => _openPhotoGallery(context, report, photoIndex),
                          child: Hero(
                            tag: 'photo_${report.id}_$photoIndex',
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: Image.network(
                                photo.fullUrl,
                                width: 70,
                                height: 70,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    width: 70,
                                    height: 70,
                                    color: Colors.grey[300],
                                    child: Icon(Icons.broken_image, size: 20, color: Colors.grey[600]),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                if (report.photos.length > 4)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '+${report.photos.length - 4} more photos',
                      style: TextStyle(color: Colors.grey[600], fontSize: 11),
                    ),
                  ),
              ],
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  if (report.reportedByName != null)
                    _buildSmallInfoChip(
                      icon: Icons.person,
                      label: report.reportedByName!,
                    ),
                  if (report.weatherCondition != null)
                    _buildSmallInfoChip(
                      icon: Icons.wb_sunny,
                      label: report.weatherCondition!,
                    ),
                  if (report.labourCount != null)
                    _buildSmallInfoChip(
                      icon: Icons.groups,
                      label: '${report.labourCount}',
                    ),
                  if (report.photos.isNotEmpty)
                    _buildSmallInfoChip(
                      icon: Icons.photo_library,
                      label: '${report.photos.length}',
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSmallInfoChip({
    required IconData icon,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.grey[700]),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: Colors.grey[700]),
          ),
        ],
      ),
    );
  }

  Widget _buildReportList(BuildContext context, SiteReportProvider provider) {
    if (provider.isLoading && provider.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: ${provider.error}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => provider.fetch(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (provider.items.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.description, size: 48, color: Colors.grey),
            SizedBox(height: 16),
            Text('No site reports found', style: TextStyle(fontSize: 16)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => provider.fetch(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: provider.items.length,
        itemBuilder: (context, index) {
          final report = provider.items[index];
          return _buildReportCard(context, report);
        },
      ),
    );
  }

  Widget _buildReportCard(BuildContext context, SiteReport report) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: () => _navigateToDetail(context, report),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          report.reportType.label,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (report.projectName != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            report.projectName!,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (report.reportType == ReportType.safetyIncident)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.statusError,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'INCIDENT',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              if (report.summary != null && report.summary!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  report.summary!,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  if (report.reportedByName != null)
                    _buildInfoChip(
                      icon: Icons.person,
                      label: report.reportedByName!,
                    ),
                  _buildInfoChip(
                    icon: Icons.calendar_today,
                    label: _formatDate(report.reportDate),
                  ),
                  if (report.weatherCondition != null)
                    _buildInfoChip(
                      icon: Icons.wb_sunny,
                      label: report.weatherCondition!,
                    ),
                  if (report.labourCount != null)
                    _buildInfoChip(
                      icon: Icons.groups,
                      label: '${report.labourCount} workers',
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildPagination(BuildContext context, SiteReportProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Page ${provider.currentPage + 1} of ${provider.totalPages}',
            style: const TextStyle(fontSize: 14),
          ),
          Row(
            children: [
              IconButton(
                onPressed: provider.currentPage > 0
                    ? () => provider.goToPage(provider.currentPage - 1)
                    : null,
                icon: const Icon(Icons.chevron_left),
              ),
              IconButton(
                onPressed: provider.currentPage < provider.totalPages - 1
                    ? () => provider.goToPage(provider.currentPage + 1)
                    : null,
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _navigateToDetail(BuildContext context, SiteReport report) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SiteReportDetailScreen(report: report),
      ),
    );
  }

  void _navigateToCreate(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddSiteReportScreen()),
    ).then((_) {
      if (context.mounted) {
        Provider.of<SiteReportProvider>(context, listen: false).fetch();
      }
    });
  }

  void _openPhotoGallery(BuildContext context, SiteReport report, int initialIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _PhotoGalleryViewer(
          photos: report.photos,
          initialIndex: initialIndex,
          reportTitle: report.title,
        ),
      ),
    );
  }
}

/// Full screen photo gallery viewer for site report photos
class _PhotoGalleryViewer extends StatefulWidget {
  final List<SiteReportPhoto> photos;
  final int initialIndex;
  final String reportTitle;

  const _PhotoGalleryViewer({
    required this.photos,
    required this.initialIndex,
    required this.reportTitle,
  });

  @override
  State<_PhotoGalleryViewer> createState() => _PhotoGalleryViewerState();
}

class _PhotoGalleryViewerState extends State<_PhotoGalleryViewer> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.reportTitle,
              style: const TextStyle(fontSize: 16),
            ),
            Text(
              '${_currentIndex + 1} of ${widget.photos.length}',
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: widget.photos.length,
            onPageChanged: (index) => setState(() => _currentIndex = index),
            itemBuilder: (context, index) {
              final photo = widget.photos[index];
              return InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: Center(
                  child: Hero(
                    tag: 'photo_${widget.photos.hashCode}_$index',
                    child: Image.network(
                      photo.fullUrl,
                      fit: BoxFit.contain,
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            value: progress.expectedTotalBytes != null
                                ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes!
                                : null,
                            color: Colors.white,
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.broken_image, size: 64, color: Colors.white54),
                            SizedBox(height: 16),
                            Text(
                              'Failed to load image',
                              style: TextStyle(color: Colors.white70),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          ),
          // Photo thumbnails at bottom
          if (widget.photos.length > 1)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 100,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.7),
                    ],
                  ),
                ),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  itemCount: widget.photos.length,
                  itemBuilder: (context, index) {
                    final isSelected = index == _currentIndex;
                    return GestureDetector(
                      onTap: () {
                        _pageController.animateToPage(
                          index,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: isSelected ? Colors.white : Colors.transparent,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.network(
                            widget.photos[index].fullUrl,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 60,
                                height: 60,
                                color: Colors.grey[800],
                                child: const Icon(Icons.broken_image, color: Colors.grey),
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}
