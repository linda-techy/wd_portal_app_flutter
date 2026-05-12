import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:admin/services/boq_payment_service.dart';
import 'package:admin/theme/app_theme.dart';
import 'package:admin/utils/error_handler.dart';
import 'package:admin/providers/portal_auth_provider.dart';

class CoManagementScreen extends StatefulWidget {
  final int projectId;

  const CoManagementScreen({super.key, required this.projectId});

  @override
  State<CoManagementScreen> createState() => _CoManagementScreenState();
}

class _CoManagementScreenState extends State<CoManagementScreen> {
  final _service = BoqPaymentService();
  final _currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);

  List<ChangeOrderModel> _cos = [];
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
      if (mounted) Navigator.of(context).pushReplacementNamed('/login');
      return;
    }
    await _load();
  }

  Future<void> _load() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final cos = await _service.getChangeOrders(widget.projectId);
      if (mounted) setState(() { _cos = cos; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _isLoading = false; _error = e.toString(); });
    }
  }

  // ---- Lifecycle actions ----

  Future<void> _submit(ChangeOrderModel co) async {
    await _performAction(() => _service.submitChangeOrder(co.id), 'CO submitted');
  }

  Future<void> _sendToCustomer(ChangeOrderModel co) async {
    await _performAction(
        () => _service.sendChangeOrderToCustomer(co.id), 'Sent to customer');
  }

  Future<void> _start(ChangeOrderModel co) async {
    await _performAction(() => _service.startChangeOrder(co.id), 'CO started');
  }

  Future<void> _complete(ChangeOrderModel co) async {
    await _performAction(
        () => _service.completeChangeOrder(co.id), 'CO completed');
  }

  Future<void> _performAction(
      Future<ChangeOrderModel> Function() action, String successMsg) async {
    try {
      await action();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(successMsg)),
        );
        _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e')),
        );
      }
    }
  }

  Future<void> _showDetail(ChangeOrderModel co) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _CoDetailSheet(
        co: co,
        currency: _currency,
        onSubmit: co.status == 'DRAFT' ? () { Navigator.pop(context); _submit(co); } : null,
        onSendToCustomer: co.status == 'SUBMITTED' ? () { Navigator.pop(context); _sendToCustomer(co); } : null,
        onStart: co.status == 'APPROVED' ? () { Navigator.pop(context); _start(co); } : null,
        onComplete: co.status == 'IN_PROGRESS' ? () { Navigator.pop(context); _complete(co); } : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Change Orders'),
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
                  child: _cos.isEmpty
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32),
                            child: Text(
                              'No change orders found.',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _cos.length,
                          itemBuilder: (_, i) => _CoCard(
                            co: _cos[i],
                            currency: _currency,
                            onTap: () => _showDetail(_cos[i]),
                          ),
                        ),
                ),
    );
  }
}

// ─── Widgets ─────────────────────────────────────────────────────────────────

class _CoCard extends StatelessWidget {
  final ChangeOrderModel co;
  final NumberFormat currency;
  final VoidCallback onTap;

  const _CoCard(
      {required this.co, required this.currency, required this.onTap});

  Color _statusColor() {
    switch (co.status) {
      case 'APPROVED':
        return Colors.green;
      case 'COMPLETED':
      case 'CLOSED':
        return Colors.teal;
      case 'REJECTED':
        return Colors.red;
      case 'CUSTOMER_REVIEW':
        return Colors.blue;
      case 'SUBMITTED':
        return Colors.indigo;
      case 'IN_PROGRESS':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _statusColor();
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 4,
                height: 60,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(co.title,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 14),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: color),
                          ),
                          child: Text(co.status.replaceAll('_', ' '),
                              style: TextStyle(
                                  color: color,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(co.referenceNumber,
                        style: TextStyle(
                            color: Colors.grey[600], fontSize: 12)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _CoTypeBadge(coType: co.coType),
                        const Spacer(),
                        Text(
                          co.isReduction
                              ? '- ${currency.format(co.netAmountInclGst)}'
                              : '+ ${currency.format(co.netAmountInclGst)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: co.isReduction
                                ? Colors.orange[700]
                                : Colors.green[700],
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}

class _CoTypeBadge extends StatelessWidget {
  final String coType;
  const _CoTypeBadge({required this.coType});

  @override
  Widget build(BuildContext context) {
    final label = coType.replaceAll('_', ' ');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label,
          style: TextStyle(color: Colors.grey[700], fontSize: 10)),
    );
  }
}

class _CoDetailSheet extends StatelessWidget {
  final ChangeOrderModel co;
  final NumberFormat currency;
  final VoidCallback? onSubmit;
  final VoidCallback? onSendToCustomer;
  final VoidCallback? onStart;
  final VoidCallback? onComplete;

  const _CoDetailSheet({
    required this.co,
    required this.currency,
    this.onSubmit,
    this.onSendToCustomer,
    this.onStart,
    this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('dd MMM yyyy');
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      maxChildSize: 0.95,
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
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(co.title,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                ),
                _CoTypeBadge(coType: co.coType),
              ],
            ),
            Text(co.referenceNumber,
                style:
                    TextStyle(color: Colors.grey[600], fontSize: 12)),
            const SizedBox(height: 12),
            if (co.description != null) ...[
              Text('Description',
                  style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(co.description!, style: const TextStyle(fontSize: 13)),
              const SizedBox(height: 12),
            ],
            if (co.justification != null) ...[
              Text('Justification',
                  style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(co.justification!, style: const TextStyle(fontSize: 13)),
              const SizedBox(height: 12),
            ],
            const Divider(),
            _AmountRow('Amount (excl. GST)',
                currency.format(co.netAmountExGst)),
            _AmountRow('GST', currency.format(co.gstAmount)),
            _AmountRow(
              co.isReduction ? 'Total Reduction' : 'Total Addition',
              (co.isReduction ? '- ' : '+ ') +
                  currency.format(co.netAmountInclGst),
              bold: true,
              color: co.isReduction ? Colors.orange[700] : Colors.green[700],
            ),
            const Divider(),
            if (co.submittedAt != null)
              _AmountRow('Submitted', df.format(co.submittedAt!)),
            if (co.approvedAt != null)
              _AmountRow('Approved', df.format(co.approvedAt!),
                  color: Colors.green),
            if (co.rejectedAt != null)
              _AmountRow('Rejected', df.format(co.rejectedAt!),
                  color: Colors.red),
            if (co.rejectionReason != null) ...[
              const SizedBox(height: 4),
              Text('Rejection reason: ${co.rejectionReason}',
                  style: TextStyle(
                      color: Colors.red[700], fontSize: 12)),
            ],
            if (co.lineItems.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text('Line Items',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 8),
              ...co.lineItems.map((li) => _LineItemRow(li, currency)),
            ],
            const SizedBox(height: 20),
            if (onSubmit != null)
              _ActionButton(
                  label: 'Submit for Internal Review',
                  icon: Icons.send,
                  color: AppTheme.primaryColor,
                  onPressed: onSubmit!),
            if (onSendToCustomer != null)
              _ActionButton(
                  label: 'Send to Customer',
                  icon: Icons.person_pin_outlined,
                  color: Colors.indigo,
                  onPressed: onSendToCustomer!),
            if (onStart != null)
              _ActionButton(
                  label: 'Start Work',
                  icon: Icons.play_circle_outline,
                  color: Colors.orange,
                  onPressed: onStart!),
            if (onComplete != null)
              _ActionButton(
                  label: 'Mark Complete',
                  icon: Icons.check_circle_outline,
                  color: Colors.teal,
                  onPressed: onComplete!),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _AmountRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  final Color? color;

  const _AmountRow(this.label, this.value,
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

class _LineItemRow extends StatelessWidget {
  final Map<String, dynamic> li;
  final NumberFormat currency;

  const _LineItemRow(this.li, this.currency);

  @override
  Widget build(BuildContext context) {
    final desc = li['description']?.toString() ?? 'Item';
    final amount = li['lineAmountExGst'];
    final amtStr = amount != null
        ? currency.format(
            amount is num ? amount.toDouble() : double.tryParse(amount.toString()) ?? 0)
        : '-';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.circle, size: 6, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(
            child: Text(desc, style: const TextStyle(fontSize: 13)),
          ),
          Text(amtStr,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
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
