import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:admin/services/observation_service.dart';
import 'package:admin/theme/app_theme.dart';
import 'package:admin/utils/error_handler.dart';
import 'package:admin/utils/file_upload_helper.dart';
import 'package:admin/providers/portal_auth_provider.dart';
import 'package:admin/services/reports/observation_report.dart';
import 'dart:io' show File;

class ObservationsScreen extends StatefulWidget {
  final int projectId;

  const ObservationsScreen({super.key, required this.projectId});

  @override
  State<ObservationsScreen> createState() => _ObservationsScreenState();
}

class _ObservationsScreenState extends State<ObservationsScreen>
    with SingleTickerProviderStateMixin {
  final ObservationService _service = ObservationService();
  late TabController _tabController;
  List<ObservationItem> _active = [];
  List<ObservationItem> _resolved = [];
  bool _isLoading = true;
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _verifyAuthAndLoadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _exportPdf() async {
    setState(() => _isExporting = true);
    try {
      await ObservationReport.generate(
        projectName: 'Project',
        active: _active,
        resolved: _resolved,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDF export failed: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _verifyAuthAndLoadData() async {
    final authProvider =
        Provider.of<PortalAuthProvider>(context, listen: false);
    if (!authProvider.isAuthenticated) {
      if (mounted) {
        await ErrorHandler.handleAuthError(context);
      }
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
      return;
    }
    await _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _service.getActiveObservations(widget.projectId),
        _service.getResolvedObservations(widget.projectId),
      ]);
      if (mounted) {
        setState(() {
          _active = results[0];
          _resolved = results[1];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        await ErrorHandler.handleApiError(context, e,
            defaultMessage: 'Failed to load observations');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Snags / Observations'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Active (${_active.length})'),
            Tab(text: 'Resolved (${_resolved.length})'),
          ],
        ),
        actions: [
          IconButton(
            icon: _isExporting
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.download_outlined),
            tooltip: 'Export PDF',
            onPressed: _isExporting ? null : _exportPdf,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateDialog,
        backgroundColor: AppTheme.deepSlate,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildList(_active, isActive: true),
                _buildList(_resolved, isActive: false),
              ],
            ),
    );
  }

  Widget _buildList(List<ObservationItem> items, {required bool isActive}) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isActive ? Icons.warning_amber_rounded : Icons.check_circle_outline,
              size: 48,
              color: Colors.grey,
            ),
            const SizedBox(height: 12),
            Text(
              isActive ? 'No active snags' : 'No resolved snags',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        itemBuilder: (context, index) => _buildCard(items[index]),
      ),
    );
  }

  Widget _buildCard(ObservationItem item) {
    final priorityColor = _getPriorityColor(item.priority);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppTheme.borderLight.withOpacity(0.5)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showDetail(item),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (item.priority != null) ...[
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: priorityColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        item.priority!.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: priorityColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  _buildStatusChip(item.status),
                  const Spacer(),
                  Text(
                    DateFormat('MMM d').format(item.createdAt),
                    style: const TextStyle(
                        fontSize: 12, color: AppTheme.textTertiary),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                item.title,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (item.description.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  item.description,
                  style: const TextStyle(
                      fontSize: 13, color: AppTheme.textSecondary),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (item.location != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined,
                        size: 14, color: AppTheme.textTertiary),
                    const SizedBox(width: 4),
                    Text(item.location!,
                        style: const TextStyle(
                            fontSize: 12, color: AppTheme.textTertiary)),
                  ],
                ),
              ],
              if (item.reportedByName != null) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.person_outline,
                        size: 14, color: AppTheme.textTertiary),
                    const SizedBox(width: 4),
                    Text(item.reportedByName!,
                        style: const TextStyle(
                            fontSize: 12, color: AppTheme.textTertiary)),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    final color = _getStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status.replaceAll('_', ' '),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  void _showDetail(ObservationItem item) {
    final dateFormat = DateFormat('MMM d, yyyy • h:mm a');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.65,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Padding(
          padding: const EdgeInsets.all(20),
          child: ListView(
            controller: scrollController,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  if (item.priority != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color:
                            _getPriorityColor(item.priority).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${item.priority!.toUpperCase()} Priority',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: _getPriorityColor(item.priority),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  _buildStatusChip(item.status),
                ],
              ),
              const SizedBox(height: 16),
              Text(item.title,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              if (item.description.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(item.description,
                    style: const TextStyle(
                        fontSize: 14, color: AppTheme.textSecondary, height: 1.5)),
              ],
              const SizedBox(height: 16),
              if (item.location != null)
                _buildInfoRow(Icons.location_on, 'Location', item.location!),
              if (item.reportedByName != null)
                _buildInfoRow(
                    Icons.person, 'Reported by', item.reportedByName!),
              _buildInfoRow(Icons.calendar_today, 'Reported',
                  dateFormat.format(item.createdAt)),
              // Resolution info
              if (!item.isActive) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.successGreen.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: AppTheme.successGreen.withOpacity(0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.check_circle,
                              color: AppTheme.successGreen, size: 18),
                          SizedBox(width: 8),
                          Text('Resolved',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.successGreen)),
                        ],
                      ),
                      if (item.resolvedByName != null) ...[
                        const SizedBox(height: 8),
                        Text('By: ${item.resolvedByName}',
                            style: const TextStyle(fontSize: 13)),
                      ],
                      if (item.resolvedDate != null) ...[
                        const SizedBox(height: 4),
                        Text(
                            'On: ${dateFormat.format(item.resolvedDate!)}',
                            style: const TextStyle(fontSize: 13)),
                      ],
                      if (item.resolutionNotes != null) ...[
                        const SizedBox(height: 8),
                        Text(item.resolutionNotes!,
                            style: const TextStyle(
                                fontSize: 13, fontStyle: FontStyle.italic)),
                      ],
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),
              // Action buttons
              if (item.isActive)
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _resolveObservation(item);
                        },
                        icon: const Icon(Icons.check_circle,
                            size: 18, color: Colors.white),
                        label: const Text('Resolve',
                            style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.successGreen,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _confirmDelete(item);
                        },
                        icon: const Icon(Icons.delete_outline, size: 18),
                        label: const Text('Delete'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.errorRed,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppTheme.textSecondary),
          const SizedBox(width: 8),
          Text('$label: ',
              style: const TextStyle(
                  fontSize: 13, color: AppTheme.textSecondary)),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  Future<void> _showCreateDialog() async {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    final locationController = TextEditingController();
    String priority = 'MEDIUM';
    File? pickedFile;
    Uint8List? pickedBytes;
    String? pickedFileName;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Report Snag'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Title *'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(labelText: 'Description *'),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: priority,
                  decoration: const InputDecoration(labelText: 'Priority'),
                  items: ['LOW', 'MEDIUM', 'HIGH', 'CRITICAL']
                      .map((p) =>
                          DropdownMenuItem(value: p, child: Text(p)))
                      .toList(),
                  onChanged: (v) => setDialogState(() => priority = v!),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: locationController,
                  decoration:
                      const InputDecoration(labelText: 'Location (optional)'),
                ),
                const SizedBox(height: 12),
                // Image picker row
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        pickedFileName ?? 'No photo selected',
                        style: TextStyle(
                          fontSize: 12,
                          color: pickedFileName != null
                              ? AppTheme.deepSlate
                              : AppTheme.textTertiary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final result = await FilePicker.platform.pickFiles(
                          type: FileType.image,
                          withData: kIsWeb,
                        );
                        if (result != null) {
                          try {
                            final data = FileUploadHelper.extractFileData(
                                result.files.single);
                            setDialogState(() {
                              pickedFile = data.file;
                              pickedBytes = data.bytes;
                              pickedFileName = data.fileName;
                            });
                          } catch (_) {}
                        }
                      },
                      icon: const Icon(Icons.attach_file, size: 16),
                      label: const Text('Photo',
                          style: TextStyle(fontSize: 12)),
                      style: OutlinedButton.styleFrom(
                          visualDensity: VisualDensity.compact),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.deepSlate),
              child: const Text('Report',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );

    if (result == true && mounted) {
      if (titleController.text.isEmpty || descController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Title and description are required')),
        );
        return;
      }
      try {
        await _service.createObservation(
          projectId: widget.projectId,
          title: titleController.text,
          description: descController.text,
          priority: priority,
          location: locationController.text.isNotEmpty
              ? locationController.text
              : null,
          imageFile: pickedFile,
          imageBytes: pickedBytes,
          imageFileName: pickedFileName,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Snag reported'),
                backgroundColor: AppTheme.successGreen),
          );
        }
        await _loadData();
      } catch (e) {
        if (mounted) {
          await ErrorHandler.handleApiError(context, e,
              defaultMessage: 'Failed to report snag');
        }
      }
    }
  }

  Future<void> _resolveObservation(ObservationItem item) async {
    final notesController = TextEditingController();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Resolve Snag'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Mark "${item.title}" as resolved?'),
            const SizedBox(height: 16),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                labelText: 'Resolution Notes',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.successGreen),
            child:
                const Text('Resolve', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        await _service.resolveObservation(
          item.id,
          notesController.text.isNotEmpty ? notesController.text : null,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Snag resolved'),
                backgroundColor: AppTheme.successGreen),
          );
        }
        await _loadData();
      } catch (e) {
        if (mounted) {
          await ErrorHandler.handleApiError(context, e,
              defaultMessage: 'Failed to resolve snag');
        }
      }
    }
  }

  Future<void> _confirmDelete(ObservationItem item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Snag'),
        content: Text('Are you sure you want to delete "${item.title}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style:
                ElevatedButton.styleFrom(backgroundColor: AppTheme.errorRed),
            child:
                const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        await _service.deleteObservation(item.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Snag deleted'),
                backgroundColor: AppTheme.successGreen),
          );
        }
        await _loadData();
      } catch (e) {
        if (mounted) {
          await ErrorHandler.handleApiError(context, e,
              defaultMessage: 'Failed to delete snag');
        }
      }
    }
  }

  Color _getPriorityColor(String? priority) {
    switch (priority?.toUpperCase()) {
      case 'CRITICAL':
        return const Color(0xFFDC2626);
      case 'HIGH':
        return AppTheme.errorRed;
      case 'MEDIUM':
        return AppTheme.constructionOrange;
      case 'LOW':
        return AppTheme.successGreen;
      default:
        return Colors.grey;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'OPEN':
        return AppTheme.constructionOrange;
      case 'IN_PROGRESS':
        return AppTheme.skyBlue;
      case 'RESOLVED':
      case 'CLOSED':
        return AppTheme.successGreen;
      default:
        return Colors.grey;
    }
  }
}
