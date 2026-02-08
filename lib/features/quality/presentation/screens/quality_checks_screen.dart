import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../../services/quality_check_service.dart';

import '../../../../utils/error_handler.dart';
import '../../../../providers/portal_auth_provider.dart';

class QualityChecksScreen extends StatefulWidget {
  final int projectId;

  const QualityChecksScreen({super.key, required this.projectId});

  @override
  State<QualityChecksScreen> createState() => _QualityChecksScreenState();
}

class _QualityChecksScreenState extends State<QualityChecksScreen> {
  final QualityCheckService _service = QualityCheckService();
  List<QualityCheck> _checks = [];
  bool _isPageLoading = true;

  @override
  void initState() {
    super.initState();
    _verifyAuthAndLoadData();
  }

  Future<void> _verifyAuthAndLoadData() async {
    final authProvider = Provider.of<PortalAuthProvider>(context, listen: false);
    if (!authProvider.isAuthenticated) {
      if (mounted) {
         await ErrorHandler.handleAuthError(context);
         if (mounted) {
           Navigator.of(context).pushReplacementNamed('/login');
         }
      }
      return;
    }
    await _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isPageLoading = true);
    try {
      final checks = await _service.getProjectChecks(widget.projectId);
      setState(() {
        _checks = checks;
        _isPageLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isPageLoading = false);
        await ErrorHandler.handleApiError(context, e, defaultMessage: 'Failed to load quality checks');
      }
    }
  }

  Future<void> _showCreateDialog() async {
    await showDialog(
      context: context,
      builder: (context) => CreateQualityCheckDialog(
        projectId: widget.projectId,
        onSave: _loadData,
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PASSED': return Colors.green;
      case 'FAILED': return Colors.red;
      case 'PENDING': return Colors.orange;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quality Checks'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showCreateDialog,
          ),
        ],
      ),
      body: _isPageLoading
          ? const Center(child: CircularProgressIndicator())
          : _checks.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.fact_check_outlined, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text('No quality checks recorded.'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _showCreateDialog,
                        child: const Text('New Inspection'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _checks.length,
                  itemBuilder: (context, index) {
                    final check = _checks[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ExpansionTile(
                        leading: CircleAvatar(
                          backgroundColor: _getStatusColor(check.result ?? 'PENDING').withOpacity(0.1),
                          child: Icon(
                            check.result == 'PASSED' ? Icons.check_circle : 
                            check.result == 'FAILED' ? Icons.cancel : Icons.pending,
                            color: _getStatusColor(check.result ?? 'PENDING'),
                          ),
                        ),
                        title: Text(check.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(
                          '${check.status} • ${check.checkDate != null ? DateFormat('MMM dd, yyyy').format(check.checkDate!) : ''}'
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Description: ${check.description}'),
                                const SizedBox(height: 8),
                                if (check.remarks != null)
                                  Text('Remarks: ${check.remarks}', style: const TextStyle(color: Colors.grey)),
                                const SizedBox(height: 8),
                                if (check.conductedBy != null)
                                  Text('Inspector: ${check.conductedBy!['firstName'] ?? 'Unknown'}'),
                              ],
                            ),
                          )
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}

class CreateQualityCheckDialog extends StatefulWidget {
  final int projectId;
  final VoidCallback onSave;

  const CreateQualityCheckDialog({
    super.key, 
    required this.projectId, 
    required this.onSave
  });

  @override
  State<CreateQualityCheckDialog> createState() => _CreateQualityCheckDialogState();
}

class _CreateQualityCheckDialogState extends State<CreateQualityCheckDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final QualityCheckService _service = QualityCheckService();
  
  String _status = 'OPEN';
  String _result = 'PENDING';
  bool _isSaving = false;

  final List<String> _statuses = ['OPEN', 'IN_PROGRESS', 'CLOSED'];
  final List<String> _results = ['PENDING', 'PASSED', 'FAILED'];

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final newCheck = QualityCheck(
        projectId: widget.projectId,
        title: _titleController.text,
        description: _descController.text,
        status: _status,
        result: _result,
      );

      await _service.createCheck(newCheck);
      widget.onSave();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        await ErrorHandler.handleApiError(context, e, defaultMessage: 'Failed to create quality check');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New Inspection'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title / Area'),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _status,
                decoration: const InputDecoration(labelText: 'Status'),
                items: _statuses.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                onChanged: (v) => setState(() => _status = v!),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _result,
                decoration: const InputDecoration(labelText: 'Result'),
                items: _results.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                onChanged: (v) => setState(() => _result = v!),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: _isSaving ? null : _submit,
          child: _isSaving ? const CircularProgressIndicator() : const Text('Create'),
        ),
      ],
    );
  }
}

