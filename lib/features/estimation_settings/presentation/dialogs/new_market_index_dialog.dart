import 'package:flutter/material.dart';
import 'package:admin/features/estimation_settings/data/models/market_index_snapshot.dart';

/// Modal dialog for publishing a new market index snapshot. Returns a
/// Map<String, dynamic> with `rates` (Map<String, double>), `weights`
/// (Map<String, double>), and optional `snapshotDate` (DateTime) on save,
/// or null on cancel.
class NewMarketIndexDialog extends StatefulWidget {
  /// Optional starting values from the current active snapshot — saves the
  /// admin from re-entering 14 values when only one or two changed.
  final MarketIndexSnapshot? template;

  const NewMarketIndexDialog({super.key, this.template});

  static Future<Map<String, dynamic>?> show(
    BuildContext context, {
    MarketIndexSnapshot? template,
  }) {
    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => NewMarketIndexDialog(template: template),
    );
  }

  @override
  State<NewMarketIndexDialog> createState() => _NewMarketIndexDialogState();
}

class _NewMarketIndexDialogState extends State<NewMarketIndexDialog> {
  final _formKey = GlobalKey<FormState>();
  late Map<String, TextEditingController> _rateControllers;
  late Map<String, TextEditingController> _weightControllers;
  DateTime? _snapshotDate;

  @override
  void initState() {
    super.initState();
    final t = widget.template;
    _rateControllers = {
      for (final c in kMarketIndexCommodities)
        c: TextEditingController(text: t?.ratesByCommodity[c]?.toString() ?? ''),
    };
    _weightControllers = {
      for (final c in kMarketIndexCommodities)
        c: TextEditingController(text: t?.weightFor(c).toString() ?? ''),
    };
  }

  @override
  void dispose() {
    for (final c in _rateControllers.values) {
      c.dispose();
    }
    for (final c in _weightControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  String? _validateRate(String? v) {
    if (v == null || v.trim().isEmpty) return 'Required';
    final n = double.tryParse(v.trim());
    if (n == null) return 'Must be a number';
    if (n < 0.01 || n > 99999.99) return 'Must be between 0.01 and 99999.99';
    return null;
  }

  String? _validateWeight(String? v) {
    if (v == null || v.trim().isEmpty) return 'Required';
    final n = double.tryParse(v.trim());
    if (n == null) return 'Must be a number';
    if (n < 0.0 || n > 1.0) return 'Must be between 0.00 and 1.00';
    return null;
  }

  double get _weightSum {
    double sum = 0;
    for (final c in _weightControllers.values) {
      sum += double.tryParse(c.text.trim()) ?? 0;
    }
    return sum;
  }

  bool get _weightSumOk => _weightSum >= 0.99 && _weightSum <= 1.01;

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _snapshotDate ?? now,
      firstDate: now.subtract(const Duration(days: 365 * 5)),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _snapshotDate = picked);
  }

  void _onSave() {
    if (!_formKey.currentState!.validate()) return;
    if (!_weightSumOk) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(
          'Weights must sum to between 0.99 and 1.01 (currently ${_weightSum.toStringAsFixed(4)}).',
        )),
      );
      return;
    }
    Navigator.of(context).pop(<String, dynamic>{
      'rates': {
        for (final c in kMarketIndexCommodities)
          c: double.parse(_rateControllers[c]!.text.trim()),
      },
      'weights': {
        for (final c in kMarketIndexCommodities)
          c: double.parse(_weightControllers[c]!.text.trim()),
      },
      if (_snapshotDate != null) 'snapshotDate': _snapshotDate,
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New Market Index Snapshot'),
      content: SizedBox(
        width: 600,
        child: Form(
          key: _formKey,
          onChanged: () => setState(() {}), // re-evaluate weight sum on every keystroke
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Commodity rates (₹/unit)', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ...kMarketIndexCommodities.map((c) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: TextFormField(
                        controller: _rateControllers[c],
                        decoration: InputDecoration(labelText: '$c rate *'),
                        keyboardType: TextInputType.number,
                        validator: _validateRate,
                      ),
                    )),
                const SizedBox(height: 16),
                const Text('Weights (each 0.00-1.00, sum ~1.0)', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ...kMarketIndexCommodities.map((c) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: TextFormField(
                        controller: _weightControllers[c],
                        decoration: InputDecoration(labelText: '$c weight *'),
                        keyboardType: TextInputType.number,
                        validator: _validateWeight,
                      ),
                    )),
                const SizedBox(height: 8),
                Text(
                  'Sum: ${_weightSum.toStringAsFixed(4)}'
                  '${_weightSumOk ? "" : "  ← must be in [0.99, 1.01]"}',
                  style: TextStyle(
                    color: _weightSumOk ? Colors.green : Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(_snapshotDate == null
                      ? 'Snapshot date: today (default)'
                      : 'Snapshot date: ${_snapshotDate!.toIso8601String().substring(0, 10)}'),
                  trailing: const Icon(Icons.calendar_today_outlined),
                  onTap: _pickDate,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(null), child: const Text('Cancel')),
        FilledButton(onPressed: _onSave, child: const Text('Publish')),
      ],
    );
  }
}
