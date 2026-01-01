import 'package:flutter/material.dart';
import '../../../../../../constants.dart';
import '../../data/models/lead_document.dart';

class LeadDocumentsTab extends StatefulWidget {
  final String leadId;
  const LeadDocumentsTab({Key? key, required this.leadId}) : super(key: key);

  @override
  _LeadDocumentsTabState createState() => _LeadDocumentsTabState();
}

class _LeadDocumentsTabState extends State<LeadDocumentsTab> {
  bool _isLoading = true;
  List<LeadDocument> _documents = [];

  @override
  void initState() {
    super.initState();
    _fetchDocuments();
  }

  Future<void> _fetchDocuments() async {
    // TODO: Implement Service Call: leadService.getDocuments(widget.leadId)
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      setState(() {
        _isLoading = false;
        _documents = [];
      });
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
                    Text("Documents", style: Theme.of(context).textTheme.titleLarge),
                    ElevatedButton.icon(
                      onPressed: () {
                         ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Upload Document Implemented Next")));
                      },
                      icon: const Icon(Icons.upload_file, size: 16),
                      label: const Text("Upload File"),
                      style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
                    )
                  ],
                ),
              ),
              Expanded(
                child: _documents.isEmpty
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
                            leading: Icon(Icons.insert_drive_file, color: primaryColor),
                            title: Text(doc.filename),
                            subtitle: Text("${doc.category ?? 'Uncategorized'} • ${_ResultUtils.formatBytes(doc.fileSize ?? 0)}"),
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
    const suffixes = ["B", "KB", "MB", "GB", "TB", "PB", "EB", "ZB", "YB"];
    var i = (bytes.toString().length - 1) ~/ 3; // Approximate log1000
    // Simplified logic for quick implementation
    return "$bytes B"; // TODO: Implement proper formatting
  }
}
