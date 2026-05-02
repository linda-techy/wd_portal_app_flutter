import 'package:flutter/material.dart';

/// Modal dialog for creating a new rate version. Returns a Map<String, dynamic> on save,
/// or null on cancel. Caller is responsible for passing packageId + projectType to the
/// provider (they're not part of the dialog because they're selected on the parent screen).
class NewRateVersionDialog extends StatefulWidget {
  const NewRateVersionDialog({super.key});

  static Future<Map<String, dynamic>?> show(BuildContext context) {
    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => const NewRateVersionDialog(),
    );
  }

  @override
  State<NewRateVersionDialog> createState() => _NewRateVersionDialogState();
}

class _NewRateVersionDialogState extends State<NewRateVersionDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _materialRate;
  late TextEditingController _labourRate;
  late TextEditingController _overheadRate;
  DateTime? _effectiveFrom;

  @override
  void initState() {
    super.initState();
    _materialRate = TextEditingController();
    _labourRate = TextEditingController();
    _overheadRate = TextEditingController();
  }

  @override
  void dispose() {
    _materialRate.dispose();
    _labourRate.dispose();
    _overheadRate.dispose();
    super.dispose();
  }

  String? _validateRate(String? v) {
    if (v == null || v.trim().isEmpty) return 'Required';
    final n = double.tryParse(v.trim());
    if (n == null) return 'Must be a number';
    if (n < 0.01 || n > 99999.99) return 'Must be between 0.01 and 99999.99';
    return null;
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _effectiveFrom ?? now,
      firstDate: now.subtract(const Duration(days: 365 * 5)),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _effectiveFrom = picked);
  }

  void _onSave() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(<String, dynamic>{
      'materialRate': double.parse(_materialRate.text),
      'labourRate': double.parse(_labourRate.text),
      'overheadRate': double.parse(_overheadRate.text),
      if (_effectiveFrom != null) 'effectiveFrom': _effectiveFrom,
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New Rate Version'),
      content: SizedBox(
        width: 460,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _materialRate,
                decoration: const InputDecoration(labelText: 'Material rate (₹/sqft) *'),
                keyboardType: TextInputType.number,
                validator: _validateRate,
              ),
              TextFormField(
                controller: _labourRate,
                decoration: const InputDecoration(labelText: 'Labour rate (₹/sqft) *'),
                keyboardType: TextInputType.number,
                validator: _validateRate,
              ),
              TextFormField(
                controller: _overheadRate,
                decoration: const InputDecoration(labelText: 'Overhead rate (₹/sqft) *'),
                keyboardType: TextInputType.number,
                validator: _validateRate,
              ),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(_effectiveFrom == null
                    ? 'Effective from: today (default)'
                    : 'Effective from: ${_effectiveFrom!.toIso8601String().substring(0, 10)}'),
                trailing: const Icon(Icons.calendar_today_outlined),
                onTap: _pickDate,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(null), child: const Text('Cancel')),
        FilledButton(onPressed: _onSave, child: const Text('Save')),
      ],
    );
  }
}
