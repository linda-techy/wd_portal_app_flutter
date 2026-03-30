import 'package:flutter/material.dart';
import 'package:admin/constants.dart';
import 'package:admin/utils/error_handler.dart';
import 'package:admin/models/document_models.dart';
import 'package:admin/models/customer_project.dart';
import 'package:admin/services/document_service.dart';
import 'package:admin/services/crm_service.dart';

class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({super.key});

  @override
  State<DocumentsScreen> createState() => DocumentsScreenState();
}

class DocumentsScreenState extends State<DocumentsScreen> {
  final DocumentService _documentService = DocumentService();
  final CRMService _crmService = CRMService();

  List<CustomerProject> _projects = [];
  CustomerProject? _selectedProject;
  List<ProjectDocument> _documents = [];
  List<DocumentCategory> _categories = [];
  bool _isLoadingProjects = true;
  bool _isLoadingDocuments = false;
  String? _error;
  String _searchQuery = '';
  int? _categoryFilter;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProjects() async {
    setState(() => _isLoadingProjects = true);
    try {
      final projects = await _crmService.getAllCustomerProjects();
      setState(() {
        _projects = projects;
        _isLoadingProjects = false;
        if (_projects.isNotEmpty) {
          _selectedProject = _projects.first;
          _loadDocuments();
        }
      });
    } catch (e) {
      setState(() { _error = e.toString(); _isLoadingProjects = false; });
    }
  }

  Future<void> _loadDocuments() async {
    if (_selectedProject == null) return;
    setState(() { _isLoadingDocuments = true; _error = null; });
    try {
      final results = await Future.wait([
        _documentService.getProjectDocuments(_selectedProject!.id!, categoryId: _categoryFilter),
        _documentService.getCategories(_selectedProject!.id!),
      ]);
      setState(() {
        _documents = results[0] as List<ProjectDocument>;
        _categories = results[1] as List<DocumentCategory>;
        _isLoadingDocuments = false;
      });
    } catch (e) {
      setState(() { _error = e.toString(); _isLoadingDocuments = false; });
    }
  }

  List<ProjectDocument> get _filteredDocuments {
    return _documents.where((doc) {
      final matchesSearch = _searchQuery.isEmpty ||
          doc.filename.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          doc.categoryName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (doc.description?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
      return matchesSearch;
    }).toList();
  }

  IconData _getFileIcon(String fileType) {
    final type = fileType.toLowerCase();
    if (type.contains('pdf')) return Icons.picture_as_pdf;
    if (type.contains('image') || type.contains('png') || type.contains('jpg') || type.contains('jpeg')) return Icons.image;
    if (type.contains('doc') || type.contains('word')) return Icons.description;
    if (type.contains('xls') || type.contains('sheet') || type.contains('csv')) return Icons.table_chart;
    if (type.contains('ppt') || type.contains('presentation')) return Icons.slideshow;
    if (type.contains('zip') || type.contains('rar') || type.contains('tar')) return Icons.archive;
    return Icons.insert_drive_file;
  }

  Color _getFileColor(String fileType) {
    final type = fileType.toLowerCase();
    if (type.contains('pdf')) return Colors.red;
    if (type.contains('image') || type.contains('png') || type.contains('jpg')) return Colors.green;
    if (type.contains('doc') || type.contains('word')) return Colors.blue;
    if (type.contains('xls') || type.contains('sheet')) return Colors.teal;
    return Colors.grey;
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredDocuments;

    return Scaffold(
      body: Container(
        padding: const EdgeInsets.all(defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Documents Management", style: Theme.of(context).textTheme.headlineMedium),
                IconButton(icon: const Icon(Icons.refresh), onPressed: _loadDocuments, tooltip: 'Refresh'),
              ],
            ),
            const SizedBox(height: defaultPadding),

            // Project Selector & Filters
            Container(
              padding: const EdgeInsets.all(defaultPadding),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: containerBorder),
              ),
              child: Row(
                children: [
                  const Icon(Icons.business, size: 20, color: textSecondary),
                  const SizedBox(width: 8),
                  const Text('Project:', style: TextStyle(fontWeight: FontWeight.w500)),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: _isLoadingProjects
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : DropdownButtonFormField<CustomerProject>(
                            value: _selectedProject,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              isDense: true,
                            ),
                            items: _projects.map((p) => DropdownMenuItem(
                              value: p,
                              child: Text(p.projectName.isNotEmpty ? p.projectName : 'Project #${p.id}', overflow: TextOverflow.ellipsis),
                            )).toList(),
                            onChanged: (v) {
                              setState(() { _selectedProject = v; _categoryFilter = null; });
                              _loadDocuments();
                            },
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<int?>(
                      value: _categoryFilter,
                      decoration: InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        isDense: true,
                      ),
                      items: [
                        const DropdownMenuItem<int?>(value: null, child: Text('All Categories')),
                        ..._categories.map((c) => DropdownMenuItem<int?>(value: c.id, child: Text(c.name, overflow: TextOverflow.ellipsis))),
                      ],
                      onChanged: (v) {
                        setState(() => _categoryFilter = v);
                        _loadDocuments();
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search files...',
                        prefixIcon: const Icon(Icons.search, size: 20),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        isDense: true,
                      ),
                      onChanged: (v) => setState(() => _searchQuery = v),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: defaultPadding),

            // Stats
            if (!_isLoadingDocuments && _documents.isNotEmpty)
              Row(
                children: [
                  _buildStatChip('Total Files', filtered.length, primaryColor),
                  const SizedBox(width: 8),
                  _buildStatChip('Categories', _categories.length, infoColor),
                  const SizedBox(width: 8),
                  _buildStatChip('Total Size', _formatFileSize(_documents.fold(0, (s, d) => s + d.fileSize)), warningColor),
                ],
              ),
            if (!_isLoadingDocuments && _documents.isNotEmpty) const SizedBox(height: defaultPadding),

            // Content
            Expanded(
              child: _isLoadingDocuments
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.error_outline, size: 48, color: errorColor),
                              const SizedBox(height: 8),
                              Text(_error!, style: const TextStyle(color: textSecondary, fontSize: 12)),
                              const SizedBox(height: 16),
                              ElevatedButton(onPressed: _loadDocuments, child: const Text('Retry')),
                            ],
                          ),
                        )
                      : _selectedProject == null
                          ? const Center(child: Text('Select a project to view documents', style: TextStyle(color: textSecondary)))
                          : filtered.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.folder_open, size: 48, color: Colors.grey[400]),
                                      const SizedBox(height: 8),
                                      const Text('No documents found', style: TextStyle(color: textSecondary)),
                                    ],
                                  ),
                                )
                              : Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: containerBorder),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: SingleChildScrollView(
                                      child: SizedBox(
                                        width: double.infinity,
                                        child: DataTable(
                                          headingRowColor: WidgetStateProperty.all(boxSecondary),
                                          columnSpacing: 16,
                                          horizontalMargin: 16,
                                          columns: const [
                                            DataColumn(label: Text('File Name', style: TextStyle(fontWeight: FontWeight.bold))),
                                            DataColumn(label: Text('Category', style: TextStyle(fontWeight: FontWeight.bold))),
                                            DataColumn(label: Text('Size', style: TextStyle(fontWeight: FontWeight.bold))),
                                            DataColumn(label: Text('Uploaded By', style: TextStyle(fontWeight: FontWeight.bold))),
                                            DataColumn(label: Text('Upload Date', style: TextStyle(fontWeight: FontWeight.bold))),
                                            DataColumn(label: Text('Version', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
                                            DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
                                          ],
                                          rows: filtered.map((doc) => DataRow(
                                            cells: [
                                              DataCell(Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(_getFileIcon(doc.fileType), size: 20, color: _getFileColor(doc.fileType)),
                                                  const SizedBox(width: 8),
                                                  Flexible(
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        Text(doc.filename, style: const TextStyle(fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis),
                                                        if (doc.description != null && doc.description!.isNotEmpty)
                                                          Text(doc.description!, style: const TextStyle(fontSize: 11, color: textSecondary), overflow: TextOverflow.ellipsis),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              )),
                                              DataCell(
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: boxInfo,
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: Text(doc.categoryName, style: const TextStyle(fontSize: 12)),
                                                ),
                                              ),
                                              DataCell(Text(_formatFileSize(doc.fileSize), style: const TextStyle(fontSize: 12))),
                                              DataCell(Text(doc.uploadedByName, style: const TextStyle(fontSize: 12))),
                                              DataCell(Text(doc.uploadDate, style: const TextStyle(fontSize: 12))),
                                              DataCell(Text('v${doc.version}')),
                                              DataCell(Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  IconButton(
                                                    icon: const Icon(Icons.delete_outline, size: 18),
                                                    onPressed: () => _deleteDocument(doc),
                                                    tooltip: 'Delete',
                                                    color: errorColor,
                                                    splashRadius: 18,
                                                  ),
                                                ],
                                              )),
                                            ],
                                          )).toList(),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip(String label, dynamic value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$value', style: TextStyle(fontWeight: FontWeight.bold, color: color)),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 12, color: color)),
        ],
      ),
    );
  }

  Future<void> _deleteDocument(ProjectDocument doc) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Document'),
        content: Text('Delete "${doc.filename}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: errorColor, foregroundColor: Colors.white),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await _documentService.deleteDocument(_selectedProject!.id!, doc.id);
        _loadDocuments();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Document deleted'), backgroundColor: successColor),
          );
        }
      } catch (e) {
        if (mounted) {
          ErrorHandler.showErrorSnackBar(context, e);
        }
      }
    }
  }
}
