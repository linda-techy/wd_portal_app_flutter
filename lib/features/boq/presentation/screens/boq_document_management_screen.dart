import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:admin/services/boq_payment_service.dart';
import 'package:admin/theme/app_theme.dart';
import 'package:admin/utils/error_handler.dart';
import 'package:admin/providers/permission_provider.dart';
import 'package:admin/features/boq/presentation/screens/customer_approve_boq_dialog.dart';
import 'package:admin/features/boq/presentation/screens/payment_schedule_screen.dart';

/// Full lifecycle UI for BoQ documents on a project: create DRAFT, submit for
/// approval, internal sign-off, customer approval (with payment stages),
/// rejection, and revisioning.
class BoqDocumentManagementScreen extends StatefulWidget {
  final int projectId;

  const BoqDocumentManagementScreen({super.key, required this.projectId});

  @override
  State<BoqDocumentManagementScreen> createState() =>
      _BoqDocumentManagementScreenState();
}

class _BoqDocumentManagementScreenState
    extends State<BoqDocumentManagementScreen> {
  final _service = BoqPaymentService();
  final _currency = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 2,
  );
  final _dateFmt = DateFormat('dd MMM yyyy, HH:mm');

  bool _isLoading = true;
  List<BoqDocumentModel> _docs = [];

  // Per-row in-flight transitions, keyed by document id.
  final Set<int> _busyIds = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final docs = await _service.listForProject(widget.projectId);
      if (!mounted) return;
      setState(() {
        _docs = docs;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      await ErrorHandler.handleApiError(context, e,
          defaultMessage: 'Failed to load BoQ documents');
    }
  }

  bool get _hasDraft =>
      _docs.any((d) => d.status.toUpperCase() == 'DRAFT');

  Future<void> _createDocument() async {
    setState(() => _isLoading = true);
    try {
      await _service.createDocument(widget.projectId);
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Draft BoQ document created.')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      final msg = e.toString();
      if (msg.contains('409') ||
          msg.toLowerCase().contains('already') ||
          msg.toLowerCase().contains('exists')) {
        await ErrorHandler.handleApiError(
          context,
          'A draft already exists for this project.',
          defaultMessage: 'Could not create document',
        );
      } else {
        await ErrorHandler.handleApiError(context, e,
            defaultMessage: 'Failed to create document');
      }
    }
  }

  Future<void> _runTransition(
    BoqDocumentModel doc,
    Future<BoqDocumentModel> Function() action, {
    required String successMessage,
    required String failureMessage,
  }) async {
    setState(() => _busyIds.add(doc.id));
    try {
      await action();
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(successMessage)),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _busyIds.remove(doc.id));
      await ErrorHandler.handleApiError(context, e,
          defaultMessage: failureMessage);
    } finally {
      if (mounted) {
        setState(() => _busyIds.remove(doc.id));
      }
    }
  }

  Future<void> _submit(BoqDocumentModel doc) async {
    await _runTransition(
      doc,
      () => _service.submitDocument(doc.id),
      successMessage: 'Document submitted for approval.',
      failureMessage: 'Failed to submit document',
    );
  }

  Future<void> _approveInternal(BoqDocumentModel doc) async {
    await _runTransition(
      doc,
      () => _service.approveDocumentInternally(doc.id),
      successMessage: 'Internal approval recorded.',
      failureMessage: 'Failed to approve internally',
    );
  }

  Future<void> _customerApprove(BoqDocumentModel doc) async {
    final approved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => CustomerApproveBoqDialog(
        boqDocumentId: doc.id,
        projectId: widget.projectId,
        onApproved: () {},
      ),
    );
    if (approved == true) {
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Customer approval recorded.')),
      );
    }
  }

  Future<void> _reject(BoqDocumentModel doc) async {
    final reason = await _promptRejectReason();
    if (reason == null || reason.trim().isEmpty) return;
    await _runTransition(
      doc,
      () => _service.rejectDocument(doc.id, reason.trim()),
      successMessage: 'Document rejected.',
      failureMessage: 'Failed to reject document',
    );
  }

  Future<String?> _promptRejectReason() async {
    final ctrl = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject BoQ Document'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
                'Provide a reason — this is recorded with the rejection.'),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              autofocus: true,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'e.g. Pricing not aligned with revised scope',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(null),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorRed,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(ctrl.text),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
    return result;
  }

  void _viewPaymentSchedule() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            PaymentScheduleScreen(projectId: widget.projectId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final perms = context.watch<PermissionProvider>();
    final canCreate = perms.canCreateBoq;
    return Scaffold(
      appBar: AppBar(
        title: const Text('BoQ Documents'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _load,
            tooltip: 'Refresh',
          ),
        ],
      ),
      floatingActionButton: canCreate && !_hasDraft && !_isLoading
          ? FloatingActionButton.extended(
              onPressed: _createDocument,
              backgroundColor: AppTheme.deepSlate,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('New Document'),
            )
          : null,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _docs.isEmpty
                  ? _buildEmptyState(canCreate)
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                      itemCount: _docs.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (_, i) => _buildDocCard(_docs[i], perms),
                    ),
            ),
    );
  }

  Widget _buildEmptyState(bool canCreate) {
    return ListView(
      // ListView so RefreshIndicator works in empty state.
      children: [
        const SizedBox(height: 80),
        const Icon(Icons.description_outlined,
            size: 64, color: Colors.grey),
        const SizedBox(height: 16),
        const Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'No BoQ documents yet — create one to start the approval workflow.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: Colors.black54),
            ),
          ),
        ),
        const SizedBox(height: 24),
        if (canCreate)
          Center(
            child: ElevatedButton.icon(
              onPressed: _createDocument,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.deepSlate,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 12),
              ),
              icon: const Icon(Icons.add),
              label: const Text('New Document'),
            ),
          ),
      ],
    );
  }

  Widget _buildDocCard(BoqDocumentModel doc, PermissionProvider perms) {
    final status = doc.status.toUpperCase();
    final isBusy = _busyIds.contains(doc.id);
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _statusPill(status),
                const SizedBox(width: 10),
                Text(
                  'Revision ${doc.revisionNumber}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const Spacer(),
                Text(
                  doc.createdAt != null
                      ? 'Created ${_dateFmt.format(doc.createdAt!.toLocal())}'
                      : '',
                  style:
                      const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _kv('Total ex-GST',
                      _currency.format(doc.totalValueExGst)),
                ),
                Expanded(
                  child: _kv(
                      'GST (${(doc.gstRate * 100).toStringAsFixed(0)}%)',
                      _currency.format(doc.totalGstAmount)),
                ),
                Expanded(
                  child: _kv('Total incl-GST',
                      _currency.format(doc.totalValueInclGst),
                      bold: true),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildTimestamps(doc),
            if (status == 'REJECTED' && (doc.rejectionReason ?? '').isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.errorRed.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.error_outline,
                          color: AppTheme.errorRed, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Rejection reason: ${doc.rejectionReason!}',
                          style: const TextStyle(color: AppTheme.errorRed),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 12),
            _buildActionRow(doc, status, isBusy, perms),
          ],
        ),
      ),
    );
  }

  Widget _kv(String k, String v, {bool bold = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(k,
            style: const TextStyle(fontSize: 11, color: Colors.black54)),
        const SizedBox(height: 2),
        Text(v,
            style: TextStyle(
                fontSize: 14,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w500)),
      ],
    );
  }

  Widget _buildTimestamps(BoqDocumentModel doc) {
    final entries = <(String, DateTime?)>[
      ('Submitted', doc.submittedAt),
      ('Internally approved', doc.approvedAt),
      ('Customer approved', doc.customerApprovedAt),
      if (doc.rejectedAt != null) ('Rejected', doc.rejectedAt),
    ].where((e) => e.$2 != null).toList();
    if (entries.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: 16,
      runSpacing: 4,
      children: entries
          .map((e) => Text(
                '${e.$1}: ${_dateFmt.format(e.$2!.toLocal())}',
                style:
                    const TextStyle(fontSize: 12, color: Colors.black54),
              ))
          .toList(),
    );
  }

  Widget _buildActionRow(
    BoqDocumentModel doc,
    String status,
    bool isBusy,
    PermissionProvider perms,
  ) {
    final actions = <Widget>[];

    if (isBusy) {
      actions.add(const Padding(
        padding: EdgeInsets.all(6),
        child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2)),
      ));
    } else {
      switch (status) {
        case 'DRAFT':
          if (perms.canSubmitBoqDoc) {
            actions.add(_primaryAction(
              icon: Icons.send_outlined,
              label: 'Submit for Approval',
              onPressed: () => _submit(doc),
            ));
          }
          break;
        case 'PENDING_APPROVAL':
          if (doc.approvedAt == null) {
            if (perms.canApproveBoq) {
              actions.add(_primaryAction(
                icon: Icons.verified_user_outlined,
                label: 'Internal Approve',
                onPressed: () => _approveInternal(doc),
              ));
            }
          } else {
            if (perms.canCustomerApproveBoq) {
              actions.add(_primaryAction(
                icon: Icons.verified_outlined,
                label: 'Record Customer Approval',
                onPressed: () => _customerApprove(doc),
              ));
            }
          }
          if (perms.canApproveBoq) {
            actions.add(_secondaryAction(
              icon: Icons.cancel_outlined,
              label: 'Reject',
              color: AppTheme.errorRed,
              onPressed: () => _reject(doc),
            ));
          }
          break;
        case 'APPROVED':
          actions.add(_secondaryAction(
            icon: Icons.list_alt,
            label: 'View Payment Schedule',
            onPressed: _viewPaymentSchedule,
          ));
          break;
        case 'REJECTED':
          if (perms.canCreateBoq) {
            actions.add(_primaryAction(
              icon: Icons.refresh,
              label: 'Create Revision',
              onPressed: _createDocument,
            ));
          }
          break;
      }
    }

    if (actions.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.end,
      children: actions,
    );
  }

  Widget _primaryAction({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.coralRed,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      ),
      icon: Icon(icon, size: 16),
      label: Text(label),
    );
  }

  Widget _secondaryAction({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    Color? color,
  }) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      ),
      icon: Icon(icon, size: 16),
      label: Text(label),
    );
  }

  Widget _statusPill(String status) {
    final (Color bg, Color fg, String label) = switch (status) {
      'DRAFT' => (Colors.grey.shade300, Colors.black87, 'Draft'),
      'PENDING_APPROVAL' => (
        AppTheme.warningAmber.withOpacity(0.2),
        Colors.orange.shade900,
        'Pending Approval'
      ),
      'APPROVED' => (
        AppTheme.successGreen.withOpacity(0.18),
        Colors.green.shade900,
        'Approved'
      ),
      'REJECTED' => (
        AppTheme.errorRed.withOpacity(0.15),
        AppTheme.errorRed,
        'Rejected'
      ),
      _ => (Colors.grey.shade200, Colors.black54, status),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
            color: fg, fontWeight: FontWeight.w600, fontSize: 12),
      ),
    );
  }
}
