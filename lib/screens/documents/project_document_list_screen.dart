import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:admin/constants.dart';
import 'package:admin/theme/app_theme.dart';
import 'package:admin/providers/document_provider.dart';
import 'package:admin/models/document_models.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class ProjectDocumentListScreen extends StatefulWidget {
  final int projectId;
  final String projectName;

  const ProjectDocumentListScreen({
    super.key,
    required this.projectId,
    required this.projectName,
  });

  @override
  State<ProjectDocumentListScreen> createState() => _ProjectDocumentListScreenState();
}

class _ProjectDocumentListScreenState extends State<ProjectDocumentListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DocumentProvider>().fetchDocuments(widget.projectId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Documents - ${widget.projectName}"),
      ),
      body: Consumer<DocumentProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) return const Center(child: CircularProgressIndicator());
          if (provider.documents.isEmpty) {
            return const Center(child: Text("No documents found for this project"));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16.0),
            itemCount: provider.documents.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final doc = provider.documents[index];
              return _buildDocumentCard(doc);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Implement upload dialog/screen
        },
        child: const Icon(Icons.upload),
      ),
    );
  }

  Widget _buildDocumentCard(ProjectDocument doc) {
    return Card(
      child: ListTile(
        leading: Icon(
          _getFileIcon(doc.fileType),
          color: WalldotColors.primary,
          size: 32,
        ),
        title: Text(doc.filename),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("${doc.categoryName} • ${DateFormat('yyyy-MM-dd').format(DateTime.parse(doc.uploadDate))}"),
            if (doc.description != null) ...[
              const SizedBox(height: 4),
              Text(
                doc.description!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.download),
          onPressed: () => _downloadFile(doc.downloadUrl),
        ),
      ),
    );
  }

  IconData _getFileIcon(String type) {
    if (type.contains('pdf')) return Icons.picture_as_pdf;
    if (type.contains('image')) return Icons.image;
    if (type.contains('sheet') || type.contains('excel')) return Icons.table_view;
    if (type.contains('word') || type.contains('document')) return Icons.description;
    return Icons.insert_drive_file;
  }

  Future<void> _downloadFile(String url) async {
    // In a real app, you'd prepend the base URL
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Could not launch download URL")),
      );
    }
  }
}
