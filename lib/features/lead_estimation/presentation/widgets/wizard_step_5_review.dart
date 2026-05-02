import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:admin/services/api_service.dart';
import 'package:admin/features/lead_estimation/data/models/lead_estimation.dart';
import 'package:admin/features/lead_estimation/presentation/screens/lead_estimation_wizard_screen.dart';
import 'package:admin/features/lead_estimation/providers/lead_estimations_provider.dart';

/// Step 5 — Review (live preview) + Save.
///
/// On enter / on input change, runs a debounced POST /api/estimations/calculate
/// and renders the totals. The Save button calls the provider's create with
/// the final draft and pops the screen with the created [LeadEstimationDetail].
class WizardStep5Review extends StatefulWidget {
  final WizardDraft draft;
  final LeadEstimationsProvider estimationsProvider;
  final VoidCallback onChanged;
  final void Function(LeadEstimationDetail created) onSaved;

  const WizardStep5Review({
    super.key,
    required this.draft,
    required this.estimationsProvider,
    required this.onChanged,
    required this.onSaved,
  });

  @override
  State<WizardStep5Review> createState() => _WizardStep5ReviewState();
}

class _WizardStep5ReviewState extends State<WizardStep5Review> {
  late final TextEditingController _discountCtrl;
  late final TextEditingController _gstCtrl;
  Map<String, dynamic>? _previewData;
  bool _previewLoading = false;
  String? _previewError;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _discountCtrl = TextEditingController(
        text: widget.draft.discountPercent != null
            ? widget.draft.discountPercent.toString()
            : '');
    _gstCtrl = TextEditingController(
        text: widget.draft.gstRate != null
            ? widget.draft.gstRate.toString()
            : '');
    WidgetsBinding.instance.addPostFrameCallback((_) => _runPreview());
  }

  @override
  void dispose() {
    _discountCtrl.dispose();
    _gstCtrl.dispose();
    super.dispose();
  }

  Future<void> _runPreview() async {
    setState(() {
      _previewLoading = true;
      _previewError = null;
    });
    try {
      final dio = ApiService().dio;
      final response = await dio.post(
        '/api/estimations/calculate',
        data: widget.draft.toPreviewPayload(),
      );
      if (!mounted) return;
      setState(() {
        _previewData = response.data['data'] as Map<String, dynamic>;
        _previewLoading = false;
      });
    } on DioException catch (e) {
      if (!mounted) return;
      final status = e.response?.statusCode;
      String msg;
      if (status == 400) {
        final data = e.response?.data;
        msg = (data is Map && data['message'] is String)
            ? data['message'] as String
            : 'Invalid request — check earlier steps.';
      } else if (status == 403) {
        msg = 'You do not have permission to preview estimations.';
      } else if (status != null && status >= 500) {
        msg = 'Server error. Please try again.';
      } else {
        msg = e.message ?? 'Network error.';
      }
      setState(() {
        _previewError = msg;
        _previewLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _previewError = e.toString().replaceFirst('Exception: ', '');
        _previewLoading = false;
      });
    }
  }

  Future<void> _pickValidUntil() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: widget.draft.validUntil ?? now.add(const Duration(days: 30)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => widget.draft.validUntil = picked);
      widget.onChanged();
    }
  }

  Future<void> _onSave() async {
    if (_previewData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Wait for preview to complete first.')),
      );
      return;
    }
    setState(() => _saving = true);
    final created = await widget.estimationsProvider.create(
      previewPayload: widget.draft.toPreviewPayload(),
      validUntil: widget.draft.validUntil,
    );
    if (!mounted) return;
    setState(() => _saving = false);

    if (created != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Estimation saved (${created.estimationNo}) — total ₹${created.grandTotal.toStringAsFixed(2)}')),
      );
      widget.onSaved(created);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(widget.estimationsProvider.errorMessage ??
                'Failed to save estimation.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _discountCtrl,
                decoration: const InputDecoration(
                  labelText: 'Discount % (0–50)',
                  hintText: '0',
                ),
                keyboardType: TextInputType.number,
                onChanged: (v) {
                  final n = double.tryParse(v.trim());
                  widget.draft.discountPercent = n != null ? n / 100 : null;
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _gstCtrl,
                decoration: const InputDecoration(
                  labelText: 'GST % (default 18)',
                  hintText: '18',
                ),
                keyboardType: TextInputType.number,
                onChanged: (v) {
                  final n = double.tryParse(v.trim());
                  widget.draft.gstRate = n != null ? n / 100 : null;
                },
              ),
            ),
            const SizedBox(width: 12),
            FilledButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Re-preview'),
              onPressed: _previewLoading ? null : _runPreview,
            ),
          ],
        ),
        const SizedBox(height: 16),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(widget.draft.validUntil == null
              ? 'Valid until: today + 30 days (default)'
              : 'Valid until: ${widget.draft.validUntil!.toIso8601String().substring(0, 10)}'),
          trailing: const Icon(Icons.calendar_today_outlined),
          onTap: _pickValidUntil,
        ),
        const SizedBox(height: 16),
        if (_previewLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_previewError != null)
          Card(
            color: Colors.red.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_previewError!,
                      style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 8),
                  FilledButton(
                      onPressed: _runPreview, child: const Text('Retry')),
                ],
              ),
            ),
          )
        else if (_previewData != null)
          _buildTotals(_previewData!),
        const SizedBox(height: 16),
        FilledButton.icon(
          icon: _saving
              ? const SizedBox(
                  width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.save),
          label: Text(_saving ? 'Saving…' : 'Save Estimation'),
          onPressed: _saving ? null : _onSave,
        ),
      ],
    );
  }

  String _fmt(dynamic v) =>
      v == null ? '—' : (v as num).toStringAsFixed(2);

  Widget _buildTotals(Map<String, dynamic> data) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _row('Chargeable area (sqft)', _fmt(data['chargeableArea'])),
            _row('Base cost', '₹${_fmt(data['baseCost'])}'),
            _row('Customisations', '₹${_fmt(data['customisationCost'])}'),
            _row('Site fees', '₹${_fmt(data['siteCost'])}'),
            _row('Add-ons', '₹${_fmt(data['addOnCost'])}'),
            _row('Fluctuation adjustment', '₹${_fmt(data['fluctuationAdjustment'])}'),
            const Divider(),
            _row('Subtotal', '₹${_fmt(data['subtotal'])}', bold: true),
            _row('Govt fees', '₹${_fmt(data['govtFees'])}'),
            _row('Discount', '−₹${_fmt(data['discount'])}'),
            _row('Taxable', '₹${_fmt(data['taxable'])}'),
            _row('GST', '₹${_fmt(data['gst'])}'),
            const Divider(),
            _row('Grand total', '₹${_fmt(data['grandTotal'])}', big: true),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value, {bool bold = false, bool big = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
              child: Text(label,
                  style: TextStyle(
                    fontSize: big ? 16 : 14,
                    fontWeight: bold || big ? FontWeight.w600 : FontWeight.normal,
                  ))),
          Text(value,
              style: TextStyle(
                fontSize: big ? 18 : 14,
                fontWeight: bold || big ? FontWeight.bold : FontWeight.normal,
                color: big ? Colors.green.shade800 : null,
              )),
        ],
      ),
    );
  }
}
