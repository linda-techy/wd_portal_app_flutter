import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:admin/services/boq_payment_service.dart';
import 'package:admin/theme/app_theme.dart';
import 'package:admin/utils/error_handler.dart';
import 'package:admin/providers/portal_auth_provider.dart';

class PaymentScheduleScreen extends StatefulWidget {
  final int projectId;

  const PaymentScheduleScreen({super.key, required this.projectId});

  @override
  State<PaymentScheduleScreen> createState() => _PaymentScheduleScreenState();
}

class _PaymentScheduleScreenState extends State<PaymentScheduleScreen> {
  final _service = BoqPaymentService();
  final _currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);
  final _pct = NumberFormat.percentPattern()..maximumFractionDigits = 1;

  List<PaymentStageModel> _stages = [];
  Map<String, dynamic>? _financeSummary;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final auth = Provider.of<PortalAuthProvider>(context, listen: false);
    if (!auth.isAuthenticated) {
      if (mounted) await ErrorHandler.handleAuthError(context);
      if (mounted) unawaited(Navigator.of(context).pushReplacementNamed('/login'));
      return;
    }
    await _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _service.getPaymentSchedule(widget.projectId),
        _service.getFinanceSummary(widget.projectId),
      ]);
      if (mounted) {
        setState(() {
          _stages = results[0] as List<PaymentStageModel>;
          _financeSummary = results[1] as Map<String, dynamic>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _isLoading = false; _error = e.toString(); });
    }
  }

  // ---- Raise invoice ----

  Future<void> _raiseInvoice(PaymentStageModel stage) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked == null) return;

    try {
      await _service.raiseStageInvoice(
          stage.id, picked.toIso8601String().split('T').first);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Stage invoice raised successfully')),
        );
        await _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to raise invoice: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Schedule'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _ErrorView(message: _error!, onRetry: _load)
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      if (_financeSummary != null) _FinanceSummaryCard(
                        summary: _financeSummary!,
                        currency: _currency,
                      ),
                      const SizedBox(height: 16),
                      if (_stages.isEmpty)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32),
                            child: Text(
                              'No payment schedule yet.\nThe schedule is generated automatically when the customer approves the BOQ.',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        )
                      else
                        ..._stages.map((s) => _StageCard(
                              stage: s,
                              currency: _currency,
                              pct: _pct,
                              onRaiseInvoice: (s.status == 'DUE' || s.status == 'UPCOMING') && s.invoiceId == null
                                  ? () => _raiseInvoice(s)
                                  : null,
                            )),
                    ],
                  ),
                ),
    );
  }
}

// ─── Widgets ─────────────────────────────────────────────────────────────────

class _FinanceSummaryCard extends StatelessWidget {
  final Map<String, dynamic> summary;
  final NumberFormat currency;

  const _FinanceSummaryCard({required this.summary, required this.currency});

  @override
  Widget build(BuildContext context) {
    double v(String k) {
      final val = summary[k];
      if (val == null) return 0;
      if (val is num) return val.toDouble();
      return double.tryParse(val.toString()) ?? 0;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Finance Overview',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const Divider(),
            _Row('Original Contract', v('originalContractValue'), currency),
            _Row('CO Additions (+)', v('coAdditions'), currency,
                color: Colors.green),
            _Row('CO Reductions (-)', v('coReductions'), currency,
                color: Colors.orange),
            _Row('Net Project Value', v('netProjectValue'), currency,
                bold: true),
            const Divider(),
            _Row('Total Invoiced', v('totalInvoiced'), currency),
            _Row('Total Collected', v('totalCollected'), currency,
                color: Colors.green),
            _Row('Outstanding', v('totalOutstanding'), currency,
                color: Colors.red),
            if (v('pendingCredits') > 0)
              _Row('Pending Credits', v('pendingCredits'), currency,
                  color: Colors.blue),
            if (v('pendingRefundsToCustomer') > 0)
              _Row('Refunds Due', v('pendingRefundsToCustomer'), currency,
                  color: Colors.purple),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final double value;
  final NumberFormat currency;
  final Color? color;
  final bool bold;

  const _Row(this.label, this.value, this.currency,
      {this.color, this.bold = false});

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
        color: color,
        fontWeight: bold ? FontWeight.bold : FontWeight.normal);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text(currency.format(value), style: style),
        ],
      ),
    );
  }
}

class _StageCard extends StatelessWidget {
  final PaymentStageModel stage;
  final NumberFormat currency;
  final NumberFormat pct;
  final VoidCallback? onRaiseInvoice;

  const _StageCard({
    required this.stage,
    required this.currency,
    required this.pct,
    this.onRaiseInvoice,
  });

  Color _statusColor() {
    switch (stage.status) {
      case 'PAID':
        return Colors.green;
      case 'INVOICED':
        return Colors.blue;
      case 'DUE':
        return Colors.orange;
      case 'OVERDUE':
        return Colors.red;
      case 'ON_HOLD':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppTheme.primaryColor,
                  child: Text('${stage.stageNumber}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(stage.stageName,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      if (stage.milestoneDescription != null)
                        Text(stage.milestoneDescription!,
                            style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusColor().withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _statusColor()),
                  ),
                  child: Text(stage.status,
                      style: TextStyle(
                          color: _statusColor(),
                          fontSize: 11,
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _DetailRow('Stage %',
                pct.format(stage.stagePercentage)),
            _DetailRow('Stage Amount (excl. GST)',
                currency.format(stage.stageAmountExGst)),
            _DetailRow('GST', currency.format(stage.gstAmount)),
            _DetailRow('Gross Payable',
                currency.format(stage.stageAmountInclGst),
                bold: true),
            if (stage.appliedCreditAmount > 0)
              _DetailRow('Credit Applied',
                  '- ${currency.format(stage.appliedCreditAmount)}',
                  color: Colors.blue),
            _DetailRow('Net Payable',
                currency.format(stage.netPayableAmount),
                bold: true,
                color: stage.status == 'PAID' ? Colors.green : null),
            if (stage.dueDate != null)
              _DetailRow('Due Date',
                  DateFormat('dd MMM yyyy').format(stage.dueDate!)),
            if (stage.paidAt != null)
              _DetailRow('Paid On',
                  DateFormat('dd MMM yyyy').format(stage.paidAt!),
                  color: Colors.green),
            if (onRaiseInvoice != null) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onRaiseInvoice,
                  icon: const Icon(Icons.receipt_long, size: 16),
                  label: const Text('Raise Invoice'),
                ),
              ),
            ],
            if (stage.invoiceId != null && stage.status != 'PAID')
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Invoice #${stage.invoiceId} raised',
                  style: TextStyle(
                      color: Colors.blue[700], fontSize: 12),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  final Color? color;

  const _DetailRow(this.label, this.value,
      {this.bold = false, this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  color: Colors.grey[600], fontSize: 13)),
          Text(value,
              style: TextStyle(
                  fontWeight: bold ? FontWeight.bold : FontWeight.normal,
                  color: color,
                  fontSize: 13)),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      );
}
