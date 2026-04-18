import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../../services/quality_check_service.dart';
import '../../../../services/reports/quality_report.dart';
import '../../../../theme/app_theme.dart';
import '../../../../utils/error_handler.dart';
import '../../../../providers/portal_auth_provider.dart';

class QualityChecksScreen extends StatefulWidget {
  final int projectId;

  const QualityChecksScreen({super.key, required this.projectId});

  @override
  State<QualityChecksScreen> createState() => _QualityChecksScreenState();
}

class _QualityChecksScreenState extends State<QualityChecksScreen>
    with SingleTickerProviderStateMixin {
  final QualityCheckService _service = QualityCheckService();
  late TabController _tabController;
  List<QualityCheck> _checks = [];
  bool _isLoading = true;
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _verifyAuthAndLoadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _verifyAuthAndLoadData() async {
    final authProvider =
        Provider.of<PortalAuthProvider>(context, listen: false);
    if (!authProvider.isAuthenticated) {
      if (mounted) {
        await ErrorHandler.handleAuthError(context);
        if (mounted) Navigator.of(context).pushReplacementNamed('/login');
      }
      return;
    }
    await _loadData();
  }

  Future<void> _exportPdf() async {
    setState(() => _isExporting = true);
    try {
      await QualityReport.generate(
        projectName: 'Project',
        qualityChecks: _checks,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDF export failed: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final checks = await _service.getProjectChecks(widget.projectId);
      if (mounted) {
        setState(() {
          _checks = checks;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        await ErrorHandler.handleApiError(context, e,
            defaultMessage: 'Failed to load quality checks');
      }
    }
  }

  List<QualityCheck> _filterByStatus(String status) {
    return _checks.where((c) => c.status.toUpperCase() == status).toList();
  }

  int _countByResult(String result) {
    return _checks.where((c) => c.result?.toUpperCase() == result).length;
  }

  @override
  Widget build(BuildContext context) {
    final openChecks = _filterByStatus('OPEN');
    final inProgressChecks = _filterByStatus('IN_PROGRESS');
    final closedChecks = _filterByStatus('CLOSED');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quality Checks'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Open (${openChecks.length})'),
            Tab(text: 'In Progress (${inProgressChecks.length})'),
            Tab(text: 'Closed (${closedChecks.length})'),
          ],
        ),
        actions: [
          IconButton(
            icon: _isExporting
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.download_outlined),
            tooltip: 'Export PDF',
            onPressed: _isExporting ? null : _exportPdf,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateDialog(),
        backgroundColor: AppTheme.deepSlate,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Summary stats
                _buildSummaryBar(),
                // Tab content
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildCheckList(openChecks),
                      _buildCheckList(inProgressChecks),
                      _buildCheckList(closedChecks),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSummaryBar() {
    final passed = _countByResult('PASSED');
    final failed = _countByResult('FAILED');
    final pending = _countByResult('PENDING');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        border: Border(bottom: BorderSide(color: AppTheme.borderLight.withOpacity(0.5))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStat('Total', '${_checks.length}', AppTheme.deepSlate),
          _buildStat('Passed', '$passed', AppTheme.successGreen),
          _buildStat('Failed', '$failed', AppTheme.errorRed),
          _buildStat('Pending', '$pending', AppTheme.constructionOrange),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
      ],
    );
  }

  Widget _buildCheckList(List<QualityCheck> checks) {
    if (checks.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.fact_check_outlined, size: 48, color: Colors.grey),
            SizedBox(height: 12),
            Text('No checks in this category',
                style: TextStyle(fontSize: 15, color: Colors.grey)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: checks.length,
        itemBuilder: (context, index) => _buildCheckCard(checks[index]),
      ),
    );
  }

  Widget _buildCheckCard(QualityCheck check) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppTheme.borderLight.withOpacity(0.5)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showCheckDetail(check),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: _getResultColor(check.result).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getResultIcon(check.result),
                      color: _getResultColor(check.result),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          check.title,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        if (check.checkDate != null)
                          Text(
                            DateFormat('MMM d, yyyy').format(check.checkDate!),
                            style: const TextStyle(
                                fontSize: 12, color: AppTheme.textSecondary),
                          ),
                      ],
                    ),
                  ),
                  _buildResultBadge(check.result ?? 'PENDING'),
                ],
              ),
              if (check.description.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  check.description,
                  style: const TextStyle(
                      fontSize: 13, color: AppTheme.textSecondary),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (check.remarks != null && check.remarks!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceElevated,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Remarks: ${check.remarks}',
                    style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildStatusChip(check.status),
                  const Spacer(),
                  if (check.conductedBy != null)
                    Row(
                      children: [
                        const Icon(Icons.person_outline,
                            size: 14, color: AppTheme.textTertiary),
                        const SizedBox(width: 4),
                        Text(
                          check.conductedBy!['firstName'] ?? 'Unknown',
                          style: const TextStyle(
                              fontSize: 12, color: AppTheme.textTertiary),
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultBadge(String result) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _getResultColor(result).withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        result,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: _getResultColor(result),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _getStatusColor(status).withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status.replaceAll('_', ' '),
        style: TextStyle(
          fontSize: 11,
          color: _getStatusColor(status),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  void _showCheckDetail(QualityCheck check) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.85,
        builder: (context, scrollController) => Padding(
          padding: const EdgeInsets.all(20),
          child: ListView(
            controller: scrollController,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: _getResultColor(check.result).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _getResultIcon(check.result),
                      color: _getResultColor(check.result),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(check.title,
                            style: const TextStyle(
                                fontSize: 17, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            _buildStatusChip(check.status),
                            const SizedBox(width: 8),
                            _buildResultBadge(check.result ?? 'PENDING'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (check.description.isNotEmpty) ...[
                _buildInfoSection('Description', check.description),
              ],
              if (check.checkDate != null)
                _buildInfoRow(
                    Icons.calendar_today,
                    'Inspection Date',
                    DateFormat('EEEE, MMM d, yyyy').format(check.checkDate!)),
              if (check.conductedBy != null)
                _buildInfoRow(Icons.person, 'Inspector',
                    check.conductedBy!['firstName'] ?? 'Unknown'),
              if (check.remarks != null && check.remarks!.isNotEmpty)
                _buildInfoSection('Remarks', check.remarks!),
              const SizedBox(height: 20),
              // Actions
              Row(
                children: [
                  if (check.status != 'CLOSED')
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _showUpdateDialog(check);
                        },
                        icon: const Icon(Icons.edit, size: 18, color: Colors.white),
                        label: const Text('Update',
                            style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.deepSlate,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  if (check.status != 'CLOSED' &&
                      check.result != 'PASSED' &&
                      check.result != 'FAILED') ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _resolveCheck(check, 'PASSED');
                        },
                        icon: const Icon(Icons.check, size: 18, color: Colors.white),
                        label: const Text('Pass',
                            style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.successGreen,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _resolveCheck(check, 'FAILED');
                        },
                        icon: const Icon(Icons.close, size: 18, color: Colors.white),
                        label: const Text('Fail',
                            style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.errorRed,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoSection(String label, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
          const SizedBox(height: 4),
          Text(content, style: const TextStyle(fontSize: 14, height: 1.4)),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppTheme.textSecondary),
          const SizedBox(width: 8),
          Text('$label: ',
              style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Future<void> _resolveCheck(QualityCheck check, String result) async {
    final remarksController = TextEditingController();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(result == 'PASSED' ? 'Mark as Passed' : 'Mark as Failed'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Are you sure you want to mark "${check.title}" as ${result.toLowerCase()}?',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: remarksController,
              decoration: const InputDecoration(
                labelText: 'Remarks (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  result == 'PASSED' ? AppTheme.successGreen : AppTheme.errorRed,
            ),
            child: Text(result == 'PASSED' ? 'Pass' : 'Fail',
                style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true && check.id != null && mounted) {
      try {
        final updated = QualityCheck(
          projectId: check.projectId,
          title: check.title,
          description: check.description,
          status: 'CLOSED',
          result: result,
          remarks: remarksController.text.isNotEmpty
              ? remarksController.text
              : check.remarks,
        );
        await _service.updateCheck(check.id!, updated);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Quality check ${result == 'PASSED' ? 'passed' : 'failed'}'),
              backgroundColor:
                  result == 'PASSED' ? AppTheme.successGreen : AppTheme.errorRed,
            ),
          );
        }
        await _loadData();
      } catch (e) {
        if (mounted) {
          await ErrorHandler.handleApiError(context, e,
              defaultMessage: 'Failed to update quality check');
        }
      }
    }
  }

  Future<void> _showUpdateDialog(QualityCheck check) async {
    final remarksController = TextEditingController(text: check.remarks ?? '');
    String status = check.status;
    String result = check.result ?? 'PENDING';

    final statuses = ['OPEN', 'IN_PROGRESS', 'CLOSED'];
    final results = ['PENDING', 'PASSED', 'FAILED'];

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Update Quality Check'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: status,
                  decoration: const InputDecoration(labelText: 'Status'),
                  items: statuses
                      .map((s) => DropdownMenuItem(value: s, child: Text(s.replaceAll('_', ' '))))
                      .toList(),
                  onChanged: (v) => setDialogState(() => status = v!),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: result,
                  decoration: const InputDecoration(labelText: 'Result'),
                  items: results
                      .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                      .toList(),
                  onChanged: (v) => setDialogState(() => result = v!),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: remarksController,
                  decoration: const InputDecoration(
                    labelText: 'Remarks',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.deepSlate),
              child:
                  const Text('Update', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );

    if (confirm == true && check.id != null && mounted) {
      try {
        final updated = QualityCheck(
          projectId: check.projectId,
          title: check.title,
          description: check.description,
          status: status,
          result: result,
          remarks: remarksController.text.isNotEmpty
              ? remarksController.text
              : null,
        );
        await _service.updateCheck(check.id!, updated);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Quality check updated'),
                backgroundColor: AppTheme.successGreen),
          );
        }
        await _loadData();
      } catch (e) {
        if (mounted) {
          await ErrorHandler.handleApiError(context, e,
              defaultMessage: 'Failed to update quality check');
        }
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
      case 'OPEN':
        return AppTheme.skyBlue;
      case 'IN_PROGRESS':
        return AppTheme.constructionOrange;
      case 'CLOSED':
        return AppTheme.textSecondary;
      default:
        return Colors.grey;
    }
  }

  Color _getResultColor(String? result) {
    switch ((result ?? '').toUpperCase()) {
      case 'PASSED':
        return AppTheme.successGreen;
      case 'FAILED':
        return AppTheme.errorRed;
      case 'PENDING':
        return AppTheme.constructionOrange;
      default:
        return Colors.grey;
    }
  }

  IconData _getResultIcon(String? result) {
    switch ((result ?? '').toUpperCase()) {
      case 'PASSED':
        return Icons.check_circle;
      case 'FAILED':
        return Icons.cancel;
      default:
        return Icons.pending;
    }
  }
}

class CreateQualityCheckDialog extends StatefulWidget {
  final int projectId;
  final VoidCallback onSave;

  const CreateQualityCheckDialog({
    super.key,
    required this.projectId,
    required this.onSave,
  });

  @override
  State<CreateQualityCheckDialog> createState() =>
      _CreateQualityCheckDialogState();
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
        await ErrorHandler.handleApiError(context, e,
            defaultMessage: 'Failed to create quality check');
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
                decoration:
                    const InputDecoration(labelText: 'Title / Area *'),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(labelText: 'Description *'),
                maxLines: 3,
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _status,
                decoration: const InputDecoration(labelText: 'Status'),
                items: _statuses
                    .map((s) => DropdownMenuItem(
                        value: s, child: Text(s.replaceAll('_', ' '))))
                    .toList(),
                onChanged: (v) => setState(() => _status = v!),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _result,
                decoration: const InputDecoration(labelText: 'Result'),
                items: _results
                    .map(
                        (r) => DropdownMenuItem(value: r, child: Text(r)))
                    .toList(),
                onChanged: (v) => setState(() => _result = v!),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel')),
        ElevatedButton(
          onPressed: _isSaving ? null : _submit,
          style:
              ElevatedButton.styleFrom(backgroundColor: AppTheme.deepSlate),
          child: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : const Text('Create', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
