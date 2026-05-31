import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:admin/utils/error_handler.dart';
import 'package:provider/provider.dart';

import 'package:admin/theme/app_theme.dart';
import 'package:admin/providers/document_provider.dart';
import 'package:admin/models/project_document.dart';
import 'package:admin/features/shared/universal_file_viewer_screen.dart';
import 'package:admin/services/document_download_service.dart';
import 'package:admin/utils/file_download_helper.dart';
import 'package:intl/intl.dart';

import 'package:file_picker/file_picker.dart';
import '../../utils/file_upload_helper.dart';

class ProjectDocumentListScreen extends StatefulWidget {
  final int projectId;
  final String projectName;
  final int? initialCategoryId;

  const ProjectDocumentListScreen({
    super.key,
    required this.projectId,
    required this.projectName,
    this.initialCategoryId,
  });

  @override
  State<ProjectDocumentListScreen> createState() => _ProjectDocumentListScreenState();
}

class _ProjectDocumentListScreenState extends State<ProjectDocumentListScreen> {
  int? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    _selectedCategoryId = widget.initialCategoryId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchData();
    });
  }

  Future<void> _fetchData() async {
    final provider = context.read<DocumentProvider>();
    await provider.fetchCategories(widget.projectId);
    await provider.fetchDocuments(widget.projectId, categoryId: _selectedCategoryId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Documents - ${widget.projectName}"),
      ),
      body: Column(
        children: [
          _buildCategoryFilter(),
          Expanded(
            child: Consumer<DocumentProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading) return const Center(child: CircularProgressIndicator(color: AppTheme.coralRed));
                
                if (provider.documents.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(AppTheme.spacingMD),
                  itemCount: provider.documents.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final doc = provider.documents[index];
                    return _buildDocumentCard(doc);
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showUploadDialog(context),
        backgroundColor: AppTheme.coralRed,
        child: const Icon(Icons.upload, color: Colors.white),
      ),
    );
  }

  void _showUploadDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => UploadDocumentDialog(
        projectId: widget.projectId,
        onUploadComplete: () {
          _fetchData();
        },
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return Consumer<DocumentProvider>(
      builder: (context, provider, child) {
        if (provider.categories.isEmpty) return const SizedBox.shrink();
        
        return Container(
          height: 60,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
          ),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMD),
            itemCount: provider.categories.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return _buildFilterChip(null, "All");
              }
              final cat = provider.categories[index - 1];
              return _buildFilterChip(cat.id, cat.name);
            },
          ),
        );
      },
    );
  }

  Widget _buildFilterChip(int? id, String label) {
    final isSelected = _selectedCategoryId == id;
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() => _selectedCategoryId = id);
          context.read<DocumentProvider>().fetchDocuments(widget.projectId, categoryId: id);
        },
        selectedColor: AppTheme.coralRed.withOpacity(0.2),
        checkmarkColor: AppTheme.coralRed,
        labelStyle: TextStyle(
          color: isSelected ? AppTheme.coralRed : AppTheme.textSecondary,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 12,
        ),
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: isSelected ? AppTheme.coralRed : AppTheme.borderLight),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_open, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            "No documents found",
            style: TextStyle(fontSize: 18, color: Colors.grey.shade600, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            "Upload drawings, permits or reports for this project",
            style: TextStyle(color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentCard(ProjectDocument doc) {
    final fileType = doc.fileType ?? '';
    final bool isImage = fileType.toLowerCase().contains('image') ||
                         doc.filename.toLowerCase().endsWith('.jpg') ||
                         doc.filename.toLowerCase().endsWith('.jpeg') ||
                         doc.filename.toLowerCase().endsWith('.png');

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppTheme.borderLight),
      ),
      child: InkWell(
        onTap: isImage ? () => _showPreview(doc) : () => _downloadFile(doc.downloadUrl),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _getFileColor(fileType).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getFileIcon(fileType),
                  color: _getFileColor(fileType),
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      doc.filename,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "${doc.categoryName} • ${DateFormat('dd MMM yyyy').format(doc.uploadDate)}",
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "By: ${doc.uploadedByName}",
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isImage)
                        IconButton(
                          icon: const Icon(Icons.visibility_outlined, color: Colors.blue),
                          onPressed: () => _showPreview(doc),
                          tooltip: 'View',
                        ),
                      IconButton(
                        icon: const Icon(Icons.download_rounded, color: AppTheme.coralRed),
                        onPressed: () => _downloadFile(doc.downloadUrl),
                        tooltip: 'Download',
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.grey),
                        onPressed: () => _confirmDelete(doc),
                        tooltip: 'Delete',
                      ),
                    ],
                  ),
                  Text(
                    _formatFileSize(doc.fileSize ?? 0),
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade400),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showPreview(ProjectDocument doc) async {
    if (!mounted) return;
    unawaited(Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UniversalFileViewerScreen(
          fileUrl: doc.downloadUrl,
          filename: doc.filename,
        ),
      ),
    ));
  }

  Future<void> _confirmDelete(ProjectDocument doc) async {
    final provider = context.read<DocumentProvider>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Document"),
        content: Text("Are you sure you want to delete '${doc.filename}'?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await provider.deleteDocument(widget.projectId, doc.id!);
        if (mounted && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Document deleted successfully")),
          );
        }
      } catch (e) {
        if (mounted && context.mounted) {
          ErrorHandler.showErrorSnackBar(context, e);
        }
      }
    }
  }

  IconData _getFileIcon(String type) {
    if (type.contains('pdf')) return Icons.picture_as_pdf;
    if (type.contains('image')) return Icons.image;
    if (type.contains('sheet') || type.contains('excel')) return Icons.table_view;
    if (type.contains('word') || type.contains('document')) return Icons.description;
    return Icons.insert_drive_file;
  }

  Color _getFileColor(String type) {
    if (type.contains('pdf')) return Colors.red;
    if (type.contains('image')) return Colors.blue;
    if (type.contains('sheet') || type.contains('excel')) return Colors.green;
    if (type.contains('word') || type.contains('document')) return Colors.blue.shade800;
    return Colors.grey;
  }

  String _formatFileSize(int bytes) {
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB"];
    var i = (log(bytes) / log(1024)).floor();
    return '${(bytes / pow(1024, i)).toStringAsFixed(1)} ${suffixes[i]}';
  }

  Future<void> _downloadFile(String downloadUrl) async {
    final filename = downloadUrl.split('/').last;

    if (kIsWeb) {
      // Web: Fetch bytes with auth, then trigger browser download
      try {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Preparing download...')),
        );

        final bytes = await DocumentDownloadService.fetchBytes(downloadUrl);
        final mimeType = DocumentDownloadService.guessMimeType(filename);

        await FileDownloadHelper.downloadAndShareFile(
          bytes: bytes,
          fileName: filename,
          mimeType: mimeType,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
        }
      } catch (e) {
        if (mounted) {
          ErrorHandler.showErrorSnackBar(context, e);
        }
      }
    } else {
      // Mobile/Desktop: Open viewer which handles auth and has download capability
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => UniversalFileViewerScreen(
            fileUrl: downloadUrl,
            filename: filename,
          ),
        ),
      );
    }
  }
}

class UploadDocumentDialog extends StatefulWidget {
  final int projectId;
  final VoidCallback onUploadComplete;

  const UploadDocumentDialog({
    super.key,
    required this.projectId,
    required this.onUploadComplete,
  });

  @override
  State<UploadDocumentDialog> createState() => _UploadDocumentDialogState();
}

class _UploadDocumentDialogState extends State<UploadDocumentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  FileUploadData? _selectedFileData;
  int? _selectedCategoryId;
  bool _isUploading = false;

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'xls', 'xlsx', 'jpg', 'png', 'zip'],
    );

    if (result != null) {
      setState(() {
        _selectedFileData = FileUploadHelper.extractFromResult(result);
      });
    }
  }

  Future<void> _handleUpload() async {
    if (!_formKey.currentState!.validate() || _selectedFileData == null) {
      if (_selectedFileData == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please select a file")),
        );
      }
      return;
    }

    setState(() => _isUploading = true);

    try {
      await context.read<DocumentProvider>().uploadDocument(
            projectId: widget.projectId,
            file: _selectedFileData!.file,
            bytes: _selectedFileData!.bytes,
            fileName: _selectedFileData!.fileName,
            categoryId: _selectedCategoryId!,
            description: _descriptionController.text.trim(),
          );
      
      if (mounted) {
        Navigator.pop(context);
        widget.onUploadComplete();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Document uploaded successfully")),
        );
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showErrorSnackBar(context, e);
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = context.watch<DocumentProvider>().categories;

    return AlertDialog(
      title: const Text("Upload Document"),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              InkWell(
                onTap: _pickFile,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppTheme.borderLight),
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.grey.shade50,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _selectedFileData != null ? Icons.check_circle : Icons.file_present,
                        color: _selectedFileData != null ? Colors.green : AppTheme.coralRed,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _selectedFileData != null
                              ? _selectedFileData!.fileName
                              : "Select File (PDF, DOC, Images...)",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                value: _selectedCategoryId,
                decoration: InputDecoration(
                  labelText: "Category",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                items: categories.map((cat) {
                  return DropdownMenuItem(
                    value: cat.id,
                    child: Text(cat.name),
                  );
                }).toList(),
                validator: (val) => val == null ? "Required" : null,
                onChanged: (val) => setState(() => _selectedCategoryId = val),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: "Description (Optional)",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isUploading ? null : () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: _isUploading ? null : _handleUpload,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.coralRed,
            foregroundColor: Colors.white,
          ),
          child: _isUploading
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text("Upload"),
        ),
      ],
    );
  }
}

