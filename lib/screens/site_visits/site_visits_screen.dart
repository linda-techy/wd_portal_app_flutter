import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:admin/models/site_visit_models.dart';
import 'package:admin/providers/site_visit_provider.dart';
import 'package:admin/services/site_visit_service.dart';
import 'package:admin/widgets/common/search_bar_widget.dart';
import 'package:admin/theme/app_theme.dart';
import 'package:admin/providers/permission_provider.dart';
import 'package:admin/screens/site_visits/site_visit_check_in_dialog.dart';
import 'package:admin/screens/site_visits/site_visit_check_out_dialog.dart';
import 'package:admin/screens/site_visits/site_visit_detail_screen.dart';

class SiteVisitsScreen extends StatefulWidget {
  const SiteVisitsScreen({super.key});

  @override
  State<SiteVisitsScreen> createState() => _SiteVisitsScreenState();
}

class _SiteVisitsScreenState extends State<SiteVisitsScreen> {
  final _visitService = SiteVisitService();
  SiteVisit? _activeVisit;

  @override
  void initState() {
    super.initState();
    _loadActiveVisit();
  }

  Future<void> _loadActiveVisit() async {
    try {
      final visit = await _visitService.getMyActiveVisit();
      if (mounted) {
        setState(() {
          _activeVisit = visit;
        });
      }
    } catch (_) {
      // silently fail - active visit loading is optional
    }
  }

  Future<void> _handleCheckIn(BuildContext context, SiteVisitProvider provider) async {
    final visit = await SiteVisitCheckInDialog.show(context);
    if (visit != null && mounted) {
      setState(() => _activeVisit = visit);
      provider.fetch();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Checked in at ${visit.projectName}'),
            backgroundColor: AppTheme.successGreen,
          ),
        );
      }
    }
  }

  Future<void> _handleCheckOut(BuildContext context, SiteVisitProvider provider) async {
    if (_activeVisit == null) return;
    final visit = await SiteVisitCheckOutDialog.show(context, _activeVisit!);
    if (visit != null && mounted) {
      setState(() => _activeVisit = null);
      provider.fetch();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Checked out from ${visit.projectName}'),
            backgroundColor: AppTheme.successGreen,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SiteVisitProvider()..fetch(),
      child: Consumer<SiteVisitProvider>(
        builder: (context, provider, _) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Site Visits'),
              actions: [
                // Check-in / Check-out button
                if (_activeVisit != null)
                  TextButton.icon(
                    onPressed: () => _handleCheckOut(context, provider),
                    icon: const Icon(Icons.logout, color: AppTheme.coralRed, size: 20),
                    label: const Text(
                      'Check Out',
                      style: TextStyle(color: AppTheme.coralRed, fontWeight: FontWeight.bold),
                    ),
                  )
                else
                  Consumer<PermissionProvider>(
                    builder: (context, permissionProvider, _) {
                      if (permissionProvider.hasPermission('site_visit:create')) {
                        return TextButton.icon(
                          onPressed: () => _handleCheckIn(context, provider),
                          icon: const Icon(Icons.login, color: AppTheme.successGreen, size: 20),
                          label: const Text(
                            'Check In',
                            style: TextStyle(color: AppTheme.successGreen, fontWeight: FontWeight.bold),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
              ],
            ),
            body: Column(
              children: [
                // Active visit banner
                if (_activeVisit != null) _buildActiveVisitBanner(context, provider),
                _buildSearchAndFilters(context, provider),
                Expanded(child: _buildVisitList(context, provider)),
                if (provider.totalPages > 1)
                  _buildPagination(context, provider),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildActiveVisitBanner(BuildContext context, SiteVisitProvider provider) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.constructionOrange.withOpacity(0.1),
        border: Border(bottom: BorderSide(color: AppTheme.constructionOrange.withOpacity(0.3))),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: AppTheme.constructionOrange,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Active: ${_activeVisit!.projectName}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: AppTheme.textPrimary,
                  ),
                ),
                if (_activeVisit!.checkInTime != null)
                  Text(
                    'Since ${_activeVisit!.checkInTime!.hour.toString().padLeft(2, '0')}:${_activeVisit!.checkInTime!.minute.toString().padLeft(2, '0')}',
                    style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                  ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => _handleCheckOut(context, provider),
            child: const Text(
              'CHECK OUT',
              style: TextStyle(
                color: AppTheme.coralRed,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters(
      BuildContext context, SiteVisitProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[100],
      child: Column(
        children: [
          SearchBarWidget(
            onSearch: (query) => provider.search(query),
            hintText: 'Search site visits...',
          ),
          const SizedBox(height: 12),
          _buildFilterChips(context, provider),
        ],
      ),
    );
  }

  Widget _buildFilterChips(BuildContext context, SiteVisitProvider provider) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        // Status filters
        _buildFilterChip(
          context,
          label: 'All',
          isSelected: provider.filters['status'] == null,
          onTap: () => provider.clearFilters(),
        ),
        _buildFilterChip(
          context,
          label: 'Planned',
          isSelected: provider.filters['status'] == 'PLANNED',
          onTap: () => provider.updateFilter('status', 'PLANNED'),
        ),
        _buildFilterChip(
          context,
          label: 'Completed',
          isSelected: provider.filters['status'] == 'COMPLETED',
          onTap: () => provider.updateFilter('status', 'COMPLETED'),
        ),
        _buildFilterChip(
          context,
          label: 'Cancelled',
          isSelected: provider.filters['status'] == 'CANCELLED',
          onTap: () => provider.updateFilter('status', 'CANCELLED'),
        ),
        const SizedBox(width: 16),
        // Visit Type filters
        _buildFilterChip(
          context,
          label: 'Inspection',
          isSelected: provider.filters['visitType'] == 'INSPECTION',
          onTap: () => provider.updateFilter('visitType', 'INSPECTION'),
        ),
        _buildFilterChip(
          context,
          label: 'Progress Review',
          isSelected: provider.filters['visitType'] == 'PROGRESS_REVIEW',
          onTap: () => provider.updateFilter('visitType', 'PROGRESS_REVIEW'),
        ),
        _buildFilterChip(
          context,
          label: 'Safety Audit',
          isSelected: provider.filters['visitType'] == 'SAFETY_AUDIT',
          onTap: () => provider.updateFilter('visitType', 'SAFETY_AUDIT'),
        ),
      ],
    );
  }

  Widget _buildFilterChip(
    BuildContext context, {
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
      selectedColor: Theme.of(context).primaryColor,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildVisitList(BuildContext context, SiteVisitProvider provider) {
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
            Icon(Icons.location_on, size: 48, color: Colors.grey),
            SizedBox(height: 16),
            Text('No site visits found', style: TextStyle(fontSize: 16)),
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
          final visit = provider.items[index];
          return _buildVisitCard(context, visit);
        },
      ),
    );
  }

  Widget _buildVisitCard(BuildContext context, SiteVisit visit) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: () => _navigateToDetail(context, visit),
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
                          visit.projectName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (visit.visitType != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            visit.visitType!,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (visit.visitStatus != null)
                    _buildStatusBadge(visit.visitStatus!),
                ],
              ),
              if (visit.notes != null) ...[
                const SizedBox(height: 12),
                Text(
                  visit.notes!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  if (visit.visitedByName != null)
                    _buildInfoChip(
                      icon: Icons.person,
                      label: visit.visitedByName!,
                    ),
                  if (visit.visitDate != null)
                    _buildInfoChip(
                      icon: Icons.calendar_today,
                      label: _formatDate(visit.visitDate!),
                    ),
                  if (visit.durationMinutes != null)
                    _buildInfoChip(
                      icon: Icons.timer,
                      label: '${visit.durationMinutes} mins',
                    ),
                ],
              ),
              // GPS distance info
              if (visit.formattedCheckInDistance != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.gps_fixed, size: 14, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Text(
                      'Check-in: ${visit.formattedCheckInDistance} from site',
                      style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                    ),
                    if (visit.formattedCheckOutDistance != null) ...[
                      const SizedBox(width: 10),
                      Text(
                        '| Check-out: ${visit.formattedCheckOutDistance}',
                        style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                      ),
                    ],
                  ],
                ),
              ],
              if (visit.checkOutNotes != null &&
                  visit.checkOutNotes!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.notes, size: 16, color: Colors.blue),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Check-out notes: ${visit.checkOutNotes}',
                          style:
                              const TextStyle(fontSize: 12, color: Colors.blue),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getStatusColor(status),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildInfoChip({required IconData icon, required String label}) {
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

  Widget _buildPagination(BuildContext context, SiteVisitProvider provider) {
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

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'CHECKED_OUT':
      case 'COMPLETED':
        return AppTheme.statusSuccess;
      case 'CHECKED_IN':
        return AppTheme.constructionOrange;
      case 'PENDING':
      case 'PLANNED':
        return AppTheme.skyBlue;
      case 'CANCELLED':
        return AppTheme.statusError;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _navigateToDetail(BuildContext context, SiteVisit visit) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SiteVisitDetailScreen(
          visitId: visit.id,
          initialVisit: visit,
        ),
      ),
    );
  }
}

