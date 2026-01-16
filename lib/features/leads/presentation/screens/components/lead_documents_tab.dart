import 'package:flutter/material.dart';
import '../../../../../../constants.dart';
import '../../../data/models/lead_document.dart';
import '../../../data/services/lead_service.dart';

class LeadDocumentsTab extends StatefulWidget {
  final String leadId;
  const LeadDocumentsTab({super.key, required this.leadId});

  @override
  State<LeadDocumentsTab> createState() => _LeadDocumentsTabState();
}

class _LeadDocumentsTabState extends State<LeadDocumentsTab> {
  bool _isLoading = true;
  List<LeadDocument> _documents = [];
  String? _error;
  final LeadService _leadService = LeadService();

  @override
  void initState() {
    super.initState();
    _fetchDocuments();
  }

  Future<void> _fetchDocuments() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final documents = await _leadService.getLeadDocuments(widget.leadId);
      if (mounted) {
        setState(() {
          _isLoading = false;
          _documents = documents;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Failed to load documents: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(defaultPadding),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Documents",
                        style: Theme.of(context).textTheme.titleLarge),
                    ElevatedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content:
                                    Text("Upload Document Implemented Next")));
                      },
                      icon: const Icon(Icons.upload_file, size: 16),
                      label: const Text("Upload File"),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor),
                    )
                  ],
                ),
              ),
              Expanded(
                child: _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline,
                                size: 48, color: Colors.red[300]),
                            const SizedBox(height: 16),
                            Text(_error!,
                                style: TextStyle(color: Colors.red[600])),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _fetchDocuments,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : _documents.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.folder_open,
                                    size: 48, color: Colors.grey[400]),
                                const SizedBox(height: 16),
                                Text("No documents uploaded",
                                    style: TextStyle(color: Colors.grey[600])),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: _documents.length,
                            itemBuilder: (context, index) {
                              final doc = _documents[index];
                              return ListTile(
                                leading: Icon(Icons.insert_drive_file,
                                    color: primaryColor),
                                title: Text(doc.filename),
                                subtitle: Text(
                                    "${doc.category ?? 'Uncategorized'} • ${_ResultUtils.formatBytes(doc.fileSize ?? 0)}"),
                                trailing: IconButton(
                                  icon: const Icon(Icons.download),
                                  onPressed: () {},
                                ),
                              );
                            },
                          ),
              ),
            ],
          );
  }
}

class _ResultUtils {
  static String formatBytes(int bytes, [int decimals = 2]) {
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB", "TB"];
    double size = bytes.toDouble();
    int i = 0;
    while (size >= 1024 && i < suffixes.length - 1) {
      size /= 1024;
      i++;
    }
    return "${size.toStringAsFixed(decimals)} ${suffixes[i]}";
  }
}
