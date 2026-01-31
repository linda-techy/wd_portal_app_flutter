import 'package:flutter/material.dart';
import 'package:admin/theme/app_theme.dart';
import 'package:admin/features/delays/data/models/delay_log.dart';
import 'package:admin/features/delays/data/services/delay_log_service.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:admin/utils/error_handler.dart';
import 'package:admin/providers/portal_auth_provider.dart';

class DelayLogsScreen extends StatefulWidget {
  final int projectId;

  const DelayLogsScreen({Key? key, required this.projectId}) : super(key: key);

  @override
  _DelayLogsScreenState createState() => _DelayLogsScreenState();
}

class _DelayLogsScreenState extends State<DelayLogsScreen> {
  final DelayLogService _service = DelayLogService();
  List<DelayLog> _delays = [];
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
         Navigator.of(context).pushReplacementNamed('/login');
      }
      return;
    }
    await _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isPageLoading = true);
    try {
      final data = await _service.getDelays(widget.projectId);
      setState(() {
        _delays = data;
        _isPageLoading = false;
      });
    } catch (e) {
    } catch (e) {
      if (mounted) {
        setState(() => _isPageLoading = false);
        await ErrorHandler.handleApiError(context, e, defaultMessage: 'Failed to load delays');
      }
    }
  }

  Future<void> _showAddDialog() async {
    await showDialog(
      context: context,
      builder: (context) => AddDelayDialog(
        projectId: widget.projectId,
        onSave: _loadData,
      ),
    );
  }

  Future<void> _closeDelay(DelayLog delay) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: delay.fromDate,
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      try {
        await _service.closeDelay(widget.projectId, delay.id!, picked);
        _loadData();
      } catch (e) {
        if (mounted) {
            await ErrorHandler.handleApiError(context, e, defaultMessage: 'Failed to close delay');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return _isPageLoading
        ? const Center(child: CircularProgressIndicator())
        : Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Delay Logs',
                      style: AppTheme.headlineMedium,
                    ),
                    ElevatedButton.icon(
                      onPressed: _showAddDialog,
                      icon: const Icon(Icons.timer_off_outlined),
                      label: const Text('Log Delay'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.safetyOrange,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

              // List
              Expanded(
                child: _delays.isEmpty
                    ? Center(child: Text('No delays recorded.', style: AppTheme.bodyMedium))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _delays.length,
                        itemBuilder: (context, index) {
                          return _buildCard(_delays[index]);
                        },
                      ),
              ),
            ],
          );
  }

  Widget _buildCard(DelayLog delay) {
    final isClosed = delay.toDate != null;
    final duration = isClosed
        ? delay.toDate!.difference(delay.fromDate).inDays + 1
        : DateTime.now().difference(delay.fromDate).inDays + 1;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isClosed ? Colors.grey[200] : AppTheme.safetyOrange.withOpacity(0.2),
          child: Icon(
            Icons.warning_amber_rounded,
            color: isClosed ? Colors.grey : AppTheme.safetyOrange,
          ),
        ),
        title: Text(
          delay.delayType.replaceAll('_', ' '),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('Since: ${DateFormat('MMM dd, yyyy').format(delay.fromDate)}'),
            if (isClosed) Text('Closed: ${DateFormat('MMM dd, yyyy').format(delay.toDate!)}'),
            const SizedBox(height: 4),
            Text(isClosed ? 'Lost: $duration days' : 'Ongoing ($duration days)',
                style: TextStyle(
                    color: isClosed ? Colors.grey : AppTheme.safetyOrange,
                    fontWeight: FontWeight.bold)),
            if (delay.reasonText != null)
              Text('${delay.reasonText}', style: const TextStyle(fontSize: 12)),
          ],
        ),
        trailing: !isClosed
            ? TextButton(
                onPressed: () => _closeDelay(delay),
                child: const Text('Close'),
              )
            : const Icon(Icons.check_circle, color: Colors.green),
      ),
    );
  }
}

class AddDelayDialog extends StatefulWidget {
  final int projectId;
  final VoidCallback onSave;

  const AddDelayDialog({Key? key, required this.projectId, required this.onSave}) : super(key: key);

  @override
  _AddDelayDialogState createState() => _AddDelayDialogState();
}

class _AddDelayDialogState extends State<AddDelayDialog> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();
  final DelayLogService _service = DelayLogService();
  
  String _type = 'WEATHER';
  DateTime _fromDate = DateTime.now();
  bool _isSaving = false;

  final List<String> _types = [
    'WEATHER',
    'LABOUR_STRIKE',
    'MATERIAL_DELAY',
    'CLIENT_APPROVAL',
    'OTHER'
  ];

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final newDelay = DelayLog(
        projectId: widget.projectId,
        delayType: _type,
        fromDate: _fromDate,
        reasonText: _reasonController.text,
      );

      await _service.logDelay(newDelay);

      widget.onSave();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
         setState(() => _isSaving = false);
         await ErrorHandler.handleApiError(context, e, defaultMessage: 'Failed to log delay');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Log Delay'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: _type,
                decoration: const InputDecoration(labelText: 'Type'),
                items: _types.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                onChanged: (val) => setState(() => _type = val!),
              ),
              const SizedBox(height: 16),
              InputDatePickerFormField(
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
                initialDate: _fromDate,
                fieldLabelText: 'Start Date',
                onDateSubmitted: (date) => setState(() => _fromDate = date),
                onDateSaved: (date) => setState(() => _fromDate = date),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _reasonController,
                decoration: const InputDecoration(labelText: 'Reason / Details'),
                maxLines: 3,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _submit,
          child: _isSaving
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Log'),
        ),
      ],
    );
  }
}

