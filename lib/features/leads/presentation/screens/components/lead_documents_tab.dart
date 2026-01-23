import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:intl/intl.dart';
import '../../../../../../constants.dart';
import '../../../data/models/lead_document.dart';
import '../../../data/services/lead_service.dart';
import 'package:admin/utils/error_handler.dart';
import 'package:admin/config/app_config.dart';
import 'package:url_launcher/url_launcher.dart';

// Import DocumentCategory from lead_service
export '../../../data/services/lead_service.dart' show DocumentCategory;

class LeadDocumentsTab extends StatefulWidget {
  final String leadId;
  const LeadDocumentsTab({super.key, required this.leadId});

  @override
  State<LeadDocumentsTab> createState() => _LeadDocumentsTabState();
}

class _LeadDocumentsTabState extends State<LeadDocumentsTab> {
  bool _isLoading = true;
  bool _isUploading = false;
  List<LeadDocument> _documents = [];
  List<DocumentCategory> _categories = [];
  String? _error;
  final LeadService _leadService = LeadService();

  @override
  void initState() {
    super.initState();
    _fetchDocuments();
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    try {
      final categories = await _leadService.getDocumentCategories();
      if (mounted) {
        setState(() {
          _categories = categories;
        });
      }
    } catch (e) {
      // Categories are optional, don't show error if they fail to load
      print('Failed to load document categories: $e');
    }
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

  Future<void> _pickAndUploadFile() async {
    try {
      FilePickerResult? pickerResult = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );

      if (pickerResult == null || pickerResult.files.isEmpty) {
        return;
      }

      final platformFile = pickerResult.files.single;
      
      // Handle all platforms: Web, Android, iOS, Windows, macOS, Linux
      // Priority: bytes (web) > path (mobile/desktop)
      Uint8List? fileBytes;
      String? fileName;
      File? file;

      // Get file name (available on all platforms)
      fileName = platformFile.name;

      // Web platform: bytes are available
      if (kIsWeb) {
        if (platformFile.bytes == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Failed to read file. Please try again.'),
                backgroundColor: Colors.orange,
              ),
            );
          }
          return;
        }
        fileBytes = platformFile.bytes;
      } 
      // Desktop and Mobile platforms: path is available
      // This includes: Android, iOS, Windows, macOS, Linux
      else {
        if (platformFile.path == null) {
          // Fallback: try bytes if available (some desktop platforms support both)
          if (platformFile.bytes != null) {
            fileBytes = platformFile.bytes;
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Failed to get file. Please try again.'),
                  backgroundColor: Colors.orange,
                ),
              );
            }
            return;
          }
        } else {
          file = File(platformFile.path!);
        }
      }

      // Show upload dialog with category and description
      final dialogResult = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (context) => _UploadDocumentDialog(categories: _categories),
      );

      if (dialogResult != null && mounted) {
        setState(() {
          _isUploading = true;
        });

        try {
          final categoryId = dialogResult['categoryId'] as int?;
          final description = dialogResult['description'] as String?;

          await _leadService.uploadDocument(
            widget.leadId,
            file, // null on web, File on mobile/desktop (Android/iOS/Windows/macOS/Linux)
            categoryId,
            description,
            bytes: fileBytes, // Uint8List on web, null on mobile/desktop (unless fallback)
            fileName: fileName, // Required on all platforms
          );

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Document uploaded successfully'),
                backgroundColor: Colors.green,
              ),
            );
            _fetchDocuments();
          }
        } catch (e) {
          if (mounted) {
            await ErrorHandler.handleApiError(
              context,
              e,
              defaultMessage: 'Failed to upload document',
            );
          }
        } finally {
          if (mounted) {
            setState(() {
              _isUploading = false;
            });
          }
        }
      }
    } catch (e) {
      if (mounted) {
        await ErrorHandler.handleApiError(
          context,
          e,
          defaultMessage: 'Failed to pick file',
        );
      }
    }
  }

  Future<void> _downloadDocument(LeadDocument doc) async {
    try {
      if (doc.downloadUrl == null || doc.downloadUrl!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Download URL not available'),
            backgroundColor: Colors.orange,
          ),
        );
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

  Future<void> _deleteDocument(LeadDocument doc) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Document'),
        content: Text('Are you sure you want to delete "${doc.filename}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await _leadService.deleteDocument(doc.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Document deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
          _fetchDocuments();
        }
      } catch (e) {
        if (mounted) {
          await ErrorHandler.handleApiError(
            context,
            e,
            defaultMessage: 'Failed to delete document',
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(defaultPadding),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Documents",
                  style: Theme.of(context).textTheme.titleLarge),
              ElevatedButton.icon(
                onPressed: _isUploading ? null : _pickAndUploadFile,
                icon: _isUploading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.upload_file, size: 16),
                label: Text(_isUploading ? 'Uploading...' : 'Upload File'),
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
                        return Card(
                          margin: const EdgeInsets.symmetric(
                              horizontal: defaultPadding, vertical: 4),
                          child: ListTile(
                            leading: Icon(Icons.insert_drive_file,
                                color: primaryColor),
                            title: Text(doc.filename),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(
                                  "${doc.categoryName ?? 'Uncategorized'} • ${_ResultUtils.formatBytes(doc.fileSize ?? 0)}",
                                  style: TextStyle(fontSize: 12),
                                ),
                                Text(
                                  "Uploaded ${DateFormat.yMMMd().format(doc.uploadedAt)}",
                                  style: TextStyle(
                                      fontSize: 11, color: Colors.grey[600]),
                                ),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.download),
                                  tooltip: 'Download',
                                  onPressed: () => _downloadDocument(doc),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  tooltip: 'Delete',
                                  onPressed: () => _deleteDocument(doc),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}

class _UploadDocumentDialog extends StatefulWidget {
  final List<DocumentCategory> categories;

  const _UploadDocumentDialog({required this.categories});

  @override
  State<_UploadDocumentDialog> createState() => _UploadDocumentDialogState();
}

class _UploadDocumentDialogState extends State<_UploadDocumentDialog> {
  int? _selectedCategoryId;
  final _descriptionController = TextEditingController();

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Upload Document'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.categories.isNotEmpty) ...[
              const Text('Category:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DropdownButtonFormField<int>(
                value: _selectedCategoryId,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Select category (optional)',
                ),
                items: [
                  const DropdownMenuItem<int>(
                    value: null,
                    child: Text('No category'),
                  ),
                  ...widget.categories.map((category) {
                    return DropdownMenuItem<int>(
                      value: category.id,
                      child: Text(category.name),
                    );
                  }),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedCategoryId = value;
                  });
                },
              ),
              const SizedBox(height: 16),
            ],
            const Text('Description:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Enter description (optional)',
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop({
              'categoryId': _selectedCategoryId,
              'description': _descriptionController.text.trim().isEmpty
                  ? null
                  : _descriptionController.text.trim(),
            });
          },
          child: const Text('Upload'),
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
