import 'package:flutter/material.dart';
import 'package:admin/models/variation_order_models.dart';
import 'package:admin/services/variation_order_service.dart';
import 'package:admin/theme/app_theme.dart';
import 'package:admin/utils/error_handler.dart';

class VOCreateScreen extends StatefulWidget {
  final int projectId;

  const VOCreateScreen({super.key, required this.projectId});

  @override
  State<VOCreateScreen> createState() => _VOCreateScreenState();
}

class _VOCreateScreenState extends State<VOCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final VariationOrderService _service = VariationOrderService();

  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _justCtrl = TextEditingController();
  final _scopeCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _boqDocIdCtrl = TextEditingController();

  String _coType = 'ADDITION';
  String? _voCategory;
  bool _isSaving = false;

  static const _coTypes = [
    'ADDITION', 'OMISSION', 'SUBSTITUTION', 'REVISION', 'SCOPE_REDUCTION'
  ];
  static const _voCategories = [
    'MATERIAL_HEAVY', 'LABOUR_HEAVY', 'MIXED', 'CUSTOM'
  ];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _justCtrl.dispose();
    _scopeCtrl.dispose();
    _amountCtrl.dispose();
    _boqDocIdCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      await _service.create(
        widget.projectId,
        CreateVariationOrderRequest(
          boqDocumentId: int.parse(_boqDocIdCtrl.text.trim()),
          title: _titleCtrl.text.trim(),
          description: _descCtrl.text.trim().isEmpty
              ? null
              : _descCtrl.text.trim(),
          justification: _justCtrl.text.trim().isEmpty
              ? null
              : _justCtrl.text.trim(),
          scopeNotes: _scopeCtrl.text.trim().isEmpty
              ? null
              : _scopeCtrl.text.trim(),
          coType: _coType,
          voCategory: _voCategory,
          netAmountExGst: double.parse(_amountCtrl.text.trim()),
        ),
      );
      if (!mounted) return;
      ErrorHandler.showSuccessSnackBar(context, 'Variation order created');
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ErrorHandler.showErrorSnackBar(context, e);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.deepSlate,
        foregroundColor: Colors.white,
        title: const Text('New Variation Order',
            style: TextStyle(fontSize: 16)),
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2)),
            )
          else
            TextButton(
              onPressed: _submit,
              child: const Text('Save',
                  style: TextStyle(color: Colors.white,
                      fontWeight: FontWeight.bold)),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _section('BOQ Reference'),
            _field(_boqDocIdCtrl, 'BOQ Document ID',
                keyboardType: TextInputType.number,
                validator: (v) => v == null || v.isEmpty
                    ? 'Required'
                    : int.tryParse(v) == null
                        ? 'Must be a number'
                        : null),
            const SizedBox(height: 16),
            _section('VO Details'),
            _field(_titleCtrl, 'Title *',
                validator: (v) =>
                    v == null || v.isEmpty ? 'Required' : null),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: _coType,
              decoration: _inputDecoration('Type *'),
              items: _coTypes
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: (v) => setState(() => _coType = v!),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: _voCategory,
              decoration: _inputDecoration('VO Category'),
              hint: const Text('Select (optional)'),
              items: _voCategories
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => setState(() => _voCategory = v),
            ),
            const SizedBox(height: 16),
            _section('Financials'),
            _field(_amountCtrl, 'Net Amount (excl. GST) *',
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: (v) => v == null || v.isEmpty
                    ? 'Required'
                    : double.tryParse(v) == null
                        ? 'Must be a number'
                        : null),
            const SizedBox(height: 16),
            _section('Scope'),
            _field(_descCtrl, 'Description', maxLines: 3),
            const SizedBox(height: 10),
            _field(_justCtrl, 'Justification', maxLines: 3),
            const SizedBox(height: 10),
            _field(_scopeCtrl, 'Scope Notes', maxLines: 4),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.coralRed,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: _isSaving ? null : _submit,
              child: const Text('Create Variation Order',
                  style: TextStyle(color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _section(String title) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(title,
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: AppTheme.deepSlate)),
      );

  Widget _field(TextEditingController ctrl, String label,
      {TextInputType? keyboardType,
      int maxLines = 1,
      String? Function(String?)? validator}) =>
      TextFormField(
        controller: ctrl,
        keyboardType: keyboardType,
        maxLines: maxLines,
        validator: validator,
        decoration: _inputDecoration(label),
      );

  InputDecoration _inputDecoration(String label) => InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 12, vertical: 10),
      );
}
