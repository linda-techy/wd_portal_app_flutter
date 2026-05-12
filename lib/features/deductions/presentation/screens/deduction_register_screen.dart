import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:admin/models/deduction_models.dart';
import 'package:admin/services/deduction_service.dart';
import 'package:admin/theme/app_theme.dart';
import 'package:admin/utils/error_handler.dart';

class DeductionRegisterScreen extends StatefulWidget {
  final int projectId;
  final String projectName;

  const DeductionRegisterScreen({
    super.key,
    required this.projectId,
    required this.projectName,
  });

  @override
  State<DeductionRegisterScreen> createState() =>
      _DeductionRegisterScreenState();
}

class _DeductionRegisterScreenState extends State<DeductionRegisterScreen> {
  final DeductionService _service = DeductionService();
  final _currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

  List<DeductionRegisterEntry> _deductions = [];
  bool _isLoading = true;

  static const _decisionColors = {
    'PENDING':               Colors.orange,
    'ACCEPTABLE':            Colors.green,
    'PARTIALLY_ACCEPTABLE':  Colors.teal,
    'REJECTED':              Colors.red,
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final list = await _service.getByProject(widget.projectId);
      if (!mounted) return;
      setState(() {
        _deductions = list;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ErrorHandler.showErrorSnackBar(context, e);
    }
  }

  Future<void> _createDeduction() async {
    final descCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Deduction'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: descCtrl,
              decoration: const InputDecoration(
                  labelText: 'Description *',
                  border: OutlineInputBorder()),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: amountCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                  labelText: 'Amount (₹) *',
                  border: OutlineInputBorder(),
                  prefixText: '₹ '),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.coralRed),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Add',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    if (descCtrl.text.trim().isEmpty || amountCtrl.text.trim().isEmpty) {
      ErrorHandler.showErrorSnackBar(context, 'All fields are required');
      return;
    }
    try {
      await _service.create(
        widget.projectId,
        CreateDeductionRequest(
          itemDescription: descCtrl.text.trim(),
          requestedAmount: double.parse(amountCtrl.text.trim()),
        ),
      );
      if (!mounted) return;
      ErrorHandler.showSuccessSnackBar(context, 'Deduction added');
      _load();
    } catch (e) {
      if (!mounted) return;
      ErrorHandler.showErrorSnackBar(context, e);
    }
  }

  Future<void> _recordDecision(DeductionRegisterEntry d) async {
    String decision = 'ACCEPTABLE';
    final acceptedCtrl = TextEditingController(
        text: d.requestedAmount.toString());
    final rejCtrl = TextEditingController();
    final approvedByCtrl = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('Record Decision'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: decision,
                  decoration: const InputDecoration(
                      labelText: 'Decision',
                      border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(
                        value: 'ACCEPTABLE',
                        child: Text('Acceptable')),
                    DropdownMenuItem(
                        value: 'PARTIALLY_ACCEPTABLE',
                        child: Text('Partially Acceptable')),
                    DropdownMenuItem(
                        value: 'REJECTED',
                        child: Text('Rejected')),
                  ],
                  onChanged: (v) => setS(() => decision = v!),
                ),
                const SizedBox(height: 12),
                if (decision == 'PARTIALLY_ACCEPTABLE')
                  TextField(
                    controller: acceptedCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    decoration: const InputDecoration(
                        labelText: 'Accepted Amount',
                        border: OutlineInputBorder(),
                        prefixText: '₹ '),
                  ),
                if (decision == 'REJECTED') ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: rejCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Rejection Reason *',
                        border: OutlineInputBorder()),
                    maxLines: 2,
                  ),
                ],
                const SizedBox(height: 12),
                TextField(
                  controller: approvedByCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Approved By *',
                      border: OutlineInputBorder()),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.coralRed),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Submit',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await _service.recordDecision(
        widget.projectId,
        d.id,
        DeductionDecisionRequest(
          decision: decision,
          acceptedAmount: decision == 'PARTIALLY_ACCEPTABLE'
              ? double.tryParse(acceptedCtrl.text)
              : null,
          rejectionReason:
              decision == 'REJECTED' ? rejCtrl.text.trim() : null,
          approvedBy: approvedByCtrl.text.trim(),
        ),
      );
      if (!mounted) return;
      ErrorHandler.showSuccessSnackBar(context, 'Decision recorded');
      _load();
    } catch (e) {
      if (!mounted) return;
      ErrorHandler.showErrorSnackBar(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.deepSlate,
        foregroundColor: Colors.white,
        title: Text('Deductions — ${widget.projectName}',
            style: const TextStyle(fontSize: 16)),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.coralRed,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add', style: TextStyle(color: Colors.white)),
        onPressed: _createDeduction,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildList(),
    );
  }

  Widget _buildList() {
    if (_deductions.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.remove_circle_outline, size: 56, color: Colors.grey),
            SizedBox(height: 12),
            Text('No deductions recorded.',
                style: TextStyle(color: Colors.grey, fontSize: 15)),
          ],
        ),
      );
    }

    final totalRequested = _deductions.fold<double>(
        0, (s, d) => s + d.requestedAmount);
    final totalAccepted = _deductions.fold<double>(
        0, (s, d) => s + (d.acceptedAmount ?? 0));

    return Column(
      children: [
        _summaryBar(totalRequested, totalAccepted),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _load,
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 80),
              itemCount: _deductions.length,
              itemBuilder: (_, i) => _buildCard(_deductions[i]),
            ),
          ),
        ),
      ],
    );
  }

  Widget _summaryBar(double requested, double accepted) => Container(
        color: AppTheme.deepSlate,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            _summaryItem('Requested', _currency.format(requested),
                Colors.orange),
            const SizedBox(width: 24),
            _summaryItem(
                'Accepted', _currency.format(accepted), Colors.green),
          ],
        ),
      );

  Widget _summaryItem(String label, String value, Color color) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(color: Colors.white60, fontSize: 11)),
          Text(value,
              style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 14)),
        ],
      );

  Widget _buildCard(DeductionRegisterEntry d) {
    final decColor = _decisionColors[d.decision] ?? Colors.grey;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(d.itemDescription,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: decColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(d.decision,
                      style: TextStyle(
                          color: decColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text('Requested: ${_currency.format(d.requestedAmount)}',
                    style: const TextStyle(fontSize: 13)),
                const SizedBox(width: 12),
                if (d.acceptedAmount != null)
                  Text(
                      'Accepted: ${_currency.format(d.acceptedAmount!)}',
                      style: TextStyle(
                          fontSize: 13,
                          color: Colors.green[700],
                          fontWeight: FontWeight.w600)),
              ],
            ),
            if (d.isEscalated)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  children: [
                    Icon(Icons.arrow_upward,
                        size: 14, color: Colors.indigo[600]),
                    Text(' Escalated to: ${d.escalatedTo ?? "—"}',
                        style: TextStyle(
                            fontSize: 12, color: Colors.indigo[600])),
                  ],
                ),
              ),
            if (d.settledInFinalAccount)
              const Padding(
                padding: EdgeInsets.only(top: 4),
                child: Row(
                  children: [
                    Icon(Icons.check_circle_outline,
                        size: 14, color: Colors.green),
                    Text(' Settled in Final Account',
                        style: TextStyle(
                            fontSize: 12, color: Colors.green)),
                  ],
                ),
              ),
            if (d.isPending) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => _recordDecision(d),
                  child: const Text('Record Decision'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
