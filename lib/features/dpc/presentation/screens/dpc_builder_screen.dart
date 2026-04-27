import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import 'package:admin/constants.dart';
import 'package:admin/features/boq/presentation/screens/boq_screen.dart';
import 'package:admin/features/dpc_customization_catalog/data/models/dpc_customization_catalog_item.dart';
import 'package:admin/features/dpc_customization_catalog/presentation/screens/dpc_customization_catalog_picker_dialog.dart';
import 'package:admin/features/dpc_customization_catalog/presentation/screens/promote_dpc_customization_to_catalog_dialog.dart';
import 'package:admin/models/dpc/dpc_customization_line.dart';
import 'package:admin/models/dpc/dpc_document.dart';
import 'package:admin/models/dpc/dpc_document_scope.dart';
import 'package:admin/providers/permission_provider.dart';
import 'package:admin/services/dpc_service.dart';
import 'package:admin/utils/error_handler.dart';

/// Detailed Project Costing (DPC) Builder.
///
/// Single-page editor with split-screen layout (form on the left, live PDF
/// preview on the right) at widths >= 1200, and stacked vertically below that.
class DpcBuilderScreen extends StatefulWidget {
  final int projectId;
  const DpcBuilderScreen({super.key, required this.projectId});

  @override
  State<DpcBuilderScreen> createState() => _DpcBuilderScreenState();
}

class _DpcBuilderScreenState extends State<DpcBuilderScreen> {
  final DpcService _service = DpcService();
  final NumberFormat _inr =
      NumberFormat.currency(locale: 'en_IN', symbol: '\u20B9', decimalDigits: 0);

  DpcDocument? _doc;
  bool _loading = true;
  bool _saving = false;
  String? _error;
  // True when the backend rejected the load because the project has no
  // APPROVED BoQ. Renders a friendly empty-state instead of the generic
  // error banner.
  bool _boqNotApproved = false;

  // PDF preview state
  Uint8List? _previewBytes;
  bool _loadingPreview = false;
  Timer? _previewDebounce;
  Timer? _scopeSaveDebounce;

  // Header field controllers
  final TextEditingController _titleCtrl = TextEditingController();
  final TextEditingController _subtitleCtrl = TextEditingController();

  // Contact field controllers
  final TextEditingController _clientSignCtrl = TextEditingController();
  final TextEditingController _walldotSignCtrl = TextEditingController();
  final TextEditingController _branchManagerNameCtrl = TextEditingController();
  final TextEditingController _branchManagerPhoneCtrl = TextEditingController();
  final TextEditingController _crmTeamNameCtrl = TextEditingController();
  final TextEditingController _crmTeamPhoneCtrl = TextEditingController();
  final TextEditingController _projectEngineerCtrl = TextEditingController();

  // Per-scope working state (rationale TextController, brands editor map, etc.)
  final Map<int, TextEditingController> _rationaleCtrls = {};
  final Map<int, Map<String, TextEditingController>> _brandCtrls = {};
  final Map<int, List<TextEditingController>> _whatYouGetCtrls = {};

  // Per-customization-line controllers (keyed by line id; new lines use
  // negative pending ids until persisted).
  final Map<int, TextEditingController> _custTitleCtrls = {};
  final Map<int, TextEditingController> _custDescCtrls = {};
  final Map<int, TextEditingController> _custAmountCtrls = {};

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    _previewDebounce?.cancel();
    _scopeSaveDebounce?.cancel();
    _titleCtrl.dispose();
    _subtitleCtrl.dispose();
    _clientSignCtrl.dispose();
    _walldotSignCtrl.dispose();
    _branchManagerNameCtrl.dispose();
    _branchManagerPhoneCtrl.dispose();
    _crmTeamNameCtrl.dispose();
    _crmTeamPhoneCtrl.dispose();
    _projectEngineerCtrl.dispose();
    for (final c in _rationaleCtrls.values) {
      c.dispose();
    }
    for (final m in _brandCtrls.values) {
      for (final c in m.values) {
        c.dispose();
      }
    }
    for (final list in _whatYouGetCtrls.values) {
      for (final c in list) {
        c.dispose();
      }
    }
    for (final c in _custTitleCtrls.values) {
      c.dispose();
    }
    for (final c in _custDescCtrls.values) {
      c.dispose();
    }
    for (final c in _custAmountCtrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  // ─── Bootstrap ─────────────────────────────────────────────────────────────

  Future<void> _bootstrap() async {
    setState(() {
      _loading = true;
      _error = null;
      _boqNotApproved = false;
    });
    try {
      DpcDocument? doc = await _service.getLatest(widget.projectId);
      doc ??= await _service.create(widget.projectId);
      _hydrate(doc);
      _loadPreview();
    } catch (e) {
      final msg = ErrorHandler.getErrorMessage(e);
      // Backend signals a missing customer-approved BoQ via HTTP 422 with
      // a message containing "no APPROVED BoQ" / "Project has no APPROVED BoQ".
      // Render a friendly empty-state with an "Open BoQ" CTA instead of the
      // generic error banner.
      final isBoqMissing = msg.toLowerCase().contains('no approved boq') ||
          msg.toLowerCase().contains('approved boq');
      setState(() {
        _error = msg;
        _boqNotApproved = isBoqMissing;
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _hydrate(DpcDocument doc) {
    _doc = doc;
    _titleCtrl.text = doc.titleOverride ?? '';
    _subtitleCtrl.text = doc.subtitleOverride ?? '';
    _clientSignCtrl.text = doc.clientSignatoryName ?? '';
    _walldotSignCtrl.text = doc.walldotSignatoryName ?? '';
    _branchManagerNameCtrl.text = doc.branchManagerName ?? '';
    _branchManagerPhoneCtrl.text = doc.branchManagerPhone ?? '';
    _crmTeamNameCtrl.text = doc.crmTeamName ?? '';
    _crmTeamPhoneCtrl.text = doc.crmTeamPhone ?? '';
    _projectEngineerCtrl.text = doc.projectEngineerUserId?.toString() ?? '';

    // Rebuild scope-level controllers
    for (final c in _rationaleCtrls.values) {
      c.dispose();
    }
    _rationaleCtrls.clear();
    for (final m in _brandCtrls.values) {
      for (final c in m.values) {
        c.dispose();
      }
    }
    _brandCtrls.clear();
    for (final l in _whatYouGetCtrls.values) {
      for (final c in l) {
        c.dispose();
      }
    }
    _whatYouGetCtrls.clear();

    for (final scope in doc.scopes) {
      _rationaleCtrls[scope.id] =
          TextEditingController(text: scope.selectedOptionRationale ?? '');
      _brandCtrls[scope.id] = {
        for (final entry in scope.brandsResolved.entries)
          entry.key: TextEditingController(text: entry.value),
      };
      _whatYouGetCtrls[scope.id] = scope.whatYouGetResolved
          .map((s) => TextEditingController(text: s))
          .toList();
    }

    // Customization lines
    for (final c in _custTitleCtrls.values) {
      c.dispose();
    }
    for (final c in _custDescCtrls.values) {
      c.dispose();
    }
    for (final c in _custAmountCtrls.values) {
      c.dispose();
    }
    _custTitleCtrls.clear();
    _custDescCtrls.clear();
    _custAmountCtrls.clear();
    for (final line in doc.customizationLines) {
      final key = line.id ?? 0;
      if (key == 0) continue;
      _custTitleCtrls[key] = TextEditingController(text: line.title);
      _custDescCtrls[key] = TextEditingController(text: line.description);
      _custAmountCtrls[key] =
          TextEditingController(text: line.amount.toStringAsFixed(0));
    }
  }

  void _scheduleScopeSave(int scopeId, Map<String, dynamic> patch) {
    _scopeSaveDebounce?.cancel();
    _scopeSaveDebounce = Timer(const Duration(milliseconds: 500), () {
      _saveScope(scopeId, patch);
    });
  }

  void _schedulePreviewRefresh() {
    _previewDebounce?.cancel();
    _previewDebounce = Timer(const Duration(seconds: 1), _loadPreview);
  }

  Future<void> _loadPreview() async {
    final doc = _doc;
    if (doc == null) return;
    setState(() => _loadingPreview = true);
    try {
      final bytes = await _service.previewPdf(doc.id);
      if (!mounted) return;
      setState(() {
        _previewBytes = bytes;
        _loadingPreview = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingPreview = false);
      // Don't surface preview failures as snackbars on every keystroke;
      // the placeholder will still show the last successful render.
    }
  }

  // ─── Saves ─────────────────────────────────────────────────────────────────

  Future<void> _saveHeader() async {
    final doc = _doc;
    if (doc == null) return;
    setState(() => _saving = true);
    try {
      final patch = <String, dynamic>{
        'titleOverride': _titleCtrl.text,
        'subtitleOverride': _subtitleCtrl.text,
        'clientSignatoryName': _clientSignCtrl.text,
        'walldotSignatoryName': _walldotSignCtrl.text,
        'branchManagerName': _branchManagerNameCtrl.text,
        'branchManagerPhone': _branchManagerPhoneCtrl.text,
        'crmTeamName': _crmTeamNameCtrl.text,
        'crmTeamPhone': _crmTeamPhoneCtrl.text,
        if (_projectEngineerCtrl.text.isNotEmpty)
          'projectEngineerUserId':
              int.tryParse(_projectEngineerCtrl.text.trim()),
      };
      final updated = await _service.updateHeader(doc.id, patch);
      if (!mounted) return;
      setState(() => _doc = updated);
      _schedulePreviewRefresh();
      ErrorHandler.showSuccessSnackBar(context, 'Saved');
    } catch (e) {
      if (mounted) ErrorHandler.showErrorSnackBar(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _saveScope(int scopeId, Map<String, dynamic> patch) async {
    final doc = _doc;
    if (doc == null) return;
    try {
      final updated = await _service.updateScope(doc.id, scopeId, patch);
      if (!mounted) return;
      setState(() => _doc = updated);
      _schedulePreviewRefresh();
    } catch (e) {
      if (mounted) ErrorHandler.showErrorSnackBar(context, e);
    }
  }

  Future<void> _addCustomizationLine() async {
    final doc = _doc;
    if (doc == null) return;
    final nextOrder = doc.customizationLines.length + 1;
    try {
      await _service.addCustomization(
        doc.id,
        title: 'New customization',
        description: '',
        amount: 0,
        displayOrder: nextOrder,
      );
      // Re-fetch the full document so we have stable IDs and recomputed totals.
      final refreshed = await _service.getById(doc.id);
      if (!mounted) return;
      setState(() => _hydrate(refreshed));
      _schedulePreviewRefresh();
    } catch (e) {
      if (mounted) ErrorHandler.showErrorSnackBar(context, e);
    }
  }

  Future<void> _deleteCustomization(DpcCustomizationLine line) async {
    final doc = _doc;
    if (doc == null || line.id == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete line'),
        content: Text('Remove "${line.title}" from customizations?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: errorColor, foregroundColor: Colors.white),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await _service.deleteCustomization(doc.id, line.id!);
      final refreshed = await _service.getById(doc.id);
      if (!mounted) return;
      setState(() => _hydrate(refreshed));
      _schedulePreviewRefresh();
    } catch (e) {
      if (mounted) ErrorHandler.showErrorSnackBar(context, e);
    }
  }

  Future<void> _updateCustomization(DpcCustomizationLine line) async {
    final doc = _doc;
    if (doc == null || line.id == null) return;
    final id = line.id!;
    final title = _custTitleCtrls[id]?.text ?? line.title;
    final description = _custDescCtrls[id]?.text ?? line.description;
    final amount =
        double.tryParse(_custAmountCtrls[id]?.text ?? '') ?? line.amount;
    try {
      await _service.updateCustomization(
        doc.id,
        id,
        title: title,
        description: description,
        amount: line.isManual ? amount : null,
      );
      final refreshed = await _service.getById(doc.id);
      if (!mounted) return;
      setState(() => _doc = refreshed);
      _schedulePreviewRefresh();
    } catch (e) {
      if (mounted) ErrorHandler.showErrorSnackBar(context, e);
    }
  }

  Future<void> _issue() async {
    final doc = _doc;
    if (doc == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Issue DPC?'),
        content: const Text(
          'Issuing locks this revision and saves the final PDF to project '
          'documents. You can still create a new revision afterwards.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: successColor, foregroundColor: Colors.white),
            child: const Text('Issue'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    setState(() => _saving = true);
    try {
      final issued = await _service.issue(doc.id);
      if (!mounted) return;
      setState(() => _hydrate(issued));
      _loadPreview();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('DPC issued — saved to project documents'),
          backgroundColor: successColor,
        ),
      );
    } catch (e) {
      if (mounted) ErrorHandler.showErrorSnackBar(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _newRevision() async {
    final doc = _doc;
    if (doc == null) return;
    setState(() => _saving = true);
    try {
      final fresh = await _service.createNewRevision(doc.id);
      if (!mounted) return;
      setState(() => _hydrate(fresh));
      _loadPreview();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('New revision r${fresh.revisionNumber} created'),
          backgroundColor: infoColor,
        ),
      );
    } catch (e) {
      if (mounted) ErrorHandler.showErrorSnackBar(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _openFullscreenPreview() {
    if (_previewBytes == null) return;
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        insetPadding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  const Text('PDF Preview',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PdfPreview(
                build: (_) async => _previewBytes!,
                allowPrinting: true,
                allowSharing: true,
                canChangePageFormat: false,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_boqNotApproved) {
      return _buildBoqNotApprovedScreen();
    }
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detailed Project Costing')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: errorColor),
              const SizedBox(height: 8),
              Text(_error!),
              const SizedBox(height: 16),
              ElevatedButton(
                  onPressed: _bootstrap, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }
    final doc = _doc!;
    final perms = context.watch<PermissionProvider>();
    // If user lacks DPC_VIEW, show a read-only "no access" screen.
    if (!perms.canViewDpc) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detailed Project Costing')),
        body: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock_outline, size: 48, color: textMuted),
              SizedBox(height: 8),
              Text('You do not have permission to view DPC.',
                  style: TextStyle(color: textSecondary)),
            ],
          ),
        ),
      );
    }
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Detailed Project Costing'),
            const SizedBox(width: 12),
            _revisionPill(doc),
            const SizedBox(width: 8),
            _statusPill(doc),
          ],
        ),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.history),
            label: const Text('Revisions'),
            onPressed: () =>
                context.go('/dpc/revisions/${widget.projectId}'),
          ),
          const SizedBox(width: 8),
          TextButton.icon(
            icon: const Icon(Icons.visibility_outlined),
            label: const Text('Preview'),
            onPressed:
                _previewBytes == null ? null : _openFullscreenPreview,
          ),
          const SizedBox(width: 8),
          if (perms.canEditDpc)
            ElevatedButton.icon(
              icon: const Icon(Icons.save_outlined, size: 18),
              label: Text(_saving ? 'Saving...' : 'Save Draft'),
              onPressed: doc.isIssued || _saving ? null : _saveHeader,
            ),
          const SizedBox(width: 8),
          if (perms.canIssueDpc)
            ElevatedButton.icon(
              icon: const Icon(Icons.check_circle_outline, size: 18),
              label: const Text('Issue'),
              onPressed: doc.isIssued || _saving ? null : _issue,
              style: ElevatedButton.styleFrom(
                  backgroundColor: successColor, foregroundColor: Colors.white),
            ),
          const SizedBox(width: defaultPadding),
        ],
      ),
      body: LayoutBuilder(
        builder: (ctx, constraints) {
          final wide = constraints.maxWidth >= 1200;
          if (wide) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(flex: 5, child: _formColumn()),
                const VerticalDivider(width: 1, color: containerBorder),
                Expanded(flex: 6, child: _previewPane()),
              ],
            );
          }
          return SingleChildScrollView(
            child: Column(
              children: [
                _formColumn(),
                SizedBox(height: 600, child: _previewPane()),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Friendly empty-state shown when the backend reports the project has no
  /// customer-APPROVED BoQ — DPC creation is gated on that.
  Widget _buildBoqNotApprovedScreen() {
    return Scaffold(
      appBar: AppBar(title: const Text('Detailed Project Costing')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.warning_amber_outlined,
                  size: 56,
                  color: Colors.amber,
                ),
                const SizedBox(height: 12),
                const Text(
                  'BoQ approval required',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "This project's Bill of Quantities must be customer-approved "
                  'before a Detailed Project Costing can be generated. Open '
                  'the BoQ to approve it first.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: textSecondary),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    OutlinedButton.icon(
                      icon: const Icon(Icons.arrow_back, size: 16),
                      label: const Text('Back'),
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.receipt_long_outlined, size: 16),
                      label: const Text('Open BoQ'),
                      onPressed: () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (_) =>
                                BoqScreen(projectId: widget.projectId),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _formColumn() {
    final doc = _doc!;
    final canEdit = context.read<PermissionProvider>().canEditDpc;
    final readOnly = doc.isIssued || !canEdit;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(defaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (readOnly) _issuedBanner(doc),
          if (readOnly) const SizedBox(height: defaultPadding),
          _summaryCard(doc),
          const SizedBox(height: defaultPadding),
          _headerTile(readOnly),
          const SizedBox(height: 8),
          ..._buildScopeTiles(doc, readOnly),
          const SizedBox(height: 8),
          _customizationsTile(doc, readOnly),
          const SizedBox(height: 8),
          _contactsTile(readOnly),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _issuedBanner(DpcDocument doc) {
    final issuedAt = doc.issuedAt;
    final dateText = issuedAt != null
        ? DateFormat('d MMM yyyy, h:mm a').format(issuedAt)
        : '—';
    final canCreate = context.read<PermissionProvider>().canCreateDpc;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: boxSuccess,
        border: Border.all(color: boxBorderSuccess),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.lock_outline, color: successColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Issued on $dateText. Edit by creating a new revision.',
              style: const TextStyle(color: textPrimary),
            ),
          ),
          if (canCreate)
            ElevatedButton.icon(
              icon: const Icon(Icons.add_circle_outline, size: 16),
              label: const Text('New Revision'),
              onPressed: _saving ? null : _newRevision,
            ),
        ],
      ),
    );
  }

  Widget _summaryCard(DpcDocument doc) {
    final s = doc.masterCostSummary;
    return Container(
      padding: const EdgeInsets.all(defaultPadding),
      decoration: BoxDecoration(
        color: cardBackground,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: containerBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(doc.projectName ?? 'Project',
              style: Theme.of(context).textTheme.titleMedium),
          if (doc.projectLocation != null && doc.projectLocation!.isNotEmpty)
            Text(doc.projectLocation!,
                style: const TextStyle(color: textSecondary, fontSize: 12)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _summaryStat(
                    'Original', _inr.format(s.totalOriginal), textSecondary),
              ),
              Expanded(
                child: _summaryStat('Customized',
                    _inr.format(s.totalCustomized), primaryColor),
              ),
              Expanded(
                child: _summaryStat(
                  'Variance',
                  _inr.format(s.totalVariance),
                  s.totalVariance >= 0 ? successColor : errorColor,
                ),
              ),
              Expanded(
                child: _summaryStat(
                  'Per sqft',
                  _inr.format(s.customizedPerSqft),
                  infoColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryStat(String label, String value, Color valueColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 11, color: textSecondary)),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color: valueColor,
                fontSize: 16)),
      ],
    );
  }

  Widget _headerTile(bool readOnly) {
    return Container(
      decoration: BoxDecoration(
        color: cardBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: containerBorder),
      ),
      child: ExpansionTile(
        title: const Text('HEADER',
            style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.4)),
        subtitle: const Text('Title and subtitle overrides'),
        childrenPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          TextField(
            controller: _titleCtrl,
            readOnly: readOnly,
            decoration: const InputDecoration(
              labelText: 'Title override',
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => _schedulePreviewRefresh(),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _subtitleCtrl,
            readOnly: readOnly,
            decoration: const InputDecoration(
              labelText: 'Subtitle override',
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => _schedulePreviewRefresh(),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              icon: const Icon(Icons.save_outlined, size: 16),
              label: const Text('Save header'),
              onPressed: readOnly ? null : _saveHeader,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildScopeTiles(DpcDocument doc, bool readOnly) {
    final scopes = [...doc.scopes]
      ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
    return scopes.map((s) => _scopeTile(s, readOnly)).toList();
  }

  Widget _scopeTile(DpcDocumentScope scope, bool readOnly) {
    final brandsCtrls = _brandCtrls[scope.id] ?? <String, TextEditingController>{};
    final whatYouGetCtrls =
        _whatYouGetCtrls[scope.id] ?? <TextEditingController>[];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Container(
        decoration: BoxDecoration(
          color: cardBackground,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: containerBorder),
        ),
        child: ExpansionTile(
          title: Row(
            children: [
              Expanded(
                child: Text(scope.scopeTitle,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
              ),
              const SizedBox(width: 8),
              Text(
                _inr.format(scope.customizedAmount),
                style: const TextStyle(
                    color: primaryColor, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          subtitle: scope.selectedOptionDisplayName != null
              ? Text(scope.selectedOptionDisplayName!,
                  style: const TextStyle(fontSize: 11, color: textSecondary))
              : null,
          childrenPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          children: [
            // Cost band
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: boxSecondary,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: boxBorderSecondary),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _costPill(
                        'Original', _inr.format(scope.originalAmount)),
                  ),
                  Expanded(
                    child: _costPill(
                        'Customized', _inr.format(scope.customizedAmount),
                        emphasised: true),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Available options as radio group
            if (scope.availableOptions.isNotEmpty) ...[
              const Text('Selected option',
                  style: TextStyle(
                      fontWeight: FontWeight.w600, color: textSecondary)),
              const SizedBox(height: 4),
              ...scope.availableOptions.map((opt) => RadioListTile<int>(
                    value: opt.id,
                    groupValue: scope.selectedOptionId,
                    dense: true,
                    title: Text(opt.displayName),
                    subtitle: Text(opt.code,
                        style: const TextStyle(
                            fontSize: 11, color: textSecondary)),
                    onChanged: readOnly
                        ? null
                        : (val) {
                            if (val != null) {
                              _saveScope(scope.id, {'selectedOptionId': val});
                            }
                          },
                  )),
              const SizedBox(height: 12),
            ],

            // Rationale
            TextField(
              controller: _rationaleCtrls[scope.id],
              readOnly: readOnly,
              minLines: 1,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Selected option rationale',
                border: OutlineInputBorder(),
              ),
              onChanged: (val) {
                _scheduleScopeSave(
                    scope.id, {'selectedOptionRationale': val});
                _schedulePreviewRefresh();
              },
            ),
            const SizedBox(height: 12),

            // Brands key/value editor
            const Text('Brands',
                style: TextStyle(
                    fontWeight: FontWeight.w600, color: textSecondary)),
            const SizedBox(height: 4),
            if (brandsCtrls.isEmpty)
              const Text('No brand entries configured',
                  style: TextStyle(color: textMuted, fontSize: 12)),
            ...brandsCtrls.entries.map((entry) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 140,
                        child: Text(entry.key,
                            style: const TextStyle(
                                fontWeight: FontWeight.w500)),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: entry.value,
                          readOnly: readOnly,
                          decoration: const InputDecoration(
                            isDense: true,
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (_) {
                            _scheduleScopeSave(scope.id, {
                              'brandsOverride': {
                                for (final e in brandsCtrls.entries)
                                  e.key: e.value.text,
                              },
                            });
                            _schedulePreviewRefresh();
                          },
                        ),
                      ),
                    ],
                  ),
                )),
            const SizedBox(height: 12),

            // What-you-get bullets
            const Text('What you get',
                style: TextStyle(
                    fontWeight: FontWeight.w600, color: textSecondary)),
            const SizedBox(height: 4),
            ...List.generate(whatYouGetCtrls.length, (i) {
              final ctrl = whatYouGetCtrls[i];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    const Text('•  '),
                    Expanded(
                      child: TextField(
                        controller: ctrl,
                        readOnly: readOnly,
                        decoration: const InputDecoration(
                          isDense: true,
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (_) {
                          _scheduleScopeSave(scope.id, {
                            'whatYouGetOverride':
                                whatYouGetCtrls.map((c) => c.text).toList(),
                          });
                          _schedulePreviewRefresh();
                        },
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 16),
                      onPressed: readOnly
                          ? null
                          : () {
                              setState(() {
                                ctrl.dispose();
                                whatYouGetCtrls.removeAt(i);
                              });
                              _scheduleScopeSave(scope.id, {
                                'whatYouGetOverride': whatYouGetCtrls
                                    .map((c) => c.text)
                                    .toList(),
                              });
                              _schedulePreviewRefresh();
                            },
                    ),
                  ],
                ),
              );
            }),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add bullet'),
                onPressed: readOnly
                    ? null
                    : () {
                        setState(() {
                          whatYouGetCtrls.add(TextEditingController());
                        });
                      },
              ),
            ),
            const SizedBox(height: 12),

            // Included in PDF switch
            SwitchListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: const Text('Include this scope in the PDF'),
              value: scope.includedInPdf,
              onChanged: readOnly
                  ? null
                  : (val) =>
                      _saveScope(scope.id, {'includedInPdf': val}),
            ),
          ],
        ),
      ),
    );
  }

  Widget _costPill(String label, String value, {bool emphasised = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 11, color: textSecondary)),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: emphasised ? primaryColor : textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _customizationsTile(DpcDocument doc, bool readOnly) {
    return Container(
      decoration: BoxDecoration(
        color: cardBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: containerBorder),
      ),
      child: ExpansionTile(
        title: const Text('CUSTOMIZATIONS',
            style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.4)),
        subtitle:
            Text('${doc.customizationLines.length} line(s)'),
        childrenPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          if (doc.customizationLines.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('No customization lines yet.',
                  style: TextStyle(color: textMuted)),
            ),
          ...doc.customizationLines.map((line) => _customizationRow(line, readOnly)),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add manual line'),
                  onPressed: readOnly ? null : _addCustomizationLine,
                ),
                OutlinedButton.icon(
                  icon: const Icon(Icons.inventory_2_outlined, size: 16),
                  label: const Text('Add from catalog'),
                  onPressed: readOnly ? null : _openCatalogPicker,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openCatalogPicker() async {
    final doc = _doc;
    if (doc == null) return;
    await showDialog<void>(
      context: context,
      builder: (_) => DpcCustomizationCatalogPickerDialog(
        dpcDocumentId: doc.id,
        onAdded: (_) {},
      ),
    );
    // Re-fetch the full document so we have stable IDs and recomputed totals.
    // The picker self-dismisses on success and self-handles errors, so we
    // unconditionally refresh on close — same approach as _addCustomizationLine.
    try {
      final refreshed = await _service.getById(doc.id);
      if (!mounted) return;
      setState(() => _hydrate(refreshed));
      _schedulePreviewRefresh();
    } catch (e) {
      if (mounted) ErrorHandler.showErrorSnackBar(context, e);
    }
  }

  Future<void> _promoteCustomization(DpcCustomizationLine line) async {
    final doc = _doc;
    if (doc == null || line.id == null) return;
    final categories = <String>{};
    // Best-effort category list — none locally on the line itself, so we
    // hand an empty list. The dialog also accepts free-text via dropdown
    // semantics (None or known); future enhancement could prefetch.
    final result = await showDialog<DpcCustomizationCatalogItem>(
      context: context,
      builder: (_) => PromoteDpcCustomizationToCatalogDialog(
        lineId: line.id!,
        sourceTitle: _custTitleCtrls[line.id!]?.text.trim().isNotEmpty == true
            ? _custTitleCtrls[line.id!]!.text.trim()
            : line.title,
        sourceAmount: double.tryParse(
                _custAmountCtrls[line.id!]?.text ?? '') ??
            line.amount,
        existingCategories: categories.toList(),
      ),
    );
    if (result == null || !mounted) return;
    ErrorHandler.showSuccessSnackBar(
      context,
      'Promoted to catalog (${result.code})',
    );
    try {
      final refreshed = await _service.getById(doc.id);
      if (!mounted) return;
      setState(() => _hydrate(refreshed));
      _schedulePreviewRefresh();
    } catch (e) {
      if (mounted) ErrorHandler.showErrorSnackBar(context, e);
    }
  }

  Widget _customizationRow(DpcCustomizationLine line, bool readOnly) {
    final id = line.id ?? 0;
    final titleCtrl = _custTitleCtrls[id];
    final descCtrl = _custDescCtrls[id];
    final amtCtrl = _custAmountCtrls[id];
    if (titleCtrl == null || descCtrl == null || amtCtrl == null) {
      return const SizedBox.shrink();
    }
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: boxGray,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: containerBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: titleCtrl,
                  readOnly: readOnly,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (_) => _schedulePreviewRefresh(),
                  onEditingComplete: () => _updateCustomization(line),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 140,
                child: TextField(
                  controller: amtCtrl,
                  readOnly: readOnly || line.isAuto,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Amount',
                    isDense: true,
                    border: const OutlineInputBorder(),
                    suffixIcon: line.isAuto
                        ? Container(
                            margin: const EdgeInsets.all(4),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: boxInfo,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            alignment: Alignment.center,
                            child: const Text('AUTO',
                                style: TextStyle(
                                    fontSize: 9, color: infoColor)),
                          )
                        : null,
                  ),
                  onEditingComplete: () => _updateCustomization(line),
                ),
              ),
              if (line.isManual)
                IconButton(
                  icon: const Icon(Icons.close, color: errorColor),
                  tooltip: 'Delete line',
                  onPressed: readOnly
                      ? null
                      : () => _deleteCustomization(line),
                ),
              if (line.isManual && line.customizationCatalogId == null)
                Builder(builder: (ctx) {
                  final perms = ctx.read<PermissionProvider>();
                  final canPromote = perms.canManageDpcCustomizationCatalog ||
                      perms.canEditDpc;
                  if (!canPromote) return const SizedBox.shrink();
                  return PopupMenuButton<String>(
                    tooltip: 'More actions',
                    icon: const Icon(Icons.more_vert, size: 20),
                    onSelected: (v) {
                      if (v == 'promote') _promoteCustomization(line);
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem<String>(
                        value: 'promote',
                        child: Row(
                          children: [
                            Icon(Icons.upgrade,
                                size: 16, color: primaryColor),
                            SizedBox(width: 8),
                            Text('Promote to catalog'),
                          ],
                        ),
                      ),
                    ],
                  );
                }),
            ],
          ),
          const SizedBox(height: 6),
          TextField(
            controller: descCtrl,
            readOnly: readOnly,
            minLines: 1,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Description',
              isDense: true,
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => _schedulePreviewRefresh(),
            onEditingComplete: () => _updateCustomization(line),
          ),
        ],
      ),
    );
  }

  Widget _contactsTile(bool readOnly) {
    return Container(
      decoration: BoxDecoration(
        color: cardBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: containerBorder),
      ),
      child: ExpansionTile(
        title: const Text('CONTACTS & SIGN-OFF',
            style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.4)),
        childrenPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          _contactField('Client signatory name', _clientSignCtrl, readOnly),
          _contactField('Walldot signatory name', _walldotSignCtrl, readOnly),
          _contactField('Project engineer user ID', _projectEngineerCtrl,
              readOnly,
              numeric: true),
          _contactField(
              'Branch manager name', _branchManagerNameCtrl, readOnly),
          _contactField(
              'Branch manager phone', _branchManagerPhoneCtrl, readOnly),
          _contactField('CRM team name', _crmTeamNameCtrl, readOnly),
          _contactField('CRM team phone', _crmTeamPhoneCtrl, readOnly),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              icon: const Icon(Icons.save_outlined, size: 16),
              label: const Text('Save contacts'),
              onPressed: readOnly ? null : _saveHeader,
            ),
          ),
        ],
      ),
    );
  }

  Widget _contactField(
    String label,
    TextEditingController ctrl,
    bool readOnly, {
    bool numeric = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextField(
        controller: ctrl,
        readOnly: readOnly,
        keyboardType: numeric ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          isDense: true,
        ),
        onChanged: (_) => _schedulePreviewRefresh(),
      ),
    );
  }

  // ─── Preview pane ──────────────────────────────────────────────────────────

  Widget _previewPane() {
    return Container(
      color: boxSecondary,
      child: Column(
        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: cardBackground,
            child: Row(
              children: [
                const Icon(Icons.picture_as_pdf, color: errorColor, size: 18),
                const SizedBox(width: 8),
                const Text('Live preview',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const Spacer(),
                if (_loadingPreview)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.refresh, size: 18),
                  tooltip: 'Refresh preview',
                  onPressed: _loadingPreview ? null : _loadPreview,
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: containerBorder),
          Expanded(
            child: _previewBytes == null
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.description_outlined,
                            size: 48, color: textMuted),
                        const SizedBox(height: 8),
                        Text(
                          _loadingPreview
                              ? 'Rendering preview...'
                              : 'Preview unavailable.',
                          style: const TextStyle(color: textSecondary),
                        ),
                      ],
                    ),
                  )
                : PdfPreview(
                    build: (_) async => _previewBytes!,
                    allowPrinting: true,
                    allowSharing: true,
                    canChangePageFormat: false,
                    canChangeOrientation: false,
                    canDebug: false,
                  ),
          ),
        ],
      ),
    );
  }

  // ─── Pills ─────────────────────────────────────────────────────────────────

  Widget _revisionPill(DpcDocument doc) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: boxInfo,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: boxBorderInfo),
      ),
      child: Text('r${doc.revisionNumber}',
          style: const TextStyle(
              color: infoColor, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }

  Widget _statusPill(DpcDocument doc) {
    final isDraft = doc.isDraft;
    final color = isDraft ? warningColor : successColor;
    final bg = isDraft ? boxWarning : boxSuccess;
    final border = isDraft ? boxBorderWarning : boxBorderSuccess;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Text(doc.status.toUpperCase(),
          style: TextStyle(
              color: color, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}
