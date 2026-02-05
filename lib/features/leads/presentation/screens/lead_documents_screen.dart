import 'dart:io';
import 'dart:typed_data'; // Added for BytesBuilder
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:admin/config/app_config.dart';
import 'package:admin/services/storage_service.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import '../../data/models/lead.dart';
import '../../data/models/lead_document.dart';
import '../../data/services/lead_service.dart';
import 'package:admin/utils/error_handler.dart';
import 'document_viewer_screen.dart';

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

  String _getFileExtension(String filename) {
    return filename.split('.').last.toLowerCase();
  }

  bool _isViewable(String extension) {
    return [
      'pdf',
      'jpg',
      'jpeg',
      'png',
      'webp',
      'doc',
      'docx',
      'xls',
      'xlsx',
      'ppt',
      'pptx',
      'csv',
      'txt'
    ].contains(extension);
  }



  String _getFullUrl(String url) {
    if (url.startsWith('http')) {
      return url;
    }
    return '${AppConfig.fullApiUrl}$url';
  }

  Future<void> _viewDocument(LeadDocument doc) async {
    final extension = _getFileExtension(doc.filename);
    if (doc.downloadUrl == null || doc.downloadUrl!.isEmpty) return;

    final fullUrl = _getFullUrl(doc.downloadUrl!);
    
    // Get headers with token
    final storage = StorageService(); // Make sure to import this
    final token = await storage.read(key: 'access_token');
    final headers = token != null ? {'Authorization': 'Bearer $token'} : <String, String>{};

    if (kIsWeb) {
      if (['pdf'].contains(extension)) {
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DocumentViewerScreen(
              url: fullUrl,
              fileName: doc.filename,
              fileType: 'pdf',
              headers: headers,
            ),
          ),
        );
      } else if (['jpg', 'jpeg', 'png', 'webp'].contains(extension)) {
        if (!mounted) return;
         Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DocumentViewerScreen(
              url: fullUrl,
              fileName: doc.filename,
              fileType: 'image',
              headers: headers,
            ),
          ),
        );
      } else {
        // specific handling for office docs on web with auth is hard without backend support
        // fallback to download
        _downloadDocument(doc);
      }
    } else {
      // Mobile / Desktop: Download and open with native viewer
      try {
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Opening document...')),
          );
        }
        
        final request = await HttpClient().getUrl(Uri.parse(fullUrl));
        headers.forEach((key, value) {
          request.headers.add(key, value);
        });
        final response = await request.close();
        
        if (response.statusCode != 200) {
            throw Exception('Failed to download file: ${response.statusCode}');
        }

        final bytes = await makeConsolidatable(response).fold<BytesBuilder>(
          BytesBuilder(),
          (BytesBuilder builder, List<int> chunk) => builder..add(chunk),
        ).then((builder) => builder.takeBytes());

        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/${doc.filename}');
        await file.writeAsBytes(bytes);
        
        final result = await OpenFilex.open(file.path);
        if (result.type != ResultType.done) {
           if (mounted) {
             ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Could not open file: ${result.message}')),
            );
           }
        }

      } catch (e) {
         if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error viewing document: $e')),
          );
        }
      }
    }
  }

  Stream<List<int>> makeConsolidatable(Stream<List<int>> stream) {
    return stream;
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
      String fullUrl = _getFullUrl(doc.downloadUrl!);

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
                        final extension = _getFileExtension(doc.filename);
                        final isViewable = _isViewable(extension);

                        return ListTile(
                          leading: _buildFileIcon(extension),
                          title: Text(doc.filename),
                          subtitle: Text('${(doc.fileSize ?? 0) ~/ 1024} KB • ${DateFormat.yMMMd().format(doc.uploadedAt)}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isViewable)
                                IconButton(
                                  icon: const Icon(Icons.visibility),
                                  tooltip: 'View',
                                  onPressed: () => _viewDocument(doc),
                                ),
                              IconButton(
                                icon: const Icon(Icons.download),
                                tooltip: 'Download',
                                onPressed: () => _downloadDocument(doc),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
    );
  }

  Widget _buildFileIcon(String extension) {
    IconData icon;
    Color color;

    switch (extension) {
      case 'pdf':
        icon = Icons.picture_as_pdf;
        color = Colors.red;
        break;
      case 'doc':
      case 'docx':
        icon = Icons.description;
        color = Colors.blue;
        break;
      case 'xls':
      case 'xlsx':
      case 'csv':
        icon = Icons.grid_on;
        color = Colors.green;
        break;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'webp':
        icon = Icons.image;
        color = Colors.purple;
        break;
      default:
        icon = Icons.insert_drive_file;
        color = Colors.grey;
    }

    return Icon(icon, color: color);
  }
}

