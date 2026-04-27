import 'package:flutter/material.dart';

import 'package:admin/constants.dart';
import 'package:admin/models/dpc/dpc_scope_option.dart';
import 'package:admin/models/dpc/dpc_scope_template.dart';
import 'package:admin/services/dpc_template_service.dart';
import 'package:admin/utils/error_handler.dart';

/// Edit a single DPC scope template's editable text/list/map content +
/// the per-scope "options considered" cards (Random Rubble / Raft / etc.).
/// Options support add / edit / delete / reorder; image-upload is deferred.
class DpcTemplateEditScreen extends StatefulWidget {
  final int templateId;
  const DpcTemplateEditScreen({super.key, required this.templateId});

  @override
  State<DpcTemplateEditScreen> createState() =>
      _DpcTemplateEditScreenState();
}

class _DpcTemplateEditScreenState extends State<DpcTemplateEditScreen> {
  final DpcTemplateService _service = DpcTemplateService();

  DpcScopeTemplate? _template;
  bool _loading = true;
  bool _saving = false;
  String? _error;

  final TextEditingController _titleCtrl = TextEditingController();
  final TextEditingController _subtitleCtrl = TextEditingController();
  final TextEditingController _introCtrl = TextEditingController();

  // List editors (one TextEditingController per bullet)
  List<TextEditingController> _whatYouGet = [];
  List<TextEditingController> _qualityProcedures = [];
  List<TextEditingController> _documentsYouGet = [];

  // Map editor (key + value controllers per row)
  List<({TextEditingController k, TextEditingController v})> _brandRows = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _subtitleCtrl.dispose();
    _introCtrl.dispose();
    for (final c in _whatYouGet) {
      c.dispose();
    }
    for (final c in _qualityProcedures) {
      c.dispose();
    }
    for (final c in _documentsYouGet) {
      c.dispose();
    }
    for (final r in _brandRows) {
      r.k.dispose();
      r.v.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final t = await _service.getTemplate(widget.templateId);
      if (!mounted) return;
      _hydrate(t);
      setState(() => _loading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = ErrorHandler.getErrorMessage(e);
        _loading = false;
      });
    }
  }

  void _hydrate(DpcScopeTemplate t) {
    _template = t;
    _titleCtrl.text = t.title;
    _subtitleCtrl.text = t.subtitle ?? '';
    _introCtrl.text = t.introParagraph ?? '';

    for (final c in _whatYouGet) {
      c.dispose();
    }
    for (final c in _qualityProcedures) {
      c.dispose();
    }
    for (final c in _documentsYouGet) {
      c.dispose();
    }
    for (final r in _brandRows) {
      r.k.dispose();
      r.v.dispose();
    }

    _whatYouGet =
        t.whatYouGet.map((s) => TextEditingController(text: s)).toList();
    _qualityProcedures = t.qualityProcedures
        .map((s) => TextEditingController(text: s))
        .toList();
    _documentsYouGet = t.documentsYouGet
        .map((s) => TextEditingController(text: s))
        .toList();
    _brandRows = t.defaultBrands.entries
        .map((e) => (
              k: TextEditingController(text: e.key),
              v: TextEditingController(text: e.value),
            ))
        .toList();
  }

  Future<void> _save() async {
    final t = _template;
    if (t == null) return;
    setState(() => _saving = true);
    try {
      final patch = <String, dynamic>{
        'title': _titleCtrl.text,
        'subtitle': _subtitleCtrl.text,
        'introParagraph': _introCtrl.text,
        'whatYouGet': _whatYouGet
            .map((c) => c.text)
            .where((s) => s.isNotEmpty)
            .toList(),
        'qualityProcedures': _qualityProcedures
            .map((c) => c.text)
            .where((s) => s.isNotEmpty)
            .toList(),
        'documentsYouGet': _documentsYouGet
            .map((c) => c.text)
            .where((s) => s.isNotEmpty)
            .toList(),
        'defaultBrands': {
          for (final r in _brandRows)
            if (r.k.text.isNotEmpty) r.k.text: r.v.text,
        },
      };
      final updated = await _service.updateTemplate(t.id, patch);
      if (!mounted) return;
      _hydrate(updated);
      setState(() {});
      ErrorHandler.showSuccessSnackBar(context, 'Template saved');
    } catch (e) {
      if (mounted) ErrorHandler.showErrorSnackBar(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit Template')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: errorColor),
              const SizedBox(height: 8),
              Text(_error!),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _load, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }
    final t = _template!;
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text('Edit · ${t.code}'),
        actions: [
          ElevatedButton.icon(
            icon: const Icon(Icons.save_outlined, size: 16),
            label: Text(_saving ? 'Saving...' : 'Save'),
            onPressed: _saving ? null : _save,
          ),
          const SizedBox(width: defaultPadding),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _section('Identity', [
              _readOnlyField('Code', t.code),
              const SizedBox(height: 12),
              _readOnlyField('Display order', '${t.displayOrder}'),
            ]),
            _section('Header text', [
              TextField(
                controller: _titleCtrl,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _subtitleCtrl,
                decoration: const InputDecoration(
                  labelText: 'Subtitle',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _introCtrl,
                minLines: 3,
                maxLines: 8,
                decoration: const InputDecoration(
                  labelText: 'Intro paragraph',
                  border: OutlineInputBorder(),
                ),
              ),
            ]),
            _section('What you get',
                _bulletEditor(_whatYouGet, () => setState(() {}))),
            _section('Quality procedures',
                _bulletEditor(_qualityProcedures, () => setState(() {}))),
            _section('Documents you get',
                _bulletEditor(_documentsYouGet, () => setState(() {}))),
            _section('Default brands', _brandsEditor()),
            _section('Options', _buildOptionsEditor(t)),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ──────────────────────── Options editor ────────────────────────────

  /// Build the editable list of "options considered" cards for one scope.
  /// Each row supports up/down reorder, edit, soft-delete; an [+ Add Option]
  /// button at the bottom opens the create dialog.
  List<Widget> _buildOptionsEditor(DpcScopeTemplate t) {
    final widgets = <Widget>[];
    if (t.options.isEmpty) {
      widgets.add(const Text('No options yet — click "Add Option" to create one.',
          style: TextStyle(color: textMuted)));
    } else {
      for (var i = 0; i < t.options.length; i++) {
        final o = t.options[i];
        widgets.add(Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: boxGray,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: containerBorder),
          ),
          child: Row(
            children: [
              // Thumbnail (image_path is optional)
              SizedBox(
                width: 56,
                height: 40,
                child: (o.imagePath != null && o.imagePath!.isNotEmpty)
                    ? Image.network(
                        o.imagePath!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          alignment: Alignment.center,
                          color: containerBorder,
                          child: const Icon(Icons.broken_image,
                              size: 18, color: textMuted),
                        ),
                      )
                    : Container(
                        alignment: Alignment.center,
                        color: containerBorder,
                        child: const Icon(Icons.image_outlined,
                            size: 18, color: textMuted),
                      ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: boxInfo,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(o.code,
                    style:
                        const TextStyle(fontSize: 11, color: infoColor)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(o.displayName,
                        style:
                            const TextStyle(fontWeight: FontWeight.w600)),
                    Text('#${o.displayOrder}',
                        style: const TextStyle(
                            color: textMuted, fontSize: 11)),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Move up',
                icon: const Icon(Icons.arrow_upward, size: 18),
                onPressed: i == 0 ? null : () => _moveOption(t, i, i - 1),
              ),
              IconButton(
                tooltip: 'Move down',
                icon: const Icon(Icons.arrow_downward, size: 18),
                onPressed: i == t.options.length - 1
                    ? null
                    : () => _moveOption(t, i, i + 1),
              ),
              IconButton(
                tooltip: 'Edit',
                icon: const Icon(Icons.edit_outlined, size: 18),
                onPressed: () => _openOptionDialog(t, existing: o),
              ),
              IconButton(
                tooltip: 'Delete',
                icon: const Icon(Icons.delete_outline,
                    size: 18, color: errorColor),
                onPressed: () => _deleteOption(o),
              ),
            ],
          ),
        ));
      }
    }
    widgets.add(const SizedBox(height: 8));
    widgets.add(Align(
      alignment: Alignment.centerLeft,
      child: OutlinedButton.icon(
        icon: const Icon(Icons.add, size: 16),
        label: const Text('Add Option'),
        onPressed: () => _openOptionDialog(t),
      ),
    ));
    widgets.add(const SizedBox(height: 4));
    widgets.add(const Text(
      'Tip: paste a URL into "Image path" for the option thumbnail. Image upload is coming soon.',
      style: TextStyle(color: textMuted, fontSize: 11),
    ));
    return widgets;
  }

  Future<void> _openOptionDialog(DpcScopeTemplate t,
      {DpcScopeOption? existing}) async {
    final result = await showDialog<DpcScopeOption?>(
      context: context,
      builder: (_) =>
          _ScopeOptionFormDialog(template: t, existing: existing),
    );
    if (result != null) {
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(existing == null
                ? 'Option added'
                : 'Option updated'),
            backgroundColor: successColor,
          ),
        );
      }
    }
  }

  Future<void> _deleteOption(DpcScopeOption o) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete option?'),
        content: Text(
            'Remove "${o.displayName}" from this scope? Existing DPC documents that picked this option keep it; only future DPC drafts will lose access.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: errorColor, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _service.deleteOption(o.id);
      if (!mounted) return;
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Option deleted'),
              backgroundColor: successColor),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ErrorHandler.showErrorSnackBar(context, e);
    }
  }

  Future<void> _moveOption(DpcScopeTemplate t, int from, int to) async {
    if (from == to) return;
    final ids = t.options.map((o) => o.id).toList();
    final moved = ids.removeAt(from);
    ids.insert(to, moved);
    try {
      await _service.reorderOptions(t.id, ids);
      if (!mounted) return;
      await _load();
    } catch (e) {
      if (!mounted) return;
      ErrorHandler.showErrorSnackBar(context, e);
    }
  }

  Widget _section(String title, List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.all(defaultPadding),
        decoration: BoxDecoration(
          color: cardBackground,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: containerBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title.toUpperCase(),
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.4,
                    color: textSecondary)),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _readOnlyField(String label, String value) {
    return Row(
      children: [
        SizedBox(
          width: 140,
          child: Text(label,
              style: const TextStyle(
                  color: textSecondary, fontWeight: FontWeight.w500)),
        ),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }

  List<Widget> _bulletEditor(
      List<TextEditingController> ctrls, VoidCallback rebuild) {
    return [
      ...List.generate(ctrls.length, (i) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            children: [
              const Text('•  '),
              Expanded(
                child: TextField(
                  controller: ctrls[i],
                  decoration: const InputDecoration(
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 16),
                onPressed: () {
                  ctrls[i].dispose();
                  ctrls.removeAt(i);
                  rebuild();
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
          onPressed: () {
            ctrls.add(TextEditingController());
            rebuild();
          },
        ),
      ),
    ];
  }

  List<Widget> _brandsEditor() {
    return [
      ...List.generate(_brandRows.length, (i) {
        final row = _brandRows[i];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              SizedBox(
                width: 200,
                child: TextField(
                  controller: row.k,
                  decoration: const InputDecoration(
                    labelText: 'Key',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: row.v,
                  decoration: const InputDecoration(
                    labelText: 'Brand',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 16),
                onPressed: () {
                  row.k.dispose();
                  row.v.dispose();
                  _brandRows.removeAt(i);
                  setState(() {});
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
          label: const Text('Add brand'),
          onPressed: () {
            _brandRows.add((
              k: TextEditingController(),
              v: TextEditingController(),
            ));
            setState(() {});
          },
        ),
      ),
    ];
  }
}

// ────────────────────────────────────────────────────────────────────────
// Scope-option add/edit dialog
// ────────────────────────────────────────────────────────────────────────

class _ScopeOptionFormDialog extends StatefulWidget {
  final DpcScopeTemplate template;
  final DpcScopeOption? existing;

  const _ScopeOptionFormDialog({required this.template, this.existing});

  @override
  State<_ScopeOptionFormDialog> createState() =>
      _ScopeOptionFormDialogState();
}

class _ScopeOptionFormDialogState extends State<_ScopeOptionFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _codeCtrl = TextEditingController();
  final _displayNameCtrl = TextEditingController();
  final _imagePathCtrl = TextEditingController();
  final _displayOrderCtrl = TextEditingController();
  bool _saving = false;

  static final _codeRegExp = RegExp(r'^[A-Za-z0-9_\-]+$');

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      _codeCtrl.text = widget.existing!.code;
      _displayNameCtrl.text = widget.existing!.displayName;
      _imagePathCtrl.text = widget.existing!.imagePath ?? '';
      _displayOrderCtrl.text = widget.existing!.displayOrder.toString();
    } else {
      // Suggest the next display order on create.
      final maxOrder = widget.template.options.isEmpty
          ? 0
          : widget.template.options
              .map((o) => o.displayOrder)
              .reduce((a, b) => a > b ? a : b);
      _displayOrderCtrl.text = (maxOrder + 1).toString();
    }
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    _displayNameCtrl.dispose();
    _imagePathCtrl.dispose();
    _displayOrderCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final svc = DpcTemplateService();
    final order = int.tryParse(_displayOrderCtrl.text.trim());
    final imagePath = _imagePathCtrl.text.trim();
    try {
      DpcScopeOption result;
      if (_isEdit) {
        result = await svc.updateOption(
          widget.existing!.id,
          code: _codeCtrl.text.trim(),
          displayName: _displayNameCtrl.text.trim(),
          imagePath: imagePath, // empty string clears server-side
          displayOrder: order,
        );
      } else {
        result = await svc.addOption(
          widget.template.id,
          code: _codeCtrl.text.trim(),
          displayName: _displayNameCtrl.text.trim(),
          imagePath: imagePath.isEmpty ? null : imagePath,
          displayOrder: order,
        );
      }
      if (!mounted) return;
      Navigator.pop(context, result);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ErrorHandler.showErrorSnackBar(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEdit ? 'Edit option' : 'Add option'),
      content: SizedBox(
        width: 460,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _codeCtrl,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: 'Code',
                  hintText: 'e.g. COLUMN_FOOTING',
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  final s = (v ?? '').trim();
                  if (s.isEmpty) return 'Code is required';
                  if (s.length > 50) return 'Max 50 characters';
                  if (!_codeRegExp.hasMatch(s)) {
                    return 'Letters, digits, underscores and dashes only';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _displayNameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Display name',
                  hintText: 'Column Footing',
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  final s = (v ?? '').trim();
                  if (s.isEmpty) return 'Display name is required';
                  if (s.length > 100) return 'Max 100 characters';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _imagePathCtrl,
                decoration: const InputDecoration(
                  labelText: 'Image path (URL, optional)',
                  hintText: '/dpc-assets/options/foundation-column.png',
                  helperText:
                      'Paste a thumbnail URL. Image upload coming soon.',
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  final s = (v ?? '').trim();
                  if (s.length > 500) return 'Max 500 characters';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _displayOrderCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Display order',
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  final n = int.tryParse((v ?? '').trim());
                  if (n == null) return 'Numeric only';
                  if (n < 1) return 'Must be ≥ 1';
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saving ? null : _submit,
          child: Text(_saving
              ? 'Saving…'
              : (_isEdit ? 'Save' : 'Add')),
        ),
      ],
    );
  }
}
