import 'package:flutter/material.dart';
import 'package:admin/theme/app_theme.dart';
import 'package:admin/features/delays/data/models/delay_log.dart';
import 'package:admin/features/delays/data/services/delay_log_service.dart';
import 'package:admin/services/outbox_service.dart';
import 'package:admin/services/sync_service.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:admin/utils/error_handler.dart';
import 'package:admin/providers/portal_auth_provider.dart';
import 'package:admin/services/reports/delay_report.dart';

// ─── Category constants ───────────────────────────────────────────────────────

const List<String> _kCategories = [
  'WEATHER',
  'MATERIAL_SHORTAGE',
  'LABOUR',
  'PERMITS',
  'CLIENT_DECISION',
  'SUBCONTRACTOR',
  'DESIGN_CHANGES',
  'OTHER',
];

Color _categoryColor(String? category) {
  switch ((category ?? '').toUpperCase()) {
    case 'WEATHER':
      return Colors.blue;
    case 'MATERIAL_SHORTAGE':
      return Colors.orange;
    case 'LABOUR':
      return Colors.red;
    case 'PERMITS':
      return Colors.purple;
    case 'CLIENT_DECISION':
      return Colors.teal;
    case 'SUBCONTRACTOR':
      return Colors.brown;
    case 'DESIGN_CHANGES':
      return Colors.indigo;
    default:
      return Colors.grey;
  }
}

// ─── Screen ───────────────────────────────────────────────────────────────────

class DelayLogsScreen extends StatefulWidget {
  final int projectId;

  const DelayLogsScreen({super.key, required this.projectId});

  @override
  State<DelayLogsScreen> createState() => _DelayLogsScreenState();
}

class _DelayLogsScreenState extends State<DelayLogsScreen> {
  final DelayLogService _service = DelayLogService();
  List<DelayLog> _delays = [];
  Map<String, dynamic> _summary = {};
  bool _isPageLoading = true;

  @override
  void initState() {
    super.initState();
    _verifyAuthAndLoadData();
  }

  Future<void> _verifyAuthAndLoadData() async {
    final authProvider = Provider.of<PortalAuthProvider>(context, listen: false);
    if (!authProvider.isAuthenticated) {
      if (!mounted) return;
      await ErrorHandler.handleAuthError(context);
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/login');
      return;
    }
    await _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isPageLoading = true);
    try {
      final results = await Future.wait([
        _service.getDelays(widget.projectId),
        _service.getSummary(widget.projectId),
      ]);
      if (!mounted) return;
      setState(() {
        _delays = results[0] as List<DelayLog>;
        _summary = results[1] as Map<String, dynamic>;
        _isPageLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isPageLoading = false);
        await ErrorHandler.handleApiError(context, e,
            defaultMessage: 'Failed to load delays');
      }
    }
  }

  Future<void> _exportPdf() async {
    try {
      await DelayReport.generate(
          projectName: 'Project ${widget.projectId}', delays: _delays);
    } catch (e) {
      if (mounted) {
        await ErrorHandler.handleApiError(context, e,
            defaultMessage: 'PDF export failed');
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
          await ErrorHandler.handleApiError(context, e,
              defaultMessage: 'Failed to close delay');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return _isPageLoading
        ? const Center(child: CircularProgressIndicator())
        : Stack(
            children: [
              Column(
                children: [
                  // Header row
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Delay Logs', style: AppTheme.headlineMedium),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.picture_as_pdf_outlined),
                              tooltip: 'Export PDF',
                              onPressed: _exportPdf,
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
                      ],
                    ),
                  ),

                  // Summary card
                  if (_summary.isNotEmpty) _buildSummaryCard(),

                  // List
                  Expanded(
                    child: _delays.isEmpty
                        ? Center(
                            child: Text('No delays recorded.',
                                style: AppTheme.bodyMedium))
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                            itemCount: _delays.length,
                            itemBuilder: (context, index) =>
                                _buildCard(_delays[index]),
                          ),
                  ),
                ],
              ),

              // FAB
              Positioned(
                right: 16,
                bottom: 16,
                child: FloatingActionButton.extended(
                  onPressed: _showAddDialog,
                  backgroundColor: AppTheme.safetyOrange,
                  foregroundColor: Colors.white,
                  icon: const Icon(Icons.add),
                  label: const Text('Log Delay'),
                ),
              ),
            ],
          );
  }

  Widget _buildSummaryCard() {
    final totalDelays = _summary['totalDelays'] ?? 0;
    final totalDaysLost = _summary['totalDaysLost'] ?? 0;
    final breakdown =
        (_summary['breakdownByCategory'] as Map<String, dynamic>?) ?? {};

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.safetyOrange.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.safetyOrange.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.analytics_outlined, size: 18),
              const SizedBox(width: 6),
              Text('Summary', style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildSummaryTile('Total Delays', '$totalDelays', Icons.warning_amber_rounded),
              const SizedBox(width: 16),
              _buildSummaryTile('Days Lost', '$totalDaysLost', Icons.schedule),
            ],
          ),
          if (breakdown.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: breakdown.entries.map((e) {
                final color = _categoryColor(e.key);
                return Chip(
                  label: Text('${e.key.replaceAll('_', ' ')}: ${e.value}',
                      style: TextStyle(fontSize: 11, color: color)),
                  backgroundColor: color.withOpacity(0.1),
                  side: BorderSide(color: color.withOpacity(0.3)),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  visualDensity: VisualDensity.compact,
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryTile(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppTheme.safetyOrange),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                Text(label,
                    style: TextStyle(fontSize: 11, color: Colors.grey[600])),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(DelayLog delay) {
    final isClosed = delay.toDate != null;
    final duration = delay.durationDays;
    final catColor = _categoryColor(delay.reasonCategory ?? delay.delayType);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: category chip + duration badge + status
            Row(
              children: [
                // Category chip
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: catColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    delay.categoryLabel,
                    style: TextStyle(
                        color: catColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 8),
                // Duration badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.schedule, size: 12, color: Colors.grey[600]),
                      const SizedBox(width: 3),
                      Text(
                        '$duration day${duration == 1 ? '' : 's'}',
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey[700]),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                // Open/closed chip
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: (isClosed ? Colors.green : AppTheme.safetyOrange)
                        .withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    isClosed ? 'Closed' : 'Open',
                    style: TextStyle(
                        fontSize: 11,
                        color: isClosed ? Colors.green : AppTheme.safetyOrange,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Dates
            Text(
              isClosed
                  ? 'Since: ${DateFormat('MMM dd, yyyy').format(delay.fromDate)}  –  Closed: ${DateFormat('MMM dd, yyyy').format(delay.toDate!)}'
                  : 'Since: ${DateFormat('MMM dd, yyyy').format(delay.fromDate)}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),

            // Responsible party
            if (delay.responsibleParty != null &&
                delay.responsibleParty!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.person_outline, size: 13, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(delay.responsibleParty!,
                      style:
                          TextStyle(fontSize: 12, color: Colors.grey[600])),
                ],
              ),
            ],

            // Reason text
            if (delay.reasonText != null && delay.reasonText!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(delay.reasonText!,
                  style: const TextStyle(fontSize: 13),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
            ],

            // Impact description
            if (delay.impactDescription != null &&
                delay.impactDescription!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text('Impact: ${delay.impactDescription!}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
            ],

            // Close button
            if (!isClosed) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => _closeDelay(delay),
                  child: const Text('Close Delay'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Add Delay Dialog ─────────────────────────────────────────────────────────

class AddDelayDialog extends StatefulWidget {
  final int projectId;
  final VoidCallback onSave;

  const AddDelayDialog(
      {super.key, required this.projectId, required this.onSave});

  @override
  State<AddDelayDialog> createState() => _AddDelayDialogState();
}

class _AddDelayDialogState extends State<AddDelayDialog> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();
  final _responsibleController = TextEditingController();
  final _impactController = TextEditingController();
  final _durationController = TextEditingController();
  final _customerSummaryController = TextEditingController();
  // PR2: DelayLogService is built at submit time via [DelayLogService.forOutbox]
  // reading OutboxService + SyncService from the widget tree.

  String _category = 'WEATHER';
  DateTime _fromDate = DateTime.now();
  bool _isSaving = false;
  bool _customerVisible = false;
  String _impactOnHandover = 'NONE'; // NONE | MINOR | MATERIAL

  @override
  void dispose() {
    _reasonController.dispose();
    _responsibleController.dispose();
    _impactController.dispose();
    _durationController.dispose();
    _customerSummaryController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fromDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _fromDate = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      // PR2: capture providers before any async work.
      final outbox = context.read<OutboxService>();
      final sync = context.read<SyncService>();

      final durationText = _durationController.text.trim();
      final customerSummary = _customerSummaryController.text.trim();
      final newDelay = DelayLog(
        projectId: widget.projectId,
        delayType: _category,
        reasonCategory: _category,
        fromDate: _fromDate,
        reasonText: _reasonController.text.trim().isEmpty
            ? null
            : _reasonController.text.trim(),
        responsibleParty: _responsibleController.text.trim().isEmpty
            ? null
            : _responsibleController.text.trim(),
        durationDaysField:
            durationText.isEmpty ? null : int.tryParse(durationText),
        impactDescription: _impactController.text.trim().isEmpty
            ? null
            : _impactController.text.trim(),
        customerVisible: _customerVisible,
        customerSummary: customerSummary.isEmpty ? null : customerSummary,
        impactOnHandover: _customerVisible ? _impactOnHandover : null,
      );

      // PR2: enqueue via the outbox; SyncService dispatches when online.
      await DelayLogService.forOutbox(outbox: outbox, sync: sync)
          .logDelayQueued(newDelay);
      widget.onSave();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        await ErrorHandler.handleApiError(context, e,
            defaultMessage: 'Failed to log delay');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Log Delay'),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Reason category dropdown
                DropdownButtonFormField<String>(
                  value: _category,
                  decoration: const InputDecoration(
                      labelText: 'Reason Category', border: OutlineInputBorder()),
                  items: _kCategories
                      .map((c) => DropdownMenuItem(
                          value: c,
                          child: Row(
                            children: [
                              Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                      color: _categoryColor(c),
                                      shape: BoxShape.circle)),
                              const SizedBox(width: 8),
                              Text(c.replaceAll('_', ' ')),
                            ],
                          )))
                      .toList(),
                  onChanged: (val) => setState(() => _category = val!),
                  validator: (v) => v == null ? 'Required' : null,
                ),
                const SizedBox(height: 12),

                // Date picker
                InkWell(
                  onTap: _pickDate,
                  child: InputDecorator(
                    decoration: const InputDecoration(
                        labelText: 'Start Date', border: OutlineInputBorder()),
                    child: Row(
                      children: [
                        Text(DateFormat('MMM dd, yyyy').format(_fromDate)),
                        const Spacer(),
                        const Icon(Icons.calendar_today_outlined, size: 18),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Duration days
                TextFormField(
                  controller: _durationController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                      labelText: 'Duration (days)',
                      border: OutlineInputBorder(),
                      hintText: 'Optional'),
                  validator: (v) {
                    if (v != null && v.trim().isNotEmpty) {
                      final n = int.tryParse(v.trim());
                      if (n == null || n < 1) return 'Enter a valid number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                // Responsible party
                TextFormField(
                  controller: _responsibleController,
                  decoration: const InputDecoration(
                      labelText: 'Responsible Party',
                      border: OutlineInputBorder(),
                      hintText: 'e.g. Contractor, Client, Vendor'),
                ),
                const SizedBox(height: 12),

                // Reason / details
                TextFormField(
                  controller: _reasonController,
                  decoration: const InputDecoration(
                      labelText: 'Reason / Details',
                      border: OutlineInputBorder()),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),

                // Impact description (internal)
                TextFormField(
                  controller: _impactController,
                  decoration: const InputDecoration(
                      labelText: 'Impact Description (internal)',
                      border: OutlineInputBorder(),
                      hintText: 'Describe effect on schedule or cost — not shown to customer'),
                  maxLines: 3,
                ),
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 8),

                // ─── Customer-visible section ───────────────────────────
                Row(
                  children: [
                    const Icon(Icons.visibility_outlined, size: 18),
                    const SizedBox(width: 6),
                    const Text('Share with customer',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    const Spacer(),
                    Switch(
                      value: _customerVisible,
                      onChanged: (v) => setState(() => _customerVisible = v),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'When enabled, the customer sees the summary + impact below. '
                  'The internal fields above remain private.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 12),

                if (_customerVisible) ...[
                  // Customer summary (curated)
                  TextFormField(
                    controller: _customerSummaryController,
                    decoration: const InputDecoration(
                        labelText: 'Customer Summary',
                        border: OutlineInputBorder(),
                        hintText:
                            'e.g. "Pour rescheduled due to heavy rainfall; no impact on handover."'),
                    maxLines: 3,
                    validator: (v) {
                      if (_customerVisible && (v == null || v.trim().isEmpty)) {
                        return 'Required when shared with customer';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),

                  // Impact on handover dropdown
                  DropdownButtonFormField<String>(
                    value: _impactOnHandover,
                    decoration: const InputDecoration(
                        labelText: 'Impact on Handover Date',
                        border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(
                          value: 'NONE',
                          child: Text('None — handover date unchanged')),
                      DropdownMenuItem(
                          value: 'MINOR',
                          child: Text('Minor — under 1 week slip')),
                      DropdownMenuItem(
                          value: 'MATERIAL',
                          child: Text('Material — handover date changes')),
                    ],
                    onChanged: (val) =>
                        setState(() => _impactOnHandover = val ?? 'NONE'),
                  ),
                ],
              ],
            ),
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
          style:
              ElevatedButton.styleFrom(backgroundColor: AppTheme.safetyOrange),
          child: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : const Text('Log Delay',
                  style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
