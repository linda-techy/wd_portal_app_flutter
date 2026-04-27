import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:admin/constants.dart';
import 'package:admin/features/quotation_catalog/data/models/quotation_catalog_item.dart';
import 'package:admin/features/quotation_catalog/data/services/quotation_catalog_service.dart';
import 'package:admin/utils/error_handler.dart';

/// Dialog opened from a quotation line-item's "..." menu when the line was
/// authored ad-hoc (i.e. `catalogItemId == null`).
///
/// Submits to `/leads/quotations/items/{itemId}/promote-to-catalog`. On
/// success the parent receives the new [QuotationCatalogItem] via the popped
/// dialog result and should refresh.
class PromoteToCatalogDialog extends StatefulWidget {
  /// Quotation line item id being promoted.
  final int itemId;

  /// Source line description — used to derive a default code when the user
  /// leaves the code field blank.
  final String sourceDescription;

  /// Source line unit price — pre-fills the catalog row's defaultUnitPrice
  /// so the user usually only needs to confirm.
  final double sourceUnitPrice;

  /// Categories already known in the catalog (used for the dropdown).
  final List<String> existingCategories;

  const PromoteToCatalogDialog({
    super.key,
    required this.itemId,
    required this.sourceDescription,
    required this.sourceUnitPrice,
    this.existingCategories = const [],
  });

  @override
  State<PromoteToCatalogDialog> createState() => _PromoteToCatalogDialogState();
}

class _PromoteToCatalogDialogState extends State<PromoteToCatalogDialog> {
  final _formKey = GlobalKey<FormState>();
  final QuotationCatalogService _service = QuotationCatalogService();

  late final TextEditingController _codeCtrl;
  late final TextEditingController _nameCtrl;
  late final TextEditingController _unitCtrl;
  late final TextEditingController _priceCtrl;
  String? _category;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _codeCtrl =
        TextEditingController(text: _deriveCode(widget.sourceDescription));
    _nameCtrl = TextEditingController(text: widget.sourceDescription);
    _unitCtrl = TextEditingController();
    _priceCtrl = TextEditingController(
      text: widget.sourceUnitPrice.toStringAsFixed(2),
    );
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    _nameCtrl.dispose();
    _unitCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  /// Mirrors the backend's auto-derivation: uppercase, strip non-alphanumeric,
  /// truncate to 80 — kept in sync so the suggested code matches what the
  /// service would produce when left blank.
  static String _deriveCode(String desc) {
    final cleaned = desc
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
      final price = double.tryParse(_priceCtrl.text.trim()) ?? 0;

      final result = await _service.promoteItemToCatalog(
        itemId: widget.itemId,
        code: code,
        name: name,
        category: _category,
        unit: unit,
        defaultUnitPrice: price,
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
                          'Adds this line item to the master catalog so it '
                          'can be reused on future quotations.',
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
                    hintText: 'auto-derived from description',
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
                          hintText: 'sqft / lot',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _priceCtrl,
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'[0-9.]')),
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Default unit price *',
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
