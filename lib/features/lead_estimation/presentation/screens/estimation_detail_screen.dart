import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:admin/features/lead_estimation/data/models/estimation_sub_resource.dart';
import 'package:admin/features/lead_estimation/data/models/lead_estimation.dart';
import 'package:admin/features/lead_estimation/providers/estimation_detail_provider.dart';
import 'package:admin/utils/file_download_helper.dart';

class EstimationDetailScreen extends StatefulWidget {
  final String estimationId;

  /// Optional injected provider — used by tests. Production callers omit it.
  final EstimationDetailProvider? providerOverride;

  const EstimationDetailScreen({
    super.key,
    required this.estimationId,
    this.providerOverride,
  });

  @override
  State<EstimationDetailScreen> createState() => _EstimationDetailScreenState();
}

class _EstimationDetailScreenState extends State<EstimationDetailScreen> {
  late final EstimationDetailProvider _provider;

  @override
  void initState() {
    super.initState();
    _provider = widget.providerOverride ?? EstimationDetailProvider();
    if (widget.providerOverride == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _provider.loadEstimation(widget.estimationId);
      });
    }
  }

  @override
  void dispose() {
    if (widget.providerOverride == null) _provider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<EstimationDetailProvider>.value(
      value: _provider,
      child: Consumer<EstimationDetailProvider>(
        builder: (context, p, _) {
          final detail = p.detail;
          return Scaffold(
            appBar: AppBar(
              title: Text(detail != null
                  ? 'Estimation ${detail.estimationNo}'
                  : 'Estimation Detail'),
              actions: [
                if (detail != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: _StatusChip(status: detail.status),
                  ),
                const SizedBox(width: 4),
                if (detail != null)
                  p.isPdfDownloading
                      ? const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : IconButton(
                          icon: const Icon(Icons.picture_as_pdf_outlined),
                          tooltip: 'Download PDF',
                          onPressed: () => _downloadPdf(context, p, detail),
                        ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Refresh',
                  onPressed: () =>
                      _provider.loadEstimation(widget.estimationId),
                ),
              ],
            ),
            body: _buildBody(context, p, detail),
          );
        },
      ),
    );
  }

  Future<void> _downloadPdf(
    BuildContext context,
    EstimationDetailProvider p,
    LeadEstimationDetail detail,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final bytes = await p.downloadPdf();
    if (bytes == null) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(
        content: Text(p.errorMessage ?? 'Failed to download PDF'),
        backgroundColor: Colors.red,
      ));
      return;
    }
    final fileName = 'estimation-${detail.estimationNo}.pdf';
    if (kIsWeb) {
      await FileDownloadHelper.downloadAndShareFile(
        bytes: Uint8List.fromList(bytes),
        fileName: fileName,
        mimeType: 'application/pdf',
      );
    } else {
      await FileDownloadHelper.downloadAndShareFile(
        bytes: Uint8List.fromList(bytes),
        fileName: fileName,
        mimeType: 'application/pdf',
        shareText: 'Estimation ${detail.estimationNo}',
      );
    }
  }

  Widget _buildBody(
      BuildContext context, EstimationDetailProvider p, LeadEstimationDetail? detail) {
    if (p.isLoading && detail == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (p.errorMessage != null && detail == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(p.errorMessage!,
                style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => _provider.loadEstimation(widget.estimationId),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    if (detail == null) return const SizedBox.shrink();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildHeaderCard(context, detail),
        const SizedBox(height: 12),
        _buildSubResourceSection(
            context, p, detail, SubResourceType.inclusion),
        _buildSubResourceSection(
            context, p, detail, SubResourceType.exclusion),
        _buildSubResourceSection(
            context, p, detail, SubResourceType.assumption),
        _buildSubResourceSection(
            context, p, detail, SubResourceType.paymentMilestone),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildHeaderCard(BuildContext context, LeadEstimationDetail detail) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(detail.estimationNo,
                style: theme.textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(detail.projectType.name,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: Colors.grey[600])),
            const SizedBox(height: 8),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _amountRow('Subtotal', detail.subtotal),
                _amountRow('Discount', detail.discountAmount),
                _amountRow('GST', detail.gstAmount),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text('Grand Total: ',
                    style: theme.textTheme.titleMedium),
                Text(
                  '\u20b9${detail.grandTotal.toStringAsFixed(2)}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            _buildTransitionButtons(context, detail),
          ],
        ),
      ),
    );
  }

  Widget _buildTransitionButtons(
      BuildContext context, LeadEstimationDetail detail) {
    final p = context.read<EstimationDetailProvider>();

    Future<void> doTransition({
      required String confirmMessage,
      required Future<bool> Function() action,
      required String successMessage,
    }) async {
      final messenger = ScaffoldMessenger.of(context);
      final confirm = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          content: Text(confirmMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Confirm'),
            ),
          ],
        ),
      );
      if (confirm != true) return;
      final ok = await action();
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(ok ? successMessage : (p.errorMessage ?? 'Operation failed.')),
          backgroundColor: ok ? Colors.green : Colors.red,
        ),
      );
    }

    final buttons = <Widget>[];

    switch (detail.status) {
      case LeadEstimationStatus.DRAFT:
        buttons.add(FilledButton(
          onPressed: () => doTransition(
            confirmMessage: 'Mark this estimation as Sent?',
            action: p.markSent,
            successMessage: 'Estimation marked as Sent.',
          ),
          child: const Text('Mark as Sent'),
        ));
        break;
      case LeadEstimationStatus.SENT:
        buttons.addAll([
          FilledButton(
            onPressed: () => doTransition(
              confirmMessage:
                  'Mark this estimation as Accepted? This will also update the lead status to Project Won.',
              action: p.markAccepted,
              successMessage: 'Estimation accepted. Lead marked as Project Won.',
            ),
            style: FilledButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Mark Accepted'),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: () => doTransition(
              confirmMessage: 'Mark this estimation as Rejected?',
              action: p.markRejected,
              successMessage: 'Estimation marked as Rejected.',
            ),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Mark Rejected'),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: () => doTransition(
              confirmMessage: 'Revert this estimation back to Draft?',
              action: p.revertToDraft,
              successMessage: 'Estimation reverted to Draft.',
            ),
            child: const Text('Revert to Draft'),
          ),
        ]);
        break;
      case LeadEstimationStatus.ACCEPTED:
        // Final state — no transitions allowed.
        break;
      case LeadEstimationStatus.REJECTED:
        buttons.add(OutlinedButton(
          onPressed: () => doTransition(
            confirmMessage: 'Revert this estimation back to Draft?',
            action: p.revertToDraft,
            successMessage: 'Estimation reverted to Draft.',
          ),
          child: const Text('Revert to Draft'),
        ));
        break;
    }

    if (buttons.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: buttons,
      ),
    );
  }

  Widget _amountRow(String label, double amount) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 11, color: Colors.grey)),
        Text('\u20b9${amount.toStringAsFixed(0)}',
            style: const TextStyle(fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildSubResourceSection(
    BuildContext context,
    EstimationDetailProvider p,
    LeadEstimationDetail detail,
    SubResourceType type,
  ) {
    final items = p.itemsFor(type);
    final isLoading = p.typeIsLoading(type);
    final error = p.typeError(type);
    final isMilestone = type == SubResourceType.paymentMilestone;

    double milestoneSum = 0;
    if (isMilestone) {
      for (final item in items) {
        milestoneSum += item.percentage ?? 0;
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        initiallyExpanded: true,
        title: Row(
          children: [
            Text(
              type.toDisplayLabel(),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: 8),
            Chip(
              label: Text('${items.length}'),
              padding: EdgeInsets.zero,
              labelPadding: const EdgeInsets.symmetric(horizontal: 6),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isLoading)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: 'Add',
              onPressed: () => _openEditDialog(
                  context, p, detail.id, type, null),
            ),
          ],
        ),
        children: [
          if (error != null)
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(error,
                  style: const TextStyle(color: Colors.red)),
            ),
          if (items.isEmpty && !isLoading)
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text('None added yet.',
                  style: TextStyle(color: Colors.grey)),
            ),
          ...items.map((item) => ListTile(
                title: Text(isMilestone && item.percentage != null
                    ? '${item.label} (${item.percentage!.toStringAsFixed(1)}%)'
                    : item.label),
                subtitle: item.description != null
                    ? Text(item.description!)
                    : null,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      tooltip: 'Edit',
                      onPressed: () => _openEditDialog(
                          context, p, detail.id, type, item),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 18),
                      tooltip: 'Delete',
                      onPressed: () =>
                          _confirmDelete(context, p, detail.id, type, item),
                    ),
                  ],
                ),
              )),
          if (isMilestone && items.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: Text(
                'Sum: ${milestoneSum.toStringAsFixed(1)}% (must be 99–101%)',
                style: TextStyle(
                  color: milestoneSum >= 99 && milestoneSum <= 101
                      ? Colors.green[700]
                      : Colors.red,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _openEditDialog(
    BuildContext context,
    EstimationDetailProvider p,
    String estimationId,
    SubResourceType type,
    EstimationSubResource? existing,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _SubResourceEditDialog(type: type, existing: existing),
    );
    if (result == null) return;

    bool ok;
    if (existing == null) {
      switch (type) {
        case SubResourceType.inclusion:
          ok = await p.addInclusion(estimationId, result);
          break;
        case SubResourceType.exclusion:
          ok = await p.addExclusion(estimationId, result);
          break;
        case SubResourceType.assumption:
          ok = await p.addAssumption(estimationId, result);
          break;
        case SubResourceType.paymentMilestone:
          ok = await p.addPaymentMilestone(estimationId, result);
          break;
      }
    } else {
      switch (type) {
        case SubResourceType.inclusion:
          ok = await p.updateInclusion(estimationId, existing.id, result);
          break;
        case SubResourceType.exclusion:
          ok = await p.updateExclusion(estimationId, existing.id, result);
          break;
        case SubResourceType.assumption:
          ok = await p.updateAssumption(estimationId, existing.id, result);
          break;
        case SubResourceType.paymentMilestone:
          ok = await p.updatePaymentMilestone(
              estimationId, existing.id, result);
          break;
      }
    }

    if (!ok && mounted) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(p.typeError(type) ?? 'Operation failed.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    EstimationDetailProvider p,
    String estimationId,
    SubResourceType type,
    EstimationSubResource item,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Delete ${type.toDisplayLabel().replaceAll('s', '')}?'),
        content: Text('Remove "${item.label}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
                backgroundColor: Colors.red.shade100),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    bool ok;
    switch (type) {
      case SubResourceType.inclusion:
        ok = await p.deleteInclusion(estimationId, item.id);
        break;
      case SubResourceType.exclusion:
        ok = await p.deleteExclusion(estimationId, item.id);
        break;
      case SubResourceType.assumption:
        ok = await p.deleteAssumption(estimationId, item.id);
        break;
      case SubResourceType.paymentMilestone:
        ok = await p.deletePaymentMilestone(estimationId, item.id);
        break;
    }

    if (!ok) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(p.typeError(type) ?? 'Delete failed.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Edit dialog
// ─────────────────────────────────────────────────────────────────────────────

class _SubResourceEditDialog extends StatefulWidget {
  final SubResourceType type;
  final EstimationSubResource? existing;

  const _SubResourceEditDialog({required this.type, this.existing});

  @override
  State<_SubResourceEditDialog> createState() => _SubResourceEditDialogState();
}

class _SubResourceEditDialogState extends State<_SubResourceEditDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _labelCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _orderCtrl;
  late final TextEditingController _pctCtrl;

  bool get _isMilestone =>
      widget.type == SubResourceType.paymentMilestone;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _labelCtrl = TextEditingController(text: e?.label ?? '');
    _descCtrl = TextEditingController(text: e?.description ?? '');
    _orderCtrl =
        TextEditingController(text: e?.displayOrder.toString() ?? '0');
    _pctCtrl = TextEditingController(
        text: e?.percentage?.toStringAsFixed(1) ?? '');
  }

  @override
  void dispose() {
    _labelCtrl.dispose();
    _descCtrl.dispose();
    _orderCtrl.dispose();
    _pctCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final payload = EstimationSubResource.createPayload(
      label: _labelCtrl.text.trim(),
      description: _descCtrl.text.trim().isEmpty
          ? null
          : _descCtrl.text.trim(),
      displayOrder: int.tryParse(_orderCtrl.text.trim()),
      percentage: _isMilestone
          ? double.tryParse(_pctCtrl.text.trim())
          : null,
    );
    Navigator.of(context).pop(payload);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return AlertDialog(
      title: Text(
        '${isEdit ? 'Edit' : 'Add'} ${widget.type.toDisplayLabel().replaceAll(RegExp(r's$'), '')}',
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _labelCtrl,
                decoration: const InputDecoration(
                  labelText: 'Label *',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descCtrl,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _orderCtrl,
                decoration: const InputDecoration(
                  labelText: 'Display Order',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v != null && v.isNotEmpty && int.tryParse(v) == null) {
                    return 'Must be a whole number';
                  }
                  return null;
                },
              ),
              if (_isMilestone) ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: _pctCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Percentage *',
                    border: OutlineInputBorder(),
                    suffixText: '%',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                      decimal: true),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Required';
                    final n = double.tryParse(v.trim());
                    if (n == null) return 'Must be a number';
                    if (n <= 0 || n > 100) return 'Must be between 0 and 100';
                    return null;
                  },
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _save,
          child: Text(isEdit ? 'Save' : 'Add'),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Status chip
// ─────────────────────────────────────────────────────────────────────────────

class _StatusChip extends StatelessWidget {
  final LeadEstimationStatus status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      LeadEstimationStatus.DRAFT => ('DRAFT', Colors.grey),
      LeadEstimationStatus.SENT => ('SENT', Colors.blue),
      LeadEstimationStatus.ACCEPTED => ('ACCEPTED', Colors.green),
      LeadEstimationStatus.REJECTED => ('REJECTED', Colors.red),
    };
    return Chip(
      label: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 11),
      ),
      backgroundColor: color,
      padding: EdgeInsets.zero,
      labelPadding: const EdgeInsets.symmetric(horizontal: 8),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}
