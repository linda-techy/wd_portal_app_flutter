import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../../services/site_report_service.dart';
import '../../../../models/site_report_models.dart';
import '../../../../theme/app_theme.dart';
import '../../../../utils/error_handler.dart';
import '../../../../providers/portal_auth_provider.dart';

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

  @override
  void initState() {
    super.initState();
    _verifyAuthAndLoadData();
  }

  Future<void> _verifyAuthAndLoadData() async {
    final authProvider = Provider.of<PortalAuthProvider>(context, listen: false);
    if (!authProvider.isAuthenticated) {
      if (mounted) {
         await ErrorHandler.handleAuthError(context);
         if (mounted) {
           Navigator.of(context).pushReplacementNamed('/login');
         }
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
        await ErrorHandler.handleApiError(context, e, defaultMessage: 'Failed to load site reports');
      }
    }
  }

  Future<void> _showCreateDialog() async {
    await showDialog(
      context: context,
      builder: (context) => CreateSiteReportDialog(
        projectId: widget.projectId,
        onSave: _loadData,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Site Reports'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_a_photo),
            onPressed: _showCreateDialog,
          ),
        ],
      ),
      body: _isPageLoading
          ? const Center(child: CircularProgressIndicator())
          : _reports.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.assignment_outlined, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text('No site reports submitted.'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _showCreateDialog,
                        child: const Text('Create Report'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _reports.length,
                  itemBuilder: (context, index) {
                    final report = _reports[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ExpansionTile(
                        leading: CircleAvatar(
                          backgroundColor: AppTheme.primaryBlue.withOpacity(0.1),
                          child: const Icon(Icons.description, color: AppTheme.primaryBlue),
                        ),
                        title: Text(report.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(
                          '${report.reportType.name} • ${DateFormat('MMM dd, yyyy').format(report.reportDate)}'
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Description: ${report.description}'),
                                const SizedBox(height: 8),
                                const SizedBox(height: 8),
                                if (report.submittedByName != null) 
                                   Text('Submitted By: ${report.submittedByName ?? 'Unknown'}'),
                              ],
                            ),
                          )
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}

class CreateSiteReportDialog extends StatefulWidget {
  final int projectId;
  final VoidCallback onSave;

  const CreateSiteReportDialog({
    super.key, 
    required this.projectId, 
    required this.onSave
  });

  @override
  State<CreateSiteReportDialog> createState() => _CreateSiteReportDialogState();
}

class _CreateSiteReportDialogState extends State<CreateSiteReportDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final SiteReportService _service = SiteReportService();
  final ImagePicker _picker = ImagePicker();
  
  ReportType _type = ReportType.dailyProgress;
  final List<XFile> _selectedPhotos = [];
  bool _isSaving = false;

  Future<void> _pickPhotos() async {
    final List<XFile> images = await _picker.pickMultiImage();
    if (images.isNotEmpty) {
      setState(() {
        _selectedPhotos.addAll(images);
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      await _service.createReport(
        projectId: widget.projectId,
        title: _titleController.text,
        description: _descController.text,
        reportType: _type,
        photos: _selectedPhotos,
      );

      widget.onSave();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        await ErrorHandler.handleApiError(context, e, defaultMessage: 'Failed to create site report');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New Site Report'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Report Title'),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<ReportType>(
                value: _type,
                decoration: const InputDecoration(labelText: 'Report Type'),
                items: ReportType.values.map((t) => DropdownMenuItem(value: t, child: Text(t.name))).toList(),
                onChanged: (v) => setState(() => _type = v!),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(labelText: 'Description / Progress'),
                maxLines: 4,
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _pickPhotos,
                icon: const Icon(Icons.photo_camera),
                label: Text('Attach Photos (${_selectedPhotos.length})'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: _isSaving ? null : _submit,
          child: _isSaving ? const CircularProgressIndicator() : const Text('Submit'),
        ),
      ],
    );
  }
}

