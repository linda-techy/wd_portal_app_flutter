import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:admin/constants.dart';
import 'package:admin/features/dpc_customization_catalog/data/models/dpc_customization_catalog_item.dart';
import 'package:admin/features/dpc_customization_catalog/data/services/dpc_customization_catalog_service.dart';
import 'package:admin/utils/error_handler.dart';

/// Dialog opened from a DPC manual customization line's "..." menu when the
/// line was authored ad-hoc (i.e. `customizationCatalogId == null`).
///
/// Submits to `/api/dpc-documents/customizations/{lineId}/promote-to-catalog`.
/// On success the parent receives the new
/// [DpcCustomizationCatalogItem] via the popped dialog result and should
/// refresh the DPC document.
class PromoteDpcCustomizationToCatalogDialog extends StatefulWidget {
  /// DPC customization line id being promoted.
  final int lineId;

  /// Source line title — used to derive a default code when the user
  /// leaves the code field blank, and pre-fills the Name field.
  final String sourceTitle;

  /// Source line amount — pre-fills the catalog row's defaultAmount so
  /// the user usually only needs to confirm.
  final double sourceAmount;

  /// Categories already known in the catalog (used for the dropdown).
  final List<String> existingCategories;

  const PromoteDpcCustomizationToCatalogDialog({
    super.key,
    required this.lineId,
    required this.sourceTitle,
    required this.sourceAmount,
    this.existingCategories = const [],
  });

  @override
  State<PromoteDpcCustomizationToCatalogDialog> createState() =>
      _PromoteDpcCustomizationToCatalogDialogState();
}

class _PromoteDpcCustomizationToCatalogDialogState
    extends State<PromoteDpcCustomizationToCatalogDialog> {
  final _formKey = GlobalKey<FormState>();
  final DpcCustomizationCatalogService _service =
      DpcCustomizationCatalogService();

  late final TextEditingController _codeCtrl;
  late final TextEditingController _nameCtrl;
  late final TextEditingController _unitCtrl;
  late final TextEditingController _amountCtrl;
  String? _category;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _codeCtrl =
        TextEditingController(text: _deriveCode(widget.sourceTitle));
    _nameCtrl = TextEditingController(text: widget.sourceTitle);
    _unitCtrl = TextEditingController();
    _amountCtrl = TextEditingController(
      text: widget.sourceAmount.toStringAsFixed(2),
    );
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    _nameCtrl.dispose();
    _unitCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  /// Mirrors the backend's auto-derivation: uppercase, strip non-alphanumeric,
  /// truncate to 80 — kept in sync so the suggested code matches what the
  /// service would produce when left blank.
  static String _deriveCode(String title) {
    final cleaned = title
        .toUpperCase()
        .replaceAll(RegExp(r'[^A-Z0-9]+'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
    if (cleaned.length <= 80) return cleaned;
    return cleaned.substring(0, 80);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final code = _codeCtrl.text.trim().toUpperCase();
      final name = _nameCtrl.text.trim();
      final unit =
          _unitCtrl.text.trim().isEmpty ? null : _unitCtrl.text.trim();
      final amount = double.tryParse(_amountCtrl.text.trim()) ?? 0;

      final result = await _service.promoteCustomizationToCatalog(
        lineId: widget.lineId,
        code: code,
        name: name,
        category: _category,
        unit: unit,
        defaultAmount: amount,
      );
      if (!mounted) return;
      Navigator.of(context).pop(result);
    } catch (e) {
      if (mounted) {
        ErrorHandler.showErrorSnackBar(context, e);
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Promote to Catalog'),
      content: SizedBox(
        width: 460,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: boxInfo,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: boxBorderInfo),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, size: 16, color: infoColor),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Adds this customization to the master catalog so '
                          'it can be reused on future DPC documents.',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _codeCtrl,
                  textCapitalization: TextCapitalization.characters,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                        RegExp(r'[A-Za-z0-9\-]')),
                    LengthLimitingTextInputFormatter(80),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Code',
                    hintText: 'auto-derived from title',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  validator: (v) {
                    final s = v?.trim() ?? '';
                    if (s.isEmpty) return null; // backend will derive
                    if (s.length > 80) return 'Max 80 characters';
                    if (!RegExp(r'^[A-Za-z0-9\-]+$').hasMatch(s)) {
                      return 'Only A-Z, 0-9 and - allowed';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _nameCtrl,
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(255),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Name *',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  validator: (v) {
                    final s = v?.trim() ?? '';
                    if (s.isEmpty) return 'Name is required';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String?>(
                  value: _category,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('— None —'),
                    ),
                    ...widget.existingCategories.map(
                      (c) => DropdownMenuItem<String?>(
                          value: c, child: Text(c)),
                    ),
                  ],
                  onChanged: (v) => setState(() => _category = v),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    SizedBox(
                      width: 140,
                      child: TextFormField(
                        controller: _unitCtrl,
                        inputFormatters: [
                          LengthLimitingTextInputFormatter(40),
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Unit',
                          hintText: 'sqft / lot / nos',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _amountCtrl,
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'[0-9.]')),
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Default amount *',
                          prefixText: '\u20B9 ',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        validator: (v) {
                          final s = v?.trim() ?? '';
                          if (s.isEmpty) return 'Required';
                          final n = double.tryParse(s);
                          if (n == null) return 'Enter a number';
                          if (n < 0) return 'Must be ≥ 0';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saving ? null : _submit,
          child: Text(_saving ? 'Promoting...' : 'Promote'),
        ),
      ],
    );
  }
}
