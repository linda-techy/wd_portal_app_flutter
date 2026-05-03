import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:admin/config/app_config.dart';
import 'package:admin/features/lead_estimation/data/models/estimation_sub_resource.dart';
import 'package:admin/features/lead_estimation/data/models/lead_estimation.dart';
import 'package:admin/features/lead_estimation/presentation/screens/lead_estimation_wizard_screen.dart';
import 'package:admin/features/lead_estimation/presentation/widgets/revision_diff_sheet.dart';
import 'package:admin/features/lead_estimation/providers/estimation_detail_provider.dart';
import 'package:admin/providers/permission_provider.dart';
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
                if (detail != null &&
                    (detail.status == LeadEstimationStatus.DRAFT ||
                        detail.status == LeadEstimationStatus.SENT))
                  IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    tooltip: 'Revise (creates new version)',
                    onPressed: () => _openReviseWizard(context, detail),
                  ),
                if (detail != null)
                  IconButton(
                    icon: const Icon(Icons.link),
                    tooltip: 'Copy share link',
                    onPressed: () => _copyShareLink(context, detail),
                  ),
                if (detail != null)
                  PopupMenuButton<_MoreAction>(
                    icon: const Icon(Icons.more_vert),
                    onSelected: (action) {
                      if (action == _MoreAction.regenerateToken) {
                        _confirmRegenerateToken(context, p);
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(
                        value: _MoreAction.regenerateToken,
                        child: Text('Regenerate share link'),
                      ),
                    ],
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
            if (detail.parentEstimationId != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Revision of ${detail.parentEstimationId}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.orange[700],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.compare_arrows, size: 16),
                    label: const Text('Compare with parent'),
                    onPressed: () => RevisionDiffSheet.show(context, detail),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                _ModePill(mode: detail.pricingMode),
                const SizedBox(width: 8),
                if (detail.isCurrent) const _CurrentPill(),
                if (detail.confidenceLevel != null) ...[
                  const SizedBox(width: 8),
                  _ConfidencePill(level: detail.confidenceLevel!),
                ],
                if (detail.pricingMode == EstimationPricingMode.BUDGETARY &&
                    (detail.status == LeadEstimationStatus.DRAFT ||
                        detail.status == LeadEstimationStatus.SENT)) ...[
                  const SizedBox(width: 12),
                  TextButton.icon(
                    icon: const Icon(Icons.upgrade, size: 16),
                    label: const Text('Convert to Detailed'),
                    onPressed: () async {
                      final created = await Navigator.of(context).push<LeadEstimationDetail>(
                        MaterialPageRoute(
                          builder: (_) => LeadEstimationWizardScreen(
                            leadId: detail.leadId,
                            prefillFrom: detail,
                            reviseFromEstimationId: detail.id,
                            forceMode: EstimationPricingMode.LINE_ITEM,
                          ),
                          fullscreenDialog: true,
                        ),
                      );
                      if (created != null && context.mounted) {
                        Navigator.of(context).pushReplacement(MaterialPageRoute(
                          builder: (_) => EstimationDetailScreen(estimationId: created.id),
                        ));
                      }
                    },
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            const Divider(),
            if (detail.pricingMode == EstimationPricingMode.BUDGETARY) ...[
              Text(
                'Budgetary estimate — ${detail.estimatedAreaSqft?.toStringAsFixed(0) ?? '?'} sqft',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: Colors.grey[700]),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text('Estimated range: ',
                      style: theme.textTheme.titleMedium),
                  Text(
                    '\u20b9${(detail.grandTotalMin ?? 0).toStringAsFixed(0)}'
                    ' – \u20b9${(detail.grandTotalMax ?? 0).toStringAsFixed(0)}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ] else ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _amountRow('Subtotal', detail.subtotal ?? 0),
                  _amountRow('Discount', detail.discountAmount ?? 0),
                  _amountRow('GST', detail.gstAmount ?? 0),
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
            ],
            if (detail.discountApprovalStatus != null) ...[
              const SizedBox(height: 12),
              _DiscountApprovalBanner(detail: detail),
            ],
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
        // O — Mark Sent is gated when discount > threshold and not yet approved.
        final blocked = detail.discountApprovalStatus == DiscountApprovalStatus.PENDING ||
            detail.discountApprovalStatus == DiscountApprovalStatus.REJECTED;
        buttons.add(Tooltip(
          message: blocked
              ? 'Discount needs approval before this can be sent.'
              : '',
          child: FilledButton(
            onPressed: blocked
                ? null
                : () => doTransition(
                      confirmMessage: 'Mark this estimation as Sent?',
                      action: p.markSent,
                      successMessage: 'Estimation marked as Sent.',
                    ),
            child: const Text('Mark as Sent'),
          ),
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
      case LeadEstimationStatus.PENDING_APPROVAL:
      case LeadEstimationStatus.APPROVED:
      case LeadEstimationStatus.EXPIRED:
        // EXPIRED is terminal; admin must create a new revision via the wizard.
        // PENDING_APPROVAL/APPROVED are reserved for a future approval workflow.
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

  Future<void> _openReviseWizard(
      BuildContext context, LeadEstimationDetail detail) async {
    final result = await Navigator.of(context).push<LeadEstimationDetail>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => LeadEstimationWizardScreen(
          leadId: detail.leadId,
          prefillFrom: detail,
          reviseFromEstimationId: detail.id,
        ),
      ),
    );
    if (result != null && mounted) {
      _provider.loadEstimation(widget.estimationId);
    }
  }

  Future<void> _copyShareLink(
      BuildContext context, LeadEstimationDetail detail) async {
    final url = AppConfig.buildQuotationShareUrl(detail.publicViewToken);
    await Clipboard.setData(ClipboardData(text: url));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Share link copied to clipboard')),
    );
  }

  Future<void> _confirmRegenerateToken(
      BuildContext context, EstimationDetailProvider p) async {
    final messenger = ScaffoldMessenger.of(context);
    final confirm = await showDialog<bool>(  // ignore: use_build_context_synchronously
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Regenerate share link?'),
        content: const Text(
            'This will create a new share link. Anyone with the old link will '
            'no longer be able to view this estimation.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Regenerate'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    final ok = await p.regenerateToken();
    if (!mounted) return;
    messenger.showSnackBar(SnackBar(
      content: Text(ok
          ? 'New share link generated'
          : (p.errorMessage ?? 'Failed to regenerate link')),
      backgroundColor: ok ? Colors.green : Colors.red,
    ));
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
      LeadEstimationStatus.PENDING_APPROVAL => ('PENDING APPROVAL', Colors.amber),
      LeadEstimationStatus.APPROVED => ('APPROVED', Colors.indigo),
      LeadEstimationStatus.SENT => ('SENT', Colors.blue),
      LeadEstimationStatus.ACCEPTED => ('ACCEPTED', Colors.green),
      LeadEstimationStatus.REJECTED => ('REJECTED', Colors.red),
      LeadEstimationStatus.EXPIRED => ('EXPIRED', Colors.brown),
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

// ─────────────────────────────────────────────────────────────────────────────
// More-actions menu
// ─────────────────────────────────────────────────────────────────────────────

enum _MoreAction { regenerateToken }

class _DiscountApprovalBanner extends StatelessWidget {
  final LeadEstimationDetail detail;
  const _DiscountApprovalBanner({required this.detail});

  @override
  Widget build(BuildContext context) {
    final status = detail.discountApprovalStatus!;
    final pct = ((detail.discountPercent ?? 0) * 100);
    final pctLabel = pct.toStringAsFixed(pct.truncateToDouble() == pct ? 0 : 2);
    final canApprove = context
        .watch<PermissionProvider>()
        .hasPermission('ESTIMATION_DISCOUNT_APPROVE');

    final (color, icon, header, body) = switch (status) {
      DiscountApprovalStatus.PENDING => (
        Colors.amber,
        Icons.hourglass_top,
        'Discount $pctLabel% pending approval',
        'A user with discount-approval permission must approve before this estimation can be sent.',
      ),
      DiscountApprovalStatus.APPROVED => (
        Colors.green,
        Icons.verified,
        'Discount $pctLabel% approved',
        'Approved by user #${detail.discountApprovedByUserId} on '
            '${detail.discountApprovedAt?.toIso8601String().substring(0, 16) ?? "—"}'
            '${(detail.discountApprovalNotes ?? "").isNotEmpty ? "\nNote: ${detail.discountApprovalNotes}" : ""}',
      ),
      DiscountApprovalStatus.REJECTED => (
        Colors.red,
        Icons.block,
        'Discount $pctLabel% rejected',
        '${detail.discountApprovalNotes ?? "No reason given."}\nRevise the estimation with a lower discount before retrying.',
      ),
    };

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        border: Border.all(color: color.withOpacity(0.5)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color.shade800, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(header,
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: color.shade800)),
                    const SizedBox(height: 4),
                    Text(body,
                        style: const TextStyle(fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
          if (status == DiscountApprovalStatus.PENDING && canApprove) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                FilledButton.icon(
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text('Approve'),
                  style: FilledButton.styleFrom(backgroundColor: Colors.green),
                  onPressed: () => _showApproveDialog(context),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  icon: const Icon(Icons.close, size: 18),
                  label: const Text('Reject'),
                  onPressed: () => _showRejectDialog(context),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _showApproveDialog(BuildContext context) async {
    final controller = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Approve discount'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Note (optional)',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              style: FilledButton.styleFrom(backgroundColor: Colors.green),
              child: const Text('Approve')),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    final p = context.read<EstimationDetailProvider>();
    final success = await p.approveDiscount(notes: controller.text.trim());
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(success ? 'Discount approved.' : (p.errorMessage ?? 'Approval failed.'))));
    }
  }

  Future<void> _showRejectDialog(BuildContext context) async {
    final controller = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Reject discount'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Reason (required)',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Reject')),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    final notes = controller.text.trim();
    if (notes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('A reason is required to reject.')));
      return;
    }
    final p = context.read<EstimationDetailProvider>();
    final success = await p.rejectDiscount(notes: notes);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(success ? 'Discount rejected.' : (p.errorMessage ?? 'Rejection failed.'))));
    }
  }
}

class _ConfidencePill extends StatelessWidget {
  final EstimationConfidenceLevel level;
  const _ConfidencePill({required this.level});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (level) {
      EstimationConfidenceLevel.LOW => ('Low \u00b110%', Colors.orange),
      EstimationConfidenceLevel.MEDIUM => ('Medium \u00b15%', Colors.amber),
      EstimationConfidenceLevel.HIGH => ('High \u00b13%', Colors.green),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w600, color: color.shade800)),
    );
  }
}

class _CurrentPill extends StatelessWidget {
  const _CurrentPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.deepPurple.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.deepPurple.withOpacity(0.5)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle, color: Colors.deepPurple, size: 14),
          SizedBox(width: 4),
          Text(
            'Current',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.deepPurple,
            ),
          ),
        ],
      ),
    );
  }
}

class _ModePill extends StatelessWidget {
  final EstimationPricingMode mode;
  const _ModePill({required this.mode});

  @override
  Widget build(BuildContext context) {
    final isBudgetary = mode == EstimationPricingMode.BUDGETARY;
    final color = isBudgetary ? Colors.blueGrey : Colors.teal;
    final label = isBudgetary ? 'Budgetary' : 'Detailed';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
            fontSize: 11, fontWeight: FontWeight.w600, color: color.shade800),
      ),
    );
  }
}

