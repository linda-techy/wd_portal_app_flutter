import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:admin/models/design_package_template.dart';
import 'package:admin/services/design_package_template_service.dart';
import 'package:admin/theme/app_theme.dart';
import 'package:admin/utils/error_handler.dart';
import 'package:admin/utils/motion_toast.dart';

class DesignPackageTemplatesScreen extends StatefulWidget {
  const DesignPackageTemplatesScreen({super.key});

  @override
  State<DesignPackageTemplatesScreen> createState() =>
      _DesignPackageTemplatesScreenState();
}

class _DesignPackageTemplatesScreenState
    extends State<DesignPackageTemplatesScreen> {
  final _service = DesignPackageTemplateService();
  final _inr =
      NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

  List<DesignPackageTemplate> _templates = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final rows = await _service.list();
      if (mounted) {
        setState(() {
          _templates = rows;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  Future<void> _openEditor({DesignPackageTemplate? existing}) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => _TemplateEditorDialog(existing: existing),
    );
    if (saved == true) _load();
  }

  Future<void> _toggleActive(DesignPackageTemplate t) async {
    try {
      await _service.setActive(t.id!, !t.isActive);
      if (!mounted) return;
      MotionToast.show(context,
          message: t.isActive
              ? 'Template archived — customers will no longer see it'
              : 'Template re-activated',
          isError: false);
      _load();
    } catch (e) {
      if (!mounted) return;
      await ErrorHandler.handleApiError(context, e,
          defaultMessage: 'Failed to update template');
    }
  }

  Future<void> _delete(DesignPackageTemplate t) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete template?'),
        content: Text(
            'Permanently delete "${t.name}"? Customers who selected this package in the past will lose the package name on their payment record.\n\nPrefer the Archive action unless this template was never used.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child:
                  const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _service.delete(t.id!);
      if (!mounted) return;
      MotionToast.show(context,
          message: 'Template deleted', isError: false);
      _load();
    } catch (e) {
      if (!mounted) return;
      await ErrorHandler.handleApiError(context, e,
          defaultMessage: 'Failed to delete template');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Design Package Templates'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loading ? null : _load,
            tooltip: 'Refresh',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(),
        icon: const Icon(Icons.add),
        label: const Text('New Template'),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppTheme.statusError),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(_error!, textAlign: TextAlign.center),
            ),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: _load, child: const Text('Retry')),
          ],
        ),
      );
    }
    if (_templates.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.dashboard_customize_outlined,
                size: 56, color: AppTheme.textSecondary),
            const SizedBox(height: 12),
            const Text('No design package templates yet'),
            const SizedBox(height: 8),
            const Text(
              'Create your first tier — customers see these on the design-phase screen.',
              style: TextStyle(color: AppTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _openEditor(),
              icon: const Icon(Icons.add),
              label: const Text('New Template'),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        itemCount: _templates.length,
        itemBuilder: (_, i) => _buildCard(_templates[i]),
      ),
    );
  }

  Widget _buildCard(DesignPackageTemplate t) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: t.isActive
              ? AppTheme.primaryBlue.withOpacity(0.2)
              : Colors.grey.shade300,
        ),
      ),
      child: InkWell(
        onTap: () => _openEditor(existing: t),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              t.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                t.code,
                                style: const TextStyle(
                                    fontSize: 11,
                                    fontFamily: 'monospace',
                                    color: AppTheme.textSecondary),
                              ),
                            ),
                            if (!t.isActive) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'ARCHIVED',
                                  style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.orange),
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (t.tagline != null && t.tagline!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              t.tagline!,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (v) {
                      switch (v) {
                        case 'edit':
                          _openEditor(existing: t);
                          break;
                        case 'archive':
                          _toggleActive(t);
                          break;
                        case 'delete':
                          _delete(t);
                          break;
                      }
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(value: 'edit', child: Text('Edit')),
                      PopupMenuItem(
                          value: 'archive',
                          child: Text(t.isActive ? 'Archive' : 'Re-activate')),
                      const PopupMenuItem(
                          value: 'delete',
                          child: Text('Delete',
                              style: TextStyle(color: Colors.red))),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 6,
                children: [
                  _chip(Icons.payments_outlined,
                      '${_inr.format(t.ratePerSqft)} / sqft'),
                  if (t.fullPaymentDiscountPct > 0)
                    _chip(Icons.local_offer_outlined,
                        '${t.fullPaymentDiscountPct.toStringAsFixed(0)}% off full pay',
                        color: AppTheme.statusSuccess),
                  _chip(Icons.refresh,
                      '${t.revisionsIncluded} revision${t.revisionsIncluded == 1 ? '' : 's'}'),
                  _chip(Icons.format_list_numbered,
                      'Order ${t.displayOrder}'),
                ],
              ),
              if (t.featureList.isNotEmpty) ...[
                const Divider(height: 24),
                ...t.featureList.map((f) => Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 2, right: 6),
                            child: Icon(Icons.check, size: 14,
                                color: AppTheme.statusSuccess),
                          ),
                          Expanded(
                              child: Text(f,
                                  style: const TextStyle(fontSize: 13))),
                        ],
                      ),
                    )),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(IconData icon, String label, {Color? color}) {
    final c = color ?? AppTheme.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: (color ?? Colors.grey.shade400).withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: c),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 12, color: c)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Editor dialog — create or edit a template
// ─────────────────────────────────────────────────────────────────────────────

class _TemplateEditorDialog extends StatefulWidget {
  final DesignPackageTemplate? existing;
  const _TemplateEditorDialog({this.existing});

  @override
  State<_TemplateEditorDialog> createState() => _TemplateEditorDialogState();
}

class _TemplateEditorDialogState extends State<_TemplateEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  final _service = DesignPackageTemplateService();

  late final TextEditingController _codeCtrl;
  late final TextEditingController _nameCtrl;
  late final TextEditingController _taglineCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _rateCtrl;
  late final TextEditingController _fullDiscountCtrl;
  late final TextEditingController _revisionsCtrl;
  late final TextEditingController _featuresCtrl;
  late final TextEditingController _orderCtrl;
  bool _isActive = true;
  bool _saving = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _codeCtrl = TextEditingController(text: e?.code ?? '');
    _nameCtrl = TextEditingController(text: e?.name ?? '');
    _taglineCtrl = TextEditingController(text: e?.tagline ?? '');
    _descCtrl = TextEditingController(text: e?.description ?? '');
    _rateCtrl = TextEditingController(text: e?.ratePerSqft.toString() ?? '');
    _fullDiscountCtrl =
        TextEditingController(text: (e?.fullPaymentDiscountPct ?? 0).toString());
    _revisionsCtrl =
        TextEditingController(text: (e?.revisionsIncluded ?? 2).toString());
    _featuresCtrl = TextEditingController(text: e?.features ?? '');
    _orderCtrl =
        TextEditingController(text: (e?.displayOrder ?? 0).toString());
    _isActive = e?.isActive ?? true;
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    _nameCtrl.dispose();
    _taglineCtrl.dispose();
    _descCtrl.dispose();
    _rateCtrl.dispose();
    _fullDiscountCtrl.dispose();
    _revisionsCtrl.dispose();
    _featuresCtrl.dispose();
    _orderCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final template = DesignPackageTemplate(
        id: widget.existing?.id,
        code: _codeCtrl.text.trim().toUpperCase().replaceAll(' ', '_'),
        name: _nameCtrl.text.trim(),
        tagline: _taglineCtrl.text.trim().isEmpty
            ? null
            : _taglineCtrl.text.trim(),
        description: _descCtrl.text.trim().isEmpty
            ? null
            : _descCtrl.text.trim(),
        ratePerSqft: double.parse(_rateCtrl.text),
        fullPaymentDiscountPct: double.tryParse(_fullDiscountCtrl.text) ?? 0,
        revisionsIncluded: int.tryParse(_revisionsCtrl.text) ?? 2,
        features: _featuresCtrl.text.trim().isEmpty
            ? null
            : _featuresCtrl.text.trim(),
        displayOrder: int.tryParse(_orderCtrl.text) ?? 0,
        isActive: _isActive,
      );

      if (_isEdit) {
        await _service.update(widget.existing!.id!, template);
      } else {
        await _service.create(template);
      }
      if (!mounted) return;
      MotionToast.show(context,
          message: _isEdit ? 'Template updated' : 'Template created',
          isError: false);
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      await ErrorHandler.handleApiError(context, e,
          defaultMessage: 'Failed to save template');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String? _requiredText(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Required' : null;

  String? _requiredNumber(String? v, {bool allowZero = true}) {
    if (v == null || v.trim().isEmpty) return 'Required';
    final n = double.tryParse(v);
    if (n == null) return 'Enter a number';
    if (!allowZero && n <= 0) return 'Must be greater than 0';
    if (n < 0) return 'Cannot be negative';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEdit ? 'Edit Template' : 'New Template'),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _codeCtrl,
                  enabled: !_isEdit, // code is read-only after creation
                  decoration: InputDecoration(
                    labelText: 'Code',
                    helperText: _isEdit
                        ? 'Code is read-only after creation'
                        : 'Machine code, e.g. PREMIUM, BESPOKE',
                  ),
                  validator: _requiredText,
                  textCapitalization: TextCapitalization.characters,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _nameCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Display name'),
                  validator: _requiredText,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _taglineCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Tagline (optional)',
                    helperText: 'Short marketing line shown on the picker',
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descCtrl,
                  maxLines: 3,
                  decoration:
                      const InputDecoration(labelText: 'Description (optional)'),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _rateCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Rate (₹/sqft)',
                          helperText: 'Kerala range: ₹50–250',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        validator: (v) => _requiredNumber(v, allowZero: false),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _fullDiscountCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Full-pay discount %',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        validator: _requiredNumber,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _revisionsCtrl,
                        decoration:
                            const InputDecoration(labelText: 'Revisions included'),
                        keyboardType: TextInputType.number,
                        validator: _requiredNumber,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _orderCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Display order',
                          helperText: 'Lower = shown first',
                        ),
                        keyboardType: TextInputType.number,
                        validator: _requiredNumber,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _featuresCtrl,
                  maxLines: 6,
                  decoration: const InputDecoration(
                    labelText: 'Features',
                    helperText:
                        'One bullet per line, e.g.\n2D floor plans\n3D exterior view\n2 revisions included',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _isActive,
                  onChanged: (v) => setState(() => _isActive = v),
                  title: const Text('Active'),
                  subtitle: Text(_isActive
                      ? 'Customers see this template on the design picker'
                      : 'Archived — hidden from customers, kept for history'),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed:
              _saving ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(_isEdit ? 'Save' : 'Create'),
        ),
      ],
    );
  }
}
