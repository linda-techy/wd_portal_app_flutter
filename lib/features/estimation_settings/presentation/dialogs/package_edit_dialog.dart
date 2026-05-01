import 'package:flutter/material.dart';
import 'package:admin/features/estimation_settings/data/models/estimation_package.dart';

/// Modal dialog for creating or editing an estimation package.
///
/// Returns a Map<String, dynamic> on save (suitable for passing to the provider's
/// create/update method) or null on cancel.
class PackageEditDialog extends StatefulWidget {
  final EstimationPackage? existing;

  const PackageEditDialog({super.key, this.existing});

  static Future<Map<String, dynamic>?> show(
    BuildContext context, {
    EstimationPackage? existing,
  }) {
    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => PackageEditDialog(existing: existing),
    );
  }

  @override
  State<PackageEditDialog> createState() => _PackageEditDialogState();
}

class _PackageEditDialogState extends State<PackageEditDialog> {
  final _formKey = GlobalKey<FormState>();
  late String _internalName;
  late TextEditingController _marketingName;
  late TextEditingController _tagline;
  late TextEditingController _description;
  late TextEditingController _displayOrder;
  late bool _active;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _internalName = e?.internalName ?? 'STANDARD';
    _marketingName = TextEditingController(text: e?.marketingName ?? '');
    _tagline = TextEditingController(text: e?.tagline ?? '');
    _description = TextEditingController(text: e?.description ?? '');
    _displayOrder = TextEditingController(text: (e?.displayOrder ?? 10).toString());
    _active = e?.active ?? true;
  }

  @override
  void dispose() {
    _marketingName.dispose();
    _tagline.dispose();
    _description.dispose();
    _displayOrder.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEdit ? 'Edit Estimation Package' : 'New Estimation Package'),
      content: SizedBox(
        width: 500,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_isEdit)
                  TextFormField(
                    initialValue: _internalName,
                    decoration: const InputDecoration(
                      labelText: 'Internal Name (immutable after creation)',
                    ),
                    enabled: false,
                  )
                else
                  DropdownButtonFormField<String>(
                    value: _internalName,
                    decoration: const InputDecoration(labelText: 'Internal Name'),
                    items: const [
                      DropdownMenuItem(value: 'BASIC', child: Text('BASIC')),
                      DropdownMenuItem(value: 'STANDARD', child: Text('STANDARD')),
                      DropdownMenuItem(value: 'PREMIUM', child: Text('PREMIUM')),
                    ],
                    onChanged: (v) {
                      if (v != null) setState(() => _internalName = v);
                    },
                  ),
                TextFormField(
                  controller: _marketingName,
                  decoration: const InputDecoration(labelText: 'Marketing Name *'),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Required';
                    if (v.trim().length > 100) return 'Max 100 characters';
                    return null;
                  },
                ),
                TextFormField(
                  controller: _tagline,
                  decoration: const InputDecoration(labelText: 'Tagline'),
                  validator: (v) {
                    if (v != null && v.length > 255) return 'Max 255 characters';
                    return null;
                  },
                ),
                TextFormField(
                  controller: _description,
                  decoration: const InputDecoration(labelText: 'Description'),
                  maxLines: 3,
                ),
                TextFormField(
                  controller: _displayOrder,
                  decoration: const InputDecoration(labelText: 'Display Order (1-999)'),
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    final n = int.tryParse(v ?? '');
                    if (n == null) return 'Must be a number';
                    if (n < 1 || n > 999) return 'Must be between 1 and 999';
                    return null;
                  },
                ),
                if (_isEdit)
                  SwitchListTile(
                    title: const Text('Active'),
                    value: _active,
                    onChanged: (v) => setState(() => _active = v),
                    contentPadding: EdgeInsets.zero,
                  ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _onSave,
          child: const Text('Save'),
        ),
      ],
    );
  }

  void _onSave() {
    if (!_formKey.currentState!.validate()) return;
    final result = <String, dynamic>{
      'internalName': _internalName,
      'marketingName': _marketingName.text.trim(),
      'tagline': _tagline.text.trim().isEmpty ? null : _tagline.text.trim(),
      'description': _description.text.trim().isEmpty ? null : _description.text.trim(),
      'displayOrder': int.parse(_displayOrder.text),
      if (_isEdit) 'active': _active,
    };
    Navigator.of(context).pop(result);
  }
}
