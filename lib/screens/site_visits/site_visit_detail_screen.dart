import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:admin/models/site_visit_models.dart';
import 'package:admin/providers/permission_provider.dart';
import 'package:admin/services/site_visit_service.dart';
import 'package:admin/theme/app_theme.dart';
import 'package:intl/intl.dart';

/// Detail screen for a site visit showing all info including GPS location data.
class SiteVisitDetailScreen extends StatefulWidget {
  final int visitId;
  final SiteVisit? initialVisit;

  const SiteVisitDetailScreen({
    super.key,
    required this.visitId,
    this.initialVisit,
  });

  @override
  State<SiteVisitDetailScreen> createState() => _SiteVisitDetailScreenState();
}

class _SiteVisitDetailScreenState extends State<SiteVisitDetailScreen> {
  final _visitService = SiteVisitService();
  SiteVisit? _visit;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _visit = widget.initialVisit;
    _loadVisit();
  }

  Future<void> _loadVisit() async {
    try {
      final visit = await _visitService.getVisitById(widget.visitId);
      if (mounted) {
        setState(() {
          _visit = visit;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final canForceClose = context.select<PermissionProvider, bool>(
        (p) => p.hasPermission('SITE_VISIT_FORCE_CLOSE'));
    final v = _visit;
    final showForceCloseAction =
        v != null && v.isActive && canForceClose;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Site Visit Details'),
        actions: [
          if (showForceCloseAction)
            IconButton(
              tooltip: 'Force-close this visit (bypasses GPS check)',
              icon: const Icon(Icons.lock_clock, color: AppTheme.coralRed),
              onPressed: _confirmForceClose,
            ),
        ],
      ),
      body: _isLoading && _visit == null
          ? const Center(child: CircularProgressIndicator())
          : _error != null && _visit == null
              ? _buildError()
              : _visit != null
                  ? _buildContent()
                  : const SizedBox.shrink(),
    );
  }

  Future<void> _confirmForceClose() async {
    final v = _visit;
    if (v == null) return;

    final controller = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Force-close visit?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You are closing ${v.visitedByName ?? "this user"}\'s active visit '
              'at ${v.projectName} without GPS validation. The action is permanent and '
              'is recorded against your account.',
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              minLines: 2,
              maxLines: 4,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Reason (required)',
                hintText: 'e.g. Lost phone, dead GPS, geofence policy change',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.coralRed, foregroundColor: Colors.white),
            onPressed: () {
              if (controller.text.trim().isEmpty) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('A reason is required.')),
                );
                return;
              }
              Navigator.of(ctx).pop(true);
            },
            child: const Text('Force close'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final updated =
          await _visitService.forceClose(v.id, controller.text.trim());
      if (!mounted) return;
      setState(() => _visit = updated);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Visit force-closed.'),
          backgroundColor: AppTheme.successGreen,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Force-close failed: $e'),
          backgroundColor: AppTheme.errorRed,
        ),
      );
    }
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: AppTheme.errorRed),
          const SizedBox(height: 16),
          Text('Error: $_error'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadVisit,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final visit = _visit!;
    return RefreshIndicator(
      onRefresh: _loadVisit,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Status and project header
          _buildHeader(visit),
          const SizedBox(height: 16),
          // Visit info card
          _buildInfoCard(visit),
          const SizedBox(height: 16),
          // Check-in / Check-out timeline
          _buildTimeline(visit),
          const SizedBox(height: 16),
          // GPS Location Data
          if (visit.checkInLatitude != null || visit.checkOutLatitude != null)
            _buildGpsCard(visit),
          const SizedBox(height: 16),
          // Notes
          if (visit.notes != null && visit.notes!.isNotEmpty)
            _buildNotesCard('Visit Notes', visit.notes!, Icons.notes),
          if (visit.checkOutNotes != null &&
              visit.checkOutNotes!.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildNotesCard(
                'Check-out Notes', visit.checkOutNotes!, Icons.logout),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader(SiteVisit visit) {
    return Card(
      elevation: 0,
      color: AppTheme.deepSlate.withOpacity(0.05),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color:
                    _getStatusColor(visit.visitStatus ?? '').withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _getStatusIcon(visit.visitStatus ?? ''),
                color: _getStatusColor(visit.visitStatus ?? ''),
                size: 28,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    visit.projectName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _buildStatusBadge(visit.visitStatus ?? 'UNKNOWN'),
                      const SizedBox(width: 8),
                      if (visit.visitType != null)
                        Text(
                          visit.visitType!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(SiteVisit visit) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppTheme.borderLight.withOpacity(0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Visit Information',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            if (visit.visitedByName != null)
              _buildInfoRow(Icons.person, 'Visited By', visit.visitedByName!),
            if (visit.visitDate != null)
              _buildInfoRow(
                Icons.calendar_today,
                'Visit Date',
                DateFormat('EEEE, MMM d, yyyy').format(visit.visitDate!),
              ),
            if (visit.formattedDuration != null)
              _buildInfoRow(Icons.timer, 'Duration', visit.formattedDuration!),
            if (visit.durationMinutes != null &&
                visit.formattedDuration == null)
              _buildInfoRow(
                  Icons.timer, 'Duration', '${visit.durationMinutes} min'),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeline(SiteVisit visit) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppTheme.borderLight.withOpacity(0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Check-In / Check-Out',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            // Check-in
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppTheme.successGreen.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.login,
                          size: 16, color: AppTheme.successGreen),
                    ),
                    Container(
                      width: 2,
                      height: 30,
                      color: visit.checkOutTime != null
                          ? AppTheme.successGreen.withOpacity(0.3)
                          : AppTheme.borderLight,
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Check-In',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      if (visit.checkInTime != null)
                        Text(
                          DateFormat('MMM d, yyyy • h:mm a')
                              .format(visit.checkInTime!),
                          style: const TextStyle(
                              fontSize: 13, color: AppTheme.textSecondary),
                        ),
                      if (visit.formattedCheckInDistance != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Row(
                            children: [
                              const Icon(Icons.gps_fixed,
                                  size: 12, color: AppTheme.successGreen),
                              const SizedBox(width: 4),
                              Text(
                                '${visit.formattedCheckInDistance} from site',
                                style: const TextStyle(
                                    fontSize: 12, color: AppTheme.successGreen),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            // Check-out
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: visit.checkOutTime != null
                        ? AppTheme.coralRed.withOpacity(0.1)
                        : AppTheme.borderLight.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.logout,
                    size: 16,
                    color: visit.checkOutTime != null
                        ? AppTheme.coralRed
                        : AppTheme.textTertiary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Check-Out',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: visit.checkOutTime != null
                              ? AppTheme.textPrimary
                              : AppTheme.textTertiary,
                        ),
                      ),
                      if (visit.checkOutTime != null)
                        Text(
                          DateFormat('MMM d, yyyy • h:mm a')
                              .format(visit.checkOutTime!),
                          style: const TextStyle(
                              fontSize: 13, color: AppTheme.textSecondary),
                        )
                      else
                        const Text(
                          'Not checked out yet',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.textTertiary,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      if (visit.formattedCheckOutDistance != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Row(
                            children: [
                              const Icon(Icons.gps_fixed,
                                  size: 12, color: AppTheme.successGreen),
                              const SizedBox(width: 4),
                              Text(
                                '${visit.formattedCheckOutDistance} from site',
                                style: const TextStyle(
                                    fontSize: 12, color: AppTheme.successGreen),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGpsCard(SiteVisit visit) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppTheme.borderLight.withOpacity(0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.gps_fixed, size: 18, color: AppTheme.textSecondary),
                SizedBox(width: 8),
                Text(
                  'GPS Location Data',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (visit.checkInLatitude != null && visit.checkInLongitude != null)
              _buildGpsRow(
                'Check-in',
                visit.checkInLatitude!,
                visit.checkInLongitude!,
                visit.formattedCheckInDistance,
              ),
            if (visit.checkOutLatitude != null &&
                visit.checkOutLongitude != null) ...[
              const SizedBox(height: 8),
              _buildGpsRow(
                'Check-out',
                visit.checkOutLatitude!,
                visit.checkOutLongitude!,
                visit.formattedCheckOutDistance,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildGpsRow(String label, double lat, double lng, String? distance) {
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
          ),
        ),
        Expanded(
          child: Text(
            '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}',
            style: const TextStyle(fontSize: 13, fontFamily: 'monospace'),
          ),
        ),
        if (distance != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppTheme.successGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              distance,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.successGreen,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildNotesCard(String title, String content, IconData icon) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppTheme.borderLight.withOpacity(0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: AppTheme.textSecondary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              content,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppTheme.textSecondary),
          const SizedBox(width: 8),
          SizedBox(
            width: 90,
            child: Text(
              label,
              style:
                  const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _getStatusColor(status),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        _formatStatus(status),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'CHECKED_IN':
        return AppTheme.constructionOrange;
      case 'CHECKED_OUT':
        return AppTheme.successGreen;
      case 'PENDING':
        return AppTheme.skyBlue;
      case 'CANCELLED':
        return AppTheme.errorRed;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toUpperCase()) {
      case 'CHECKED_IN':
        return Icons.location_on;
      case 'CHECKED_OUT':
        return Icons.check_circle;
      case 'PENDING':
        return Icons.schedule;
      case 'CANCELLED':
        return Icons.cancel;
      default:
        return Icons.info;
    }
  }

  String _formatStatus(String status) {
    return status.replaceAll('_', ' ');
  }
}
