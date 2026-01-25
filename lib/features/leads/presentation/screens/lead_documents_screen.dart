import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:admin/config/app_config.dart';
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


  Future<void> _downloadDocument(LeadDocument doc) async {
    try {
      if (doc.downloadUrl == null || doc.downloadUrl!.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Download URL not available'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // Construct full URL if relative
      String fullUrl = doc.downloadUrl!;
      if (!fullUrl.startsWith('http')) {
        // Get base URL from API config
        fullUrl = '${AppConfig.fullApiUrl}$fullUrl';
      }

      // Use url_launcher to open/download document
      final uri = Uri.parse(fullUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw Exception('Could not launch URL: $fullUrl');
      }
    } catch (e) {
      if (mounted) {
        await ErrorHandler.handleApiError(
          context,
          e,
          defaultMessage: 'Failed to download document',
        );
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
                          trailing: IconButton(
                            icon: const Icon(Icons.visibility),
                            tooltip: 'View Document',
                            onPressed: () => _downloadDocument(doc),
                          ),
                        );
                      },
                    ),
    );
  }
}

