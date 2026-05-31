import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:admin/services/boq_payment_service.dart';
import 'package:admin/theme/app_theme.dart';
import 'package:admin/utils/error_handler.dart';
import 'package:admin/providers/portal_auth_provider.dart';

class BoqInvoiceScreen extends StatefulWidget {
  final int projectId;

  const BoqInvoiceScreen({super.key, required this.projectId});

  @override
  State<BoqInvoiceScreen> createState() => _BoqInvoiceScreenState();
}

class _BoqInvoiceScreenState extends State<BoqInvoiceScreen> {
  final _service = BoqPaymentService();
  final _currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);

  List<BoqInvoiceModel> _invoices = [];
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
    setState(() { _isLoading = true; _error = null; });
    try {
      final invoices = await _service.getProjectInvoices(widget.projectId);
      if (mounted) setState(() { _invoices = invoices; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _isLoading = false; _error = e.toString(); });
    }
  }

  // ---- Actions ----

  Future<void> _send(BoqInvoiceModel inv) async {
    try {
      await _service.sendInvoice(inv.id);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Invoice sent')));
        await _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed to send: $e')));
      }
    }
  }

  Future<void> _confirmPayment(BoqInvoiceModel inv) async {
    final refController = TextEditingController();
    final methodController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Payment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: refController,
              decoration: const InputDecoration(
                  labelText: 'Payment Reference *',
                  border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: methodController,
              decoration: const InputDecoration(
                  labelText: 'Payment Method (optional)',
                  hintText: 'NEFT / RTGS / Cheque',
                  border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () {
                if (refController.text.trim().isEmpty) return;
                Navigator.pop(ctx, true);
              },
              child: const Text('Confirm')),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _service.confirmPayment(
          inv.id,
          refController.text.trim(),
          methodController.text.trim().isEmpty
              ? null
              : methodController.text.trim());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Payment confirmed')));
        await _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to confirm payment: $e')));
      }
    }
  }

  Future<void> _showDetail(BoqInvoiceModel inv) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => _InvoiceDetailSheet(
        invoice: inv,
        currency: _currency,
        onSend: inv.status == 'DRAFT' ? () { Navigator.pop(context); _send(inv); } : null,
        onConfirmPayment: (inv.status == 'SENT' || inv.status == 'VIEWED' || inv.status == 'OVERDUE')
            ? () { Navigator.pop(context); _confirmPayment(inv); }
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('BOQ Invoices'),
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
                  child: _invoices.isEmpty
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32),
                            child: Text(
                              'No invoices yet.\nRaise invoices from the Payment Schedule screen.',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _invoices.length,
                          itemBuilder: (_, i) => _InvoiceCard(
                            invoice: _invoices[i],
                            currency: _currency,
                            onTap: () => _showDetail(_invoices[i]),
                          ),
                        ),
                ),
    );
  }
}

// ─── Widgets ─────────────────────────────────────────────────────────────────

class _InvoiceCard extends StatelessWidget {
  final BoqInvoiceModel invoice;
  final NumberFormat currency;
  final VoidCallback onTap;

  const _InvoiceCard(
      {required this.invoice, required this.currency, required this.onTap});

  Color _statusColor() {
    switch (invoice.status) {
      case 'PAID':
        return Colors.green;
      case 'SENT':
      case 'VIEWED':
        return Colors.blue;
      case 'OVERDUE':
        return Colors.red;
      case 'DISPUTED':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _statusColor();
    final df = DateFormat('dd MMM yyyy');
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(invoice.invoiceNumber,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14)),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: color),
                    ),
                    child: Text(invoice.status,
                        style: TextStyle(
                            color: color,
                            fontSize: 10,
                            fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  _TypeBadge(invoiceType: invoice.invoiceType),
                  const Spacer(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(currency.format(invoice.netAmountDue),
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14)),
                      Text('Net due',
                          style: TextStyle(
                              color: Colors.grey[600], fontSize: 11)),
                    ],
                  ),
                ],
              ),
              if (invoice.dueDate != null) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.calendar_today,
                        size: 13, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Text('Due: ${df.format(invoice.dueDate!)}',
                        style: TextStyle(
                            color: Colors.grey[600], fontSize: 12)),
                    if (invoice.paidAt != null) ...[
                      const SizedBox(width: 12),
                      Icon(Icons.check_circle,
                          size: 13, color: Colors.green[600]),
                      const SizedBox(width: 4),
                      Text('Paid: ${df.format(invoice.paidAt!)}',
                          style: TextStyle(
                              color: Colors.green[700], fontSize: 12)),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _TypeBadge extends StatelessWidget {
  final String invoiceType;
  const _TypeBadge({required this.invoiceType});

  @override
  Widget build(BuildContext context) {
    final label = invoiceType.replaceAll('_', ' ');
    final isStage = invoiceType == 'STAGE_INVOICE';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isStage
            ? AppTheme.primaryColor.withOpacity(0.1)
            : Colors.purple.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label,
          style: TextStyle(
              color: isStage ? AppTheme.primaryColor : Colors.purple,
              fontSize: 10,
              fontWeight: FontWeight.w600)),
    );
  }
}

class _InvoiceDetailSheet extends StatelessWidget {
  final BoqInvoiceModel invoice;
  final NumberFormat currency;
  final VoidCallback? onSend;
  final VoidCallback? onConfirmPayment;

  const _InvoiceDetailSheet({
    required this.invoice,
    required this.currency,
    this.onSend,
    this.onConfirmPayment,
  });

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('dd MMM yyyy');
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.65,
      maxChildSize: 0.9,
      builder: (_, controller) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: ListView(
          controller: controller,
          children: [
            const SizedBox(height: 8),
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(invoice.invoiceNumber,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 2),
                      _TypeBadge(invoiceType: invoice.invoiceType),
                    ],
                  ),
                ),
                Text(invoice.status,
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: invoice.isPaid ? Colors.green : Colors.blue)),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            _DetailRow('Subtotal (excl. GST)',
                currency.format(invoice.subtotalExGst)),
            _DetailRow('GST', currency.format(invoice.gstAmount)),
            _DetailRow('Total incl. GST',
                currency.format(invoice.totalInclGst),
                bold: true),
            if (invoice.totalCreditApplied > 0)
              _DetailRow('Credit Applied',
                  '- ${currency.format(invoice.totalCreditApplied)}',
                  color: Colors.blue),
            _DetailRow('Net Amount Due',
                currency.format(invoice.netAmountDue),
                bold: true,
                color: invoice.isPaid ? Colors.green : null),
            const Divider(),
            if (invoice.issueDate != null)
              _DetailRow('Issued', df.format(invoice.issueDate!)),
            if (invoice.dueDate != null)
              _DetailRow('Due Date', df.format(invoice.dueDate!)),
            if (invoice.paidAt != null)
              _DetailRow('Paid On', df.format(invoice.paidAt!),
                  color: Colors.green),
            if (invoice.paymentReference != null)
              _DetailRow('Payment Ref', invoice.paymentReference!),
            const SizedBox(height: 20),
            if (onSend != null)
              _ActionButton(
                  label: 'Send Invoice to Customer',
                  icon: Icons.send,
                  color: AppTheme.primaryColor,
                  onPressed: onSend!),
            if (onConfirmPayment != null)
              _ActionButton(
                  label: 'Confirm Payment Received',
                  icon: Icons.check_circle_outline,
                  color: Colors.green,
                  onPressed: onConfirmPayment!),
            const SizedBox(height: 16),
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
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(color: Colors.grey[600], fontSize: 13)),
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

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(backgroundColor: color),
          onPressed: onPressed,
          icon: Icon(icon, size: 18),
          label: Text(label),
        ),
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
            ElevatedButton(
                onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      );
}
