import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/models/lead.dart';
import '../../data/models/lead_document.dart';
import '../../data/services/lead_service.dart';
import 'package:admin/utils/error_handler.dart';

class LeadDocumentsScreen extends StatefulWidget {
  final Lead lead;

  const LeadDocumentsScreen({super.key, required this.lead});

  @override
  State<LeadDocumentsScreen> createState() => _LeadDocumentsScreenState();
}

class _LeadDocumentsScreenState extends State<LeadDocumentsScreen> {
  final LeadService _leadService = LeadService();
  List<LeadDocument> _documents = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  Future<void> _loadDocuments() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });
      final docs = await _leadService.getLeadDocuments(widget.lead.leadId);
      setState(() {
        _documents = docs;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = ErrorHandler.getErrorMessage(e);
          _isLoading = false;
        });
        await ErrorHandler.handleApiError(context, e, defaultMessage: 'Failed to load documents', showToast: false);
      }
    }
  }

  Future<void> _pickAndUploadFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles();

      if (result != null) {
        final platformFile = result.files.single;
        if (platformFile.path == null) return;

        final file = File(platformFile.path!);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Uploading document...')),
          );
        }

        // Upload without category (null) and with description
        await _leadService.uploadDocument(
            widget.lead.leadId, 
            file, 
            null, // categoryId - can be null
            "Uploaded via Mobile App"
        );
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Upload successful')),
          );
          _loadDocuments();
        }
      }
    } catch (e) {
      if (mounted) {
        await ErrorHandler.handleApiError(context, e, defaultMessage: 'Upload failed');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Documents - ${widget.lead.name}'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _documents.isEmpty
                  ? const Center(child: Text('No documents found'))
                  : ListView.builder(
                      itemCount: _documents.length,
                      itemBuilder: (context, index) {
                        final doc = _documents[index];
                        return ListTile(
                          leading: const Icon(Icons.description),
                          title: Text(doc.filename),
                          subtitle: Text('${(doc.fileSize ?? 0) ~/ 1024} KB • ${DateFormat.yMMMd().format(doc.uploadedAt)}'),
                          // Add trailing delete button if needed, checking Service support later
                        );
                      },
                    ),
      floatingActionButton: FloatingActionButton(
        onPressed: _pickAndUploadFile,
        child: const Icon(Icons.upload_file),
      ),
    );
  }
}

