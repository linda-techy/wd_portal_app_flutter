import 'package:flutter/material.dart';
import '../../../../utils/error_handler.dart';
import '../../data/models/material_indent.dart';
import '../../data/services/material_indent_service.dart';
import 'indent_creation_screen.dart';
import 'quotation_management_screen.dart';

class IndentListScreen extends StatefulWidget {
  final int projectId;

  const IndentListScreen({Key? key, required this.projectId}) : super(key: key);

  @override
  _IndentListScreenState createState() => _IndentListScreenState();
}

class _IndentListScreenState extends State<IndentListScreen> {
  final _service = MaterialIndentService();
  bool _isPageLoading = true;
  List<MaterialIndent> _indents = [];

  @override
  void initState() {
    super.initState();
    _loadIndents();
  }

  Future<void> _loadIndents() async {
    setState(() => _isPageLoading = true);
    try {
      final list = await _service.getIndents(widget.projectId);
      if (mounted) {
        setState(() {
          _indents = list;
          _isPageLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isPageLoading = false);
        ErrorHandler.handleApiError(context, e);
      }
    }
  }

  void _navigateToCreate() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => IndentCreationScreen(projectId: widget.projectId)),
    );
    if (result == true) {
      _loadIndents();
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'APPROVED': return Colors.green;
      case 'REJECTED': return Colors.red;
      case 'SUBMITTED': return Colors.blue;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Material Indents')),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToCreate,
        child: const Icon(Icons.add),
      ),
      body: _isPageLoading
          ? const Center(child: CircularProgressIndicator())
          : _indents.isEmpty
              ? const Center(child: Text('No indents found.'))
              : RefreshIndicator(
                  onRefresh: _loadIndents,
                  child: ListView.builder(
                    itemCount: _indents.length,
                    itemBuilder: (context, index) {
                      final indent = _indents[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: _getStatusColor(indent.status).withOpacity(0.2),
                            child: Icon(Icons.assignment, color: _getStatusColor(indent.status)),
                          ),
                          title: Text(indent.indentNumber ?? 'Draft'),
                          subtitle: Text('Items: ${indent.items.length} | Date: ${indent.requestDate}'),
                          trailing: Chip(
                            label: Text(indent.status, style: const TextStyle(fontSize: 10)),
                            backgroundColor: _getStatusColor(indent.status).withOpacity(0.1),
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => QuotationManagementScreen(indent: indent),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}

