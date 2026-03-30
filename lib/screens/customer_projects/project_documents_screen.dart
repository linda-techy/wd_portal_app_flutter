import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:admin/models/customer_project.dart';
import 'package:admin/models/project_document.dart';
import 'package:admin/models/document_category.dart';
import 'package:admin/services/project_module_service.dart';
import 'package:admin/services/document_download_service.dart';
import 'package:admin/services/storage_service.dart';
import 'package:admin/features/shared/universal_file_viewer_screen.dart';
import 'package:admin/theme/app_theme.dart';
import 'package:admin/utils/error_handler.dart';
import 'package:admin/utils/file_upload_helper.dart';
import 'package:admin/utils/file_download_helper.dart';


class ProjectDocumentsScreen extends StatefulWidget {
  final CustomerProject project;

  const ProjectDocumentsScreen({
    super.key,
    required this.project,
  });

  @override
  State<ProjectDocumentsScreen> createState() => _ProjectDocumentsScreenState();
}

class _ProjectDocumentsScreenState extends State<ProjectDocumentsScreen> {
  final ProjectModuleService _moduleService = ProjectModuleService();
  List<ProjectDocument> _documents = [];
  List<DocumentCategory> _categories = [];
  DocumentCategory? _selectedCategory;
  bool _isPageLoading = true;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isPageLoading = true;
    });

    try {
      final categories = await _moduleService.getDocumentCategories(widget.project.id!);
      final documents = await _moduleService.getProjectDocuments(widget.project.id!);

      setState(() {
        _categories = categories;
        _documents = documents;
        _isPageLoading = false;
      });
    } catch (e) {
      setState(() {
        _isPageLoading = false;
      });
      if (mounted) {
        await ErrorHandler.handleApiError(context, e, defaultMessage: 'Error loading documents');
      }
    }
  }

  Future<void> _uploadDocument() async {
    if (_categories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No document categories available')),
      );
      return;
    }

    // Show category selection dialog
    final category = await showDialog<DocumentCategory>(
      context: context,
      builder: (context) => _CategorySelectionDialog(categories: _categories),
    );

    if (category == null) return;

    // Pick file
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      allowMultiple: false,
    );

    if (result == null) return;

    // Extract file data using cross-platform helper
    final fileData = FileUploadHelper.extractFromResult(result);
    final description = await _showDescriptionDialog();

    setState(() {
      _isUploading = true;
    });

    try {
      await _moduleService.uploadDocument(
        widget.project.id!,
        file: fileData.file,
        bytes: fileData.bytes,
        fileName: fileData.fileName,
        categoryId: category.id,
        description: description,
      );

      // Reload documents
      await _loadData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Document uploaded successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        await ErrorHandler.handleApiError(context, e, defaultMessage: 'Error uploading document');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  Future<String?> _showDescriptionDialog() async {
    String? description;
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Document Description (Optional)'),
        content: TextField(
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Enter description...',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) => description = value,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Skip'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    return description;
  }

  List<ProjectDocument> get _filteredDocuments {
    if (_selectedCategory == null) {
      return _documents;
    }
    return _documents
        .where((doc) => doc.categoryId != null && doc.categoryId == _selectedCategory!.id)
        .toList();
  }

  String _formatFileSize(int? fileSize) {
    if (fileSize == null) return '';
    if (fileSize < 1024) {
      return '$fileSize B';
    } else if (fileSize < 1024 * 1024) {
      return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }

  IconData _getFileIcon(String? fileType) {
    if (fileType == null) return Icons.insert_drive_file;
    final lowerType = fileType.toLowerCase();
    if (lowerType.contains('pdf')) {
      return Icons.picture_as_pdf;
    } else if (lowerType.contains('doc')) {
      return Icons.description;
    } else if (lowerType.contains('xls')) {
      return Icons.table_chart;
    } else if (lowerType.contains('zip') || lowerType.contains('rar')) {
      return Icons.folder_zip;
    } else if (lowerType.contains('image')) {
      return Icons.image;
    } else {
      return Icons.insert_drive_file;
    }
  }

  Color _getFileIconColor(String? fileType) {
    if (fileType == null) return AppTheme.textSecondary;
    final lowerType = fileType.toLowerCase();
    if (lowerType.contains('pdf')) {
      return Colors.red;
    } else if (lowerType.contains('doc')) {
      return Colors.blue;
    } else if (lowerType.contains('xls')) {
      return Colors.green;
    } else if (lowerType.contains('zip') || lowerType.contains('rar')) {
      return Colors.orange;
    } else if (lowerType.contains('image')) {
      return Colors.purple;
    } else {
      return AppTheme.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text('Documents - ${widget.project.name}'),
        elevation: 0,
        backgroundColor: AppTheme.surface,
      ),
      body: _isPageLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Filter and Upload Section
                Container(
                  padding: const EdgeInsets.all(AppTheme.spacingMD),
                  decoration: const BoxDecoration(
                    color: AppTheme.surface,
                    border: Border(
                      bottom: BorderSide(color: AppTheme.borderLight),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Category Chips (Horizontal Scroll)
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildCategoryChip('All', null),
                            const SizedBox(width: AppTheme.spacingSM),
                            ..._categories.map((category) => Padding(
                                  padding: const EdgeInsets.only(
                                      right: AppTheme.spacingSM),
                                  child: _buildCategoryChip(
                                      category.name, category),
                                )),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingMD),
                      // Upload Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isUploading ? null : _uploadDocument,
                          icon: _isUploading
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.upload),
                          label: Text(_isUploading
                              ? 'Uploading...'
                              : 'Upload Document'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              vertical: AppTheme.spacingMD,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Documents List
                Expanded(
                  child: _filteredDocuments.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.description_outlined,
                                size: 64,
                                color: AppTheme.textSecondary,
                              ),
                              const SizedBox(height: AppTheme.spacingMD),
                              const Text(
                                'No documents found',
                                style: TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: AppTheme.spacingSM),
                              ElevatedButton.icon(
                                onPressed: _uploadDocument,
                                icon: const Icon(Icons.upload),
                                label: const Text('Upload First Document'),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadData,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(AppTheme.spacingMD),
                            itemCount: _filteredDocuments.length,
                            itemBuilder: (context, index) {
                              final document = _filteredDocuments[index];
                              return _buildDocumentCard(document);
                            },
                          ),
                        ),
                ),
              ],
            ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _buildDocumentCard(ProjectDocument doc) {
    final icon = _getFileIcon(doc.fileType);
    final iconColor = _getFileIconColor(doc.fileType);
    final sizeStr = _formatFileSize(doc.fileSize);
    final dateStr = 'Uploaded on ${_formatDate(doc.uploadDate)}';

    return GestureDetector(
      onTap: () {
        // Open document - you can use url_launcher or a file viewer
        _openDocument(doc);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: AppTheme.spacingMD),
        padding: const EdgeInsets.all(AppTheme.spacingMD),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: AppTheme.surface,
          border: Border.all(color: AppTheme.borderLight),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // File Icon
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingMD),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 32,
              ),
            ),
            const SizedBox(width: AppTheme.spacingMD),
            // File Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    doc.filename,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${doc.categoryName} • ${doc.fileType?.toUpperCase() ?? 'FILE'}${sizeStr.isNotEmpty ? ' • $sizeStr' : ''}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$dateStr • ${doc.uploadedByName}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary,
                          fontSize: 11,
                        ),
                  ),
                  if (doc.description != null && doc.description!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      doc.description!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.textSecondary,
                            fontStyle: FontStyle.italic,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            // Actions Menu
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) async {
                switch (value) {
                  case 'download':
                    _downloadDocument(doc);
                    break;
                  case 'view':
                    _openDocument(doc);
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'view',
                  child: Row(
                    children: [
                      Icon(Icons.visibility, size: 20),
                      SizedBox(width: 8),
                      Text('View'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'download',
                  child: Row(
                    children: [
                      Icon(Icons.download, size: 20),
                      SizedBox(width: 8),
                      Text('Download'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openDocument(ProjectDocument doc) async {
    if (doc.downloadUrl.isEmpty) return;
    
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UniversalFileViewerScreen(
          fileUrl: doc.downloadUrl,
          filename: doc.filename,
        ),
      ),
    );
  }

  Future<void> _downloadDocument(ProjectDocument doc) async {
    try {
      if (doc.downloadUrl.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Download URL not available'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      if (kIsWeb) {
        // Web: Fetch bytes with Dio auth, then trigger browser download
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Preparing download...')),
          );
        }

        final bytes = await DocumentDownloadService.fetchBytes(doc.downloadUrl);
        final mimeType = DocumentDownloadService.guessMimeType(doc.filename);

        await FileDownloadHelper.downloadAndShareFile(
          bytes: bytes,
          fileName: doc.filename,
          mimeType: mimeType,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
        }
      } else {
        // Mobile/Desktop: Download with authentication via HttpClient
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Downloading...')),
          );
        }

        final fullUrl = DocumentDownloadService.resolveUrl(doc.downloadUrl);

        final storage = StorageService();
        final token = await storage.read(key: 'access_token');

        final request = await HttpClient().getUrl(Uri.parse('$fullUrl?download=true'));
        if (token != null) {
          request.headers.add('Authorization', 'Bearer $token');
        }
        final response = await request.close();

        if (response.statusCode != 200) {
          throw Exception('Failed to download file: ${response.statusCode}');
        }

        final bytes = await _consolidateHttpClientResponseBytes(response);

        Directory? directory;
        if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
          directory = await getDownloadsDirectory();
        }
        directory ??= await getApplicationDocumentsDirectory();

        final file = File('${directory.path}/${doc.filename}');
        await file.writeAsBytes(bytes);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Downloaded to: ${file.path}'),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showErrorSnackBar(context, e);
      }
    }
  }

  Future<Uint8List> _consolidateHttpClientResponseBytes(
      HttpClientResponse response) {
    final completer = Completer<Uint8List>();
    final chunks = <List<int>>[];
    response.listen(
      (chunk) => chunks.add(chunk),
      onDone: () {
        final bytes = Uint8List.fromList(chunks.expand((x) => x).toList());
        completer.complete(bytes);
      },
      onError: completer.completeError,
      cancelOnError: true,
    );
    return completer.future;
  }

  Widget _buildCategoryChip(String label, DocumentCategory? category) {
    final isSelected = _selectedCategory == null && category == null ||
        (_selectedCategory != null &&
            category != null &&
            _selectedCategory!.id == category.id);

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategory = category;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingMD,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryBlue
              : AppTheme.surfaceElevated,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppTheme.primaryBlue
                : AppTheme.borderLight,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppTheme.textPrimary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _CategorySelectionDialog extends StatelessWidget {
  final List<DocumentCategory> categories;

  const _CategorySelectionDialog({required this.categories});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select Category'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final category = categories[index];
            return ListTile(
              title: Text(category.name),
              subtitle: (category.description?.isNotEmpty ?? false)
                  ? Text(category.description!)
                  : null,
              onTap: () => Navigator.pop(context, category),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}


