import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../../data/local/photo_capture.dart';
import '../../../../services/outbox_service.dart';
import '../../../../services/site_report_service.dart';
import '../../../../services/sync_service.dart';
import '../../../../services/location_service.dart';
import '../../../../models/site_report_models.dart';
import '../../../../theme/app_theme.dart';
import '../../../../utils/error_handler.dart';
import '../../../../providers/portal_auth_provider.dart';
import '../../../../widgets/authenticated_image.dart';

// ──────────────────────────────────────────────────────────────────────────────
// Site Reports Screen – Timeline-based, GPS-enabled, photo management
// ──────────────────────────────────────────────────────────────────────────────
class SiteReportsScreen extends StatefulWidget {
  final int projectId;

  const SiteReportsScreen({super.key, required this.projectId});

  @override
  State<SiteReportsScreen> createState() => _SiteReportsScreenState();
}

class _SiteReportsScreenState extends State<SiteReportsScreen> {
  final SiteReportService _service = SiteReportService();
  List<SiteReport> _reports = [];
  bool _isPageLoading = true;
  final Set<DateTime> _expandedDates = {};

  /// Lazy-loaded "you have N reports on other projects" hint for the
  /// empty state. Fixes the support call where an admin files a report
  /// against the wrong project from a similar-named dropdown entry, then
  /// can't find it on the project they expected.
  Map<int, _ProjectReportCount>? _otherProjectsSummary;

  @override
  void initState() {
    super.initState();
    _verifyAuthAndLoadData();
  }

  Future<void> _verifyAuthAndLoadData() async {
    final authProvider =
        Provider.of<PortalAuthProvider>(context, listen: false);
    if (!authProvider.isAuthenticated) {
      if (mounted) {
        await ErrorHandler.handleAuthError(context);
        if (mounted) Navigator.of(context).pushReplacementNamed('/login');
      }
      return;
    }
    await _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isPageLoading = true);
    try {
      final reports = await _service.getReportsByProject(widget.projectId);
      setState(() {
        _reports = reports;
        _isPageLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isPageLoading = false);
        await ErrorHandler.handleApiError(context, e,
            defaultMessage: 'Failed to load site reports');
      }
    }
  }

  Future<void> _navigateToCreate() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _CreateSiteReportPage(projectId: widget.projectId),
      ),
    );
    if (result == true) await _loadData();
  }

  void _navigateToDetail(SiteReport report) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _SiteReportDetailPage(
          report: report,
          onChanged: _loadData,
        ),
      ),
    );
  }

  // Group reports by date
  Map<DateTime, List<SiteReport>> _groupByDate() {
    final grouped = <DateTime, List<SiteReport>>{};
    for (final r in _reports) {
      final d = DateTime(r.reportDate.year, r.reportDate.month, r.reportDate.day);
      grouped.putIfAbsent(d, () => []).add(r);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Site Reports'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'Create Report',
            onPressed: _navigateToCreate,
          ),
        ],
      ),
      body: _isPageLoading
          ? const Center(child: CircularProgressIndicator())
          : _reports.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: _buildTimelineView(),
                ),
    );
  }

  /// Lazy fetch: search across ALL accessible reports (no projectId
  /// filter), tally by project. Surfaced as the empty-state hint when
  /// the current project has zero reports but the user has reports
  /// elsewhere — the support call that motivated this is "I submitted
  /// a report and it's not showing up" → it's on a different project.
  Future<void> _loadOtherProjectsSummary() async {
    if (_otherProjectsSummary != null) return;
    try {
      final page = await _service.searchSiteReports(
        page: 0,
        size: 200,
        sortBy: 'reportDate',
        sortDirection: 'desc',
      );
      final tally = <int, _ProjectReportCount>{};
      for (final r in page.content) {
        final pid = r.projectId;
        if (pid == widget.projectId) continue; // skip current project
        final existing = tally[pid];
        tally[pid] = _ProjectReportCount(
          projectId: pid,
          projectName: r.projectName ?? existing?.projectName,
          count: (existing?.count ?? 0) + 1,
        );
      }
      if (mounted) setState(() => _otherProjectsSummary = tally);
    } catch (_) {
      if (mounted) setState(() => _otherProjectsSummary = const {});
    }
  }

  Widget _buildEmptyState() {
    if (_otherProjectsSummary == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadOtherProjectsSummary());
    }
    final others = (_otherProjectsSummary ?? <int, _ProjectReportCount>{}).values.toList();
    final totalElsewhere = others.fold<int>(0, (int s, r) => s + r.count);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text('No site reports yet',
                style: TextStyle(fontSize: 16, color: Colors.grey)),
            const SizedBox(height: 8),
            const Text('Tap + to create your first report',
                style: TextStyle(fontSize: 13, color: Colors.grey)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _navigateToCreate,
              icon: const Icon(Icons.add_a_photo),
              label: const Text('Create Report'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.coralRed,
                foregroundColor: Colors.white,
              ),
            ),
            if (totalElsewhere > 0) ...[
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 12),
              Text(
                'Looking for a report you just submitted? '
                'You have $totalElsewhere report${totalElsewhere == 1 ? '' : 's'} '
                'on other project${others.length == 1 ? '' : 's'}:',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              ...others.map((r) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text(
                      '• ${r.projectName ?? "Project #${r.projectId}"} — ${r.count} report${r.count == 1 ? '' : 's'}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  )),
              const SizedBox(height: 8),
              const Text(
                'Open that project to view its reports — '
                'or check the project picker on the create screen.',
                style: TextStyle(fontSize: 11, color: Colors.grey, fontStyle: FontStyle.italic),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Timeline View ──────────────────────────────────────────────────────────
  Widget _buildTimelineView() {
    final grouped = _groupByDate();
    final sortedDates = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      itemCount: sortedDates.length,
      itemBuilder: (ctx, i) {
        final date = sortedDates[i];
        final reports = grouped[date]!;
        return _buildDateGroup(date, reports);
      },
    );
  }

  Widget _buildDateGroup(DateTime date, List<SiteReport> reports) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    String dateLabel;
    if (date == today) {
      dateLabel = 'Today';
    } else if (date == yesterday) {
      dateLabel = 'Yesterday';
    } else {
      dateLabel = DateFormat('EEEE, MMMM d, y').format(date);
    }

    final isExpanded = _expandedDates.contains(date) || date == today;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Date Header ──
          InkWell(
            onTap: () {
              setState(() {
                if (_expandedDates.contains(date)) {
                  _expandedDates.remove(date);
                } else {
                  _expandedDates.add(date);
                }
              });
            },
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: date == today
                    ? AppTheme.coralRed.withOpacity(0.1)
                    : Colors.grey[100],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.calendar_today,
                      size: 14,
                      color: date == today ? AppTheme.coralRed : Colors.grey[600]),
                  const SizedBox(width: 6),
                  Text(
                    dateLabel,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: date == today ? AppTheme.coralRed : Colors.grey[800],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: date == today
                          ? AppTheme.coralRed.withOpacity(0.2)
                          : Colors.grey[200],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${reports.length}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: date == today ? AppTheme.coralRed : Colors.grey[700],
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  AnimatedRotation(
                    turns: isExpanded ? 0.0 : -0.25,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(Icons.expand_more,
                        size: 18,
                        color: date == today ? AppTheme.coralRed : Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          // ── Reports for this date ──
          AnimatedCrossFade(
            firstChild: Column(
              children: reports.asMap().entries.map((entry) {
                final idx = entry.key;
                final report = entry.value;
                final isLast = idx == reports.length - 1;
                return _buildTimelineItem(report, isLast);
              }).toList(),
            ),
            secondChild: const SizedBox.shrink(),
            crossFadeState:
                isExpanded ? CrossFadeState.showFirst : CrossFadeState.showSecond,
            duration: const Duration(milliseconds: 250),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(SiteReport report, bool isLast) {
    final timeStr = DateFormat('h:mm a').format(report.reportDate);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Timeline line + dot ──
          SizedBox(
            width: 32,
            child: Column(
              children: [
                const SizedBox(height: 14),
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: AppTheme.coralRed,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.coralRed.withOpacity(0.3),
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
          // ── Report Card ──
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(left: 8, bottom: isLast ? 0 : 16),
              child: _buildReportCard(report, timeStr),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteReport(SiteReport report) async {
    if (report.id == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Site Report'),
        content: Text(
            'Are you sure you want to delete "${report.title}"? This will permanently remove the report and all its photos.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child:
                  const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _service.deleteReport(report.id!);
      setState(() {
        _reports.removeWhere((r) => r.id == report.id);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Site report deleted'),
              backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        await ErrorHandler.handleApiError(context, e,
            defaultMessage: 'Failed to delete site report');
      }
    }
  }

  Widget _buildReportCard(SiteReport report, String timeStr) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _navigateToDetail(report),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Title row ──
              Row(
                children: [
                  Expanded(
                    child: Text(report.title,
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.bold)),
                  ),
                  Text(timeStr,
                      style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                  const SizedBox(width: 4),
                  PopupMenuButton<String>(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    iconSize: 20,
                    icon: Icon(Icons.more_vert,
                        size: 18, color: Colors.grey[500]),
                    onSelected: (value) {
                      if (value == 'delete') {
                        _deleteReport(report);
                      }
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline,
                                size: 18, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete',
                                style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 6),
              // ── Description ──
              if (report.description != null && report.description!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(report.description!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 13, color: Colors.grey[700])),
                ),
              // ── Photo thumbnails ──
              if (report.photos.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: SizedBox(
                    height: 64,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount:
                          report.photos.length > 4 ? 5 : report.photos.length,
                      itemBuilder: (ctx, i) {
                        if (i == 4 && report.photos.length > 4) {
                          return Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text('+${report.photos.length - 4}',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey[600])),
                            ),
                          );
                        }
                        final photo = report.photos[i];
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: AuthenticatedImage(
                            imageUrl: photo.fullUrl,
                            width: 64,
                            height: 64,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              // ── Metadata chips ──
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  _chip(Icons.category, report.reportType.label),
                  if (report.submittedByName != null)
                    _chip(Icons.person, report.submittedByName!),
                  if (report.photos.isNotEmpty)
                    _chip(Icons.photo_library, '${report.photos.length} photos'),
                  if (report.latitude != null && report.longitude != null)
                    _chip(
                      Icons.location_on,
                      report.distanceFromProject != null
                          ? '${report.distanceFromProject!.toStringAsFixed(1)} km'
                          : 'GPS',
                      color: Colors.green,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(IconData icon, String label, {Color? color}) {
    final c = color ?? Colors.grey[700]!;
    final bg = color?.withOpacity(0.1) ?? Colors.grey[100]!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: c),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 11, color: c)),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// CREATE SITE REPORT – Full-page with GPS, inline images, progress
// ═══════════════════════════════════════════════════════════════════════════════
class _CreateSiteReportPage extends StatefulWidget {
  final int projectId;
  const _CreateSiteReportPage({required this.projectId});

  @override
  State<_CreateSiteReportPage> createState() => _CreateSiteReportPageState();
}

class _CreateSiteReportPageState extends State<_CreateSiteReportPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  // PR2: SiteReportService instance is built at submit time via
  // [SiteReportService.forOutbox]; no long-lived field needed here.
  final _picker = ImagePicker();

  ReportType _type = ReportType.dailyProgress;
  final List<XFile> _photos = [];
  bool _isSaving = false;
  double _uploadProgress = 0.0;

  // GPS state
  double? _latitude;
  double? _longitude;
  double? _accuracy;
  bool _isCapturingLocation = false;
  bool _locationCaptured = false;
  String? _locationError;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  // ── GPS Capture ──
  Future<void> _captureLocation() async {
    setState(() {
      _isCapturingLocation = true;
      _locationError = null;
    });
    try {
      final pos = await LocationService.getCurrentPosition();
      setState(() {
        _latitude = pos.latitude;
        _longitude = pos.longitude;
        _accuracy = pos.accuracy;
        _locationCaptured = true;
        _isCapturingLocation = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location captured successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } on LocationException catch (e) {
      setState(() {
        _locationError = e.message;
        _isCapturingLocation = false;
      });
    } catch (e) {
      setState(() {
        _locationError = 'Failed to capture location';
        _isCapturingLocation = false;
      });
    }
  }

  // ── Photo picking ──
  Future<void> _pickFromGallery() async {
    final imgs = await _picker.pickMultiImage(imageQuality: 70);
    if (imgs.isNotEmpty) setState(() => _photos.addAll(imgs));
  }

  Future<void> _pickFromCamera() async {
    final img =
        await _picker.pickImage(source: ImageSource.camera, imageQuality: 70);
    if (img != null) setState(() => _photos.add(img));
  }

  void _removePhoto(int index) => setState(() => _photos.removeAt(index));

  // ── Submit ──
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_photos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please attach at least one photo'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
      _uploadProgress = 0.0;
    });

    try {
      // PR2: capture the providers BEFORE any async work — once we await,
      // the BuildContext can't be safely used across the gap.
      final outbox = context.read<OutboxService>();
      final sync = context.read<SyncService>();

      // Simulate upload progress
      for (int i = 0; i < 5; i++) {
        await Future.delayed(const Duration(milliseconds: 100));
        if (mounted) {
          setState(() => _uploadProgress = (i + 1) / 5 * 0.8);
        }
      }

      // PR2: route through outbox so the report survives offline use.
      final svc = SiteReportService.forOutbox(outbox: outbox, sync: sync);

      PhotoCapture? primary;
      if (_photos.isNotEmpty) {
        final first = _photos.first;
        primary = PhotoCapture(
          file: File(first.path),
          latitude: _latitude,
          longitude: _longitude,
          accuracyMeters: _accuracy,
          capturedAt: DateTime.now(),
        );
      }

      await svc.createReportQueued(
        projectId: widget.projectId,
        title: _titleCtrl.text,
        description: _descCtrl.text,
        reportType: _type,
        primaryPhoto: primary,
        latitude: _latitude,
        longitude: _longitude,
        locationAccuracy: _accuracy,
      );

      if (mounted) {
        setState(() => _uploadProgress = 1.0);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Queued — will upload when online'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        await ErrorHandler.handleApiError(context, e,
            defaultMessage: 'Failed to submit report');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Site Report'),
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: AppTheme.coralRed)),
            )
          else
            TextButton(
              onPressed: _submit,
              child: const Text('SUBMIT',
                  style: TextStyle(
                      color: AppTheme.coralRed, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Report Type ──
                  const Text('Report Type',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: ReportType.values.map((t) {
                      final sel = _type == t;
                      return ChoiceChip(
                        label: Text(t.label),
                        selected: sel,
                        onSelected: (s) {
                          if (s) setState(() => _type = t);
                        },
                        selectedColor: AppTheme.coralRed.withOpacity(0.2),
                        labelStyle: TextStyle(
                          color: sel ? AppTheme.coralRed : Colors.black87,
                          fontWeight: sel ? FontWeight.bold : FontWeight.normal,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  // ── Title ──
                  TextFormField(
                    controller: _titleCtrl,
                    decoration: InputDecoration(
                      labelText: 'Title *',
                      hintText: 'e.g., Foundation Progress',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Title is required' : null,
                  ),
                  const SizedBox(height: 16),
                  // ── Description ──
                  TextFormField(
                    controller: _descCtrl,
                    maxLines: 4,
                    decoration: InputDecoration(
                      labelText: 'Description *',
                      hintText: 'Detail the observations...',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    validator: (v) => v == null || v.isEmpty
                        ? 'Description is required'
                        : null,
                  ),
                  const SizedBox(height: 20),
                  // ── GPS Section ──
                  _buildGpsSection(),
                  const SizedBox(height: 20),
                  // ── Photos Section ──
                  _buildPhotoSection(),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
          // ── Upload progress overlay ──
          if (_isSaving)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                color: Colors.white,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: _uploadProgress,
                              minHeight: 8,
                              backgroundColor: Colors.grey[200],
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                  AppTheme.coralRed),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text('${(_uploadProgress * 100).toInt()}%',
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text('Uploading report and ${_photos.length} photos...',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── GPS Section ──────────────────────────────────────────────────────────
  Widget _buildGpsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.location_on, color: AppTheme.coralRed, size: 20),
            SizedBox(width: 8),
            Text('GPS Location',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        const SizedBox(height: 10),
        if (!_locationCaptured && !_isCapturingLocation)
          InkWell(
            onTap: _captureLocation,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!, style: BorderStyle.solid),
              ),
              child: Column(
                children: [
                  Icon(Icons.gps_fixed, size: 36, color: Colors.grey[500]),
                  const SizedBox(height: 8),
                  const Text('Tap to Capture Location',
                      style: TextStyle(
                          fontWeight: FontWeight.w600, color: AppTheme.coralRed)),
                  const SizedBox(height: 4),
                  Text('Records your GPS coordinates',
                      style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                ],
              ),
            ),
          )
        else if (_isCapturingLocation)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2)),
                SizedBox(width: 12),
                Text('Acquiring GPS signal...',
                    style: TextStyle(color: Colors.blue)),
              ],
            ),
          )
        else
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 20),
                    SizedBox(width: 8),
                    Text('Location Captured',
                        style: TextStyle(
                            color: Colors.green, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Lat: ${_latitude?.toStringAsFixed(6)}  Lng: ${_longitude?.toStringAsFixed(6)}',
                  style: const TextStyle(fontSize: 13, fontFamily: 'monospace'),
                ),
                if (_accuracy != null)
                  Text('Accuracy: ±${_accuracy!.toStringAsFixed(1)} m',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: _captureLocation,
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Recapture'),
                    style: TextButton.styleFrom(
                        foregroundColor: AppTheme.coralRed,
                        padding: EdgeInsets.zero),
                  ),
                ),
              ],
            ),
          ),
        if (_locationError != null && !_isCapturingLocation && !_locationCaptured)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(_locationError!,
                        style: const TextStyle(color: Colors.red, fontSize: 12)),
                  ),
                  TextButton(
                    onPressed: _captureLocation,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  // ── Photo Section ────────────────────────────────────────────────────────
  Widget _buildPhotoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.photo_library, color: AppTheme.coralRed, size: 20),
            const SizedBox(width: 8),
            const Text('Photos',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(width: 4),
            const Text('*',
                style: TextStyle(
                    color: Colors.red,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.camera_alt, color: AppTheme.coralRed),
              onPressed: _pickFromCamera,
              tooltip: 'Take Photo',
            ),
            IconButton(
              icon: const Icon(Icons.photo_library, color: AppTheme.coralRed),
              onPressed: _pickFromGallery,
              tooltip: 'Choose from Gallery',
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_photos.isEmpty)
          InkWell(
            onTap: _pickFromGallery,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: double.infinity,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: Colors.red.shade200, style: BorderStyle.solid),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_photo_alternate,
                      size: 36, color: Colors.red[300]),
                  const SizedBox(height: 8),
                  const Text('Tap to add photos (required)',
                      style: TextStyle(
                          color: Colors.red, fontWeight: FontWeight.w500)),
                  Text('Camera or Gallery',
                      style: TextStyle(fontSize: 12, color: Colors.red[300])),
                ],
              ),
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: _photos.length + 1,
            itemBuilder: (ctx, i) {
              // Add-more button
              if (i == _photos.length) {
                return InkWell(
                  onTap: _pickFromGallery,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add, size: 28, color: Colors.grey[500]),
                        Text('Add',
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey[500])),
                      ],
                    ),
                  ),
                );
              }
              // Photo tile
              return Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: FutureBuilder<Uint8List>(
                      future: _photos[i].readAsBytes(),
                      builder: (ctx, snap) {
                        if (!snap.hasData) {
                          return Container(
                            color: Colors.grey[200],
                            child: const Center(
                                child: CircularProgressIndicator(
                                    strokeWidth: 2)),
                          );
                        }
                        return Image.memory(
                          snap.data!,
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                        );
                      },
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () => _removePhoto(i),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                            color: Colors.white, shape: BoxShape.circle),
                        child: const Icon(Icons.close,
                            size: 16, color: Colors.red),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// SITE REPORT DETAIL – View + manage photos
// ═══════════════════════════════════════════════════════════════════════════════
class _SiteReportDetailPage extends StatefulWidget {
  final SiteReport report;
  final VoidCallback onChanged;

  const _SiteReportDetailPage({required this.report, required this.onChanged});

  @override
  State<_SiteReportDetailPage> createState() => _SiteReportDetailPageState();
}

class _SiteReportDetailPageState extends State<_SiteReportDetailPage> {
  final SiteReportService _service = SiteReportService();
  final ImagePicker _picker = ImagePicker();
  late SiteReport _report;
  bool _isAddingPhotos = false;

  @override
  void initState() {
    super.initState();
    _report = widget.report;
  }

  Future<void> _addPhotos() async {
    final imgs = await _picker.pickMultiImage(imageQuality: 70);
    if (imgs.isEmpty || _report.id == null) return;

    setState(() => _isAddingPhotos = true);
    try {
      final updated = await _service.addPhotosToReport(_report.id!, imgs);
      setState(() {
        _report = updated;
        _isAddingPhotos = false;
      });
      widget.onChanged();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${imgs.length} photo(s) added'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _isAddingPhotos = false);
      if (mounted) {
        await ErrorHandler.handleApiError(context, e,
            defaultMessage: 'Failed to add photos');
      }
    }
  }

  Future<void> _deletePhoto(SiteReportPhoto photo) async {
    if (_report.id == null || photo.id == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Photo'),
        content: const Text('Are you sure you want to delete this photo?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _service.deletePhoto(_report.id!, photo.id!);
      setState(() {
        _report = SiteReport(
          id: _report.id,
          projectId: _report.projectId,
          title: _report.title,
          description: _report.description,
          reportDate: _report.reportDate,
          status: _report.status,
          reportType: _report.reportType,
          siteVisitId: _report.siteVisitId,
          photos: _report.photos.where((p) => p.id != photo.id).toList(),
          submittedByName: _report.submittedByName,
          latitude: _report.latitude,
          longitude: _report.longitude,
          locationAccuracy: _report.locationAccuracy,
          distanceFromProject: _report.distanceFromProject,
        );
      });
      widget.onChanged();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Photo deleted'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        await ErrorHandler.handleApiError(context, e,
            defaultMessage: 'Failed to delete photo');
      }
    }
  }

  void _openFullScreenPhoto(int initialIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _FullScreenPhotoViewer(
          photos: _report.photos,
          initialIndex: initialIndex,
          onDelete: _deletePhoto,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_report.title),
        actions: [
          if (_isAddingPhotos)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else
            IconButton(
              icon: const Icon(Icons.add_photo_alternate),
              onPressed: _addPhotos,
              tooltip: 'Add Photos',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Info Card ──
            _buildInfoCard(),
            const SizedBox(height: 16),
            // ── GPS Card ──
            if (_report.latitude != null && _report.longitude != null)
              _buildGpsCard(),
            if (_report.latitude != null && _report.longitude != null)
              const SizedBox(height: 16),
            // ── Description ──
            if (_report.description != null && _report.description!.isNotEmpty)
              _buildDescriptionCard(),
            if (_report.description != null && _report.description!.isNotEmpty)
              const SizedBox(height: 16),
            // ── Photos ──
            _buildPhotosSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.coralRed.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(_report.reportType.label,
                      style: const TextStyle(
                          color: AppTheme.coralRed,
                          fontWeight: FontWeight.w600,
                          fontSize: 12)),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(_report.status,
                      style: const TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.w600,
                          fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _infoRow(Icons.calendar_today, 'Date', _report.formattedDate),
            if (_report.submittedByName != null)
              _infoRow(Icons.person, 'Submitted by', _report.submittedByName!),
            _infoRow(Icons.photo_library, 'Photos', '${_report.photos.length}'),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(icon, size: 15, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text('$label: ',
              style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 13,
                  fontWeight: FontWeight.w500)),
          Expanded(
              child: Text(value,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }

  Widget _buildGpsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.location_on, size: 18, color: Colors.green),
                SizedBox(width: 6),
                Text('GPS Location',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Lat: ${_report.latitude!.toStringAsFixed(6)}   Lng: ${_report.longitude!.toStringAsFixed(6)}',
              style: const TextStyle(fontSize: 13, fontFamily: 'monospace'),
            ),
            if (_report.distanceFromProject != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.straighten, size: 14, color: Colors.blue),
                  const SizedBox(width: 6),
                  Text(
                    'Distance from project: ${_report.distanceFromProject!.toStringAsFixed(2)} km',
                    style: const TextStyle(fontSize: 13, color: Colors.blue),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDescriptionCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Description',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 8),
            Text(_report.description!,
                style: TextStyle(color: Colors.grey[700], height: 1.5)),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotosSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Photos (${_report.photos.length})',
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const Spacer(),
            TextButton.icon(
              onPressed: _addPhotos,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add More'),
              style: TextButton.styleFrom(foregroundColor: AppTheme.coralRed),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_report.photos.isEmpty)
          Card(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(Icons.photo_library_outlined,
                      size: 48, color: Colors.grey[400]),
                  const SizedBox(height: 8),
                  Text('No photos attached',
                      style: TextStyle(color: Colors.grey[500])),
                ],
              ),
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: _report.photos.length,
            itemBuilder: (ctx, i) {
              final photo = _report.photos[i];
              return Stack(
                children: [
                  GestureDetector(
                    onTap: () => _openFullScreenPhoto(i),
                    child: AuthenticatedImage(
                      imageUrl: photo.fullUrl,
                      width: double.infinity,
                      height: double.infinity,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  // Delete button
                  Positioned(
                    top: 6,
                    right: 6,
                    child: GestureDetector(
                      onTap: () => _deletePhoto(photo),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.delete,
                            size: 16, color: Colors.white),
                      ),
                    ),
                  ),
                  // Caption
                  if (photo.caption != null && photo.caption!.isNotEmpty)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(10),
                            bottomRight: Radius.circular(10),
                          ),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.7),
                            ],
                          ),
                        ),
                        child: Text(photo.caption!,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 11),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ),
                    ),
                ],
              );
            },
          ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Full-Screen Photo Viewer
// ═══════════════════════════════════════════════════════════════════════════════
class _FullScreenPhotoViewer extends StatefulWidget {
  final List<SiteReportPhoto> photos;
  final int initialIndex;
  final Function(SiteReportPhoto) onDelete;

  const _FullScreenPhotoViewer({
    required this.photos,
    required this.initialIndex,
    required this.onDelete,
  });

  @override
  State<_FullScreenPhotoViewer> createState() => _FullScreenPhotoViewerState();
}

class _FullScreenPhotoViewerState extends State<_FullScreenPhotoViewer> {
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
        title: Text('${_currentIndex + 1} / ${widget.photos.length}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: () {
              widget.onDelete(widget.photos[_currentIndex]);
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.photos.length,
        onPageChanged: (i) => setState(() => _currentIndex = i),
        itemBuilder: (ctx, i) {
          final photo = widget.photos[i];
          return InteractiveViewer(
            minScale: 0.5,
            maxScale: 4.0,
            child: Center(
              child: AuthenticatedImage(
                imageUrl: photo.fullUrl,
                fit: BoxFit.contain,
                placeholder: const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
                errorWidget: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.broken_image, color: Colors.white54, size: 48),
                    SizedBox(height: 8),
                    Text('Failed to load',
                        style: TextStyle(color: Colors.white54)),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Tally row for the empty-state hint that surfaces the
/// "you have N reports on other projects" message when the user
/// is looking at a project with zero reports.
class _ProjectReportCount {
  final int projectId;
  final String? projectName;
  final int count;
  const _ProjectReportCount({
    required this.projectId,
    this.projectName,
    required this.count,
  });
}
