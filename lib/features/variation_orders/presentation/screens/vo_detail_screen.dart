import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:admin/models/variation_order_models.dart';
import 'package:admin/services/variation_order_service.dart';
import 'package:admin/theme/app_theme.dart';
import 'package:admin/utils/error_handler.dart';

class VODetailScreen extends StatefulWidget {
  final int projectId;
  final int voId;

  const VODetailScreen({
    super.key,
    required this.projectId,
    required this.voId,
  });

  @override
  State<VODetailScreen> createState() => _VODetailScreenState();
}

class _VODetailScreenState extends State<VODetailScreen>
    with SingleTickerProviderStateMixin {
  final VariationOrderService _service = VariationOrderService();
  final _currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

  VariationOrderDetail? _vo;
  bool _isLoading = true;
  bool _isActing = false;
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final vo = await _service.getDetail(widget.projectId, widget.voId);
      if (!mounted) return;
      setState(() {
        _vo = vo;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ErrorHandler.showErrorSnackBar(context, e);
    }
  }

  Future<void> _processApproval(String action) async {
    final commentCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('$action Variation Order'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Action: $action',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextField(
              controller: commentCtrl,
              decoration: const InputDecoration(
                  labelText: 'Comment', border: OutlineInputBorder()),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.coralRed),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(action, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _isActing = true);
    try {
      await _service.processApproval(
        widget.projectId,
        widget.voId,
        VOApprovalRequest(action: action, comment: commentCtrl.text),
      );
      if (!mounted) return;
      ErrorHandler.showSuccessSnackBar(context, 'Action recorded: $action');
      await _load();
    } catch (e) {
      if (!mounted) return;
      ErrorHandler.showErrorSnackBar(context, e);
    } finally {
      if (mounted) setState(() => _isActing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.deepSlate,
        foregroundColor: Colors.white,
        title: Text(_vo?.referenceNumber ?? 'Variation Order',
            style: const TextStyle(fontSize: 16)),
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: AppTheme.coralRed,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(text: 'Details'),
            Tab(text: 'Approval'),
            Tab(text: 'Payment'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _vo == null
              ? const Center(child: Text('VO not found'))
              : Stack(
                  children: [
                    TabBarView(
                      controller: _tabs,
                      children: [
                        _DetailsTab(vo: _vo!, currency: _currency),
                        _ApprovalTab(
                          vo: _vo!,
                          currency: _currency,
                          onAction: _processApproval,
                        ),
                        _PaymentTab(vo: _vo!, currency: _currency),
                      ],
                    ),
                    if (_isActing)
                      const ColoredBox(
                        color: Colors.black26,
                        child: Center(child: CircularProgressIndicator()),
                      ),
                  ],
                ),
    );
  }
}

// ---- Details Tab ----

class _DetailsTab extends StatelessWidget {
  final VariationOrderDetail vo;
  final NumberFormat currency;

  const _DetailsTab({required this.vo, required this.currency});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _card([
          _row('Reference', vo.referenceNumber),
          _row('Title', vo.title),
          _row('Type', vo.coType ?? '—'),
          _row('Category', vo.voCategory ?? '—'),
          _row('Status', vo.status),
        ]),
        const SizedBox(height: 12),
        _card([
          _row('Amount (excl. GST)',
              currency.format(vo.netAmountExGst ?? 0)),
          _row('GST Amount', currency.format(vo.gstAmount ?? 0)),
          _row('Amount (incl. GST)', currency.format(vo.netAmountInclGst),
              bold: true),
          if (vo.approvedCost != null)
            _row('Approved Cost', currency.format(vo.approvedCost!),
                valueColor: AppTheme.coralRed),
        ]),
        if (vo.description != null || vo.scopeNotes != null) ...[
          const SizedBox(height: 12),
          _card([
            if (vo.description != null)
              _textBlock('Description', vo.description!),
            if (vo.scopeNotes != null)
              _textBlock('Scope Notes', vo.scopeNotes!),
          ]),
        ],
        if (vo.rejectionReason != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Rejection Reason',
                    style: TextStyle(
                        color: Colors.red, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(vo.rejectionReason!),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _card(List<Widget> children) => Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        elevation: 1,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: children),
        ),
      );

  Widget _row(String label, String value,
      {bool bold = false, Color? valueColor}) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 140,
              child: Text(label,
                  style: TextStyle(color: Colors.grey[600], fontSize: 13)),
            ),
            Expanded(
              child: Text(value,
                  style: TextStyle(
                      fontWeight: bold ? FontWeight.bold : FontWeight.normal,
                      color: valueColor ?? AppTheme.deepSlate,
                      fontSize: 13)),
            ),
          ],
        ),
      );

  Widget _textBlock(String label, String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(text, style: const TextStyle(fontSize: 13)),
          ],
        ),
      );
}

// ---- Approval Tab ----

class _ApprovalTab extends StatelessWidget {
  final VariationOrderDetail vo;
  final NumberFormat currency;
  final void Function(String action) onAction;

  const _ApprovalTab({
    required this.vo,
    required this.currency,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final canAct =
        vo.status == 'SUBMITTED' || vo.status == 'CUSTOMER_REVIEW';
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (canAct) ...[
          const Text('Actions',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: AppTheme.deepSlate)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              _actionBtn('APPROVED', Colors.green, Icons.check_circle_outline),
              _actionBtn('REJECTED', Colors.red, Icons.cancel_outlined),
              _actionBtn('RETURNED', Colors.orange, Icons.undo),
              _actionBtn(
                  'ESCALATED', Colors.indigo, Icons.arrow_upward_outlined),
            ],
          ),
          const Divider(height: 28),
        ],
        const Text('Approval History',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: AppTheme.deepSlate)),
        const SizedBox(height: 8),
        if (vo.approvalHistory.isEmpty)
          const Text('No approval actions yet.',
              style: TextStyle(color: Colors.grey))
        else
          ...vo.approvalHistory.map((h) => _historyCard(h)),
      ],
    );
  }

  Widget _actionBtn(String action, Color color, IconData icon) => ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
            backgroundColor: color, foregroundColor: Colors.white),
        icon: Icon(icon, size: 16),
        label: Text(action, style: const TextStyle(fontSize: 12)),
        onPressed: () => onAction(action),
      );

  Widget _historyCard(ApprovalHistoryEntry h) {
    final actionColors = {
      'APPROVED': Colors.green,
      'REJECTED': Colors.red,
      'RETURNED': Colors.orange,
      'ESCALATED': Colors.indigo,
    };
    final color = actionColors[h.action] ?? Colors.grey;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.15),
          child: Icon(Icons.person_outline, color: color, size: 20),
        ),
        title: Text(h.approverName,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(h.action ?? '',
                    style: TextStyle(
                        color: color,
                        fontSize: 11,
                        fontWeight: FontWeight.w600)),
              ),
              const SizedBox(width: 6),
              Text(h.level ?? '',
                  style: const TextStyle(fontSize: 11, color: Colors.grey)),
            ]),
            if (h.comment != null && h.comment!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(h.comment!,
                    style: const TextStyle(fontSize: 12, color: Colors.black87)),
              ),
          ],
        ),
        trailing: h.actionAt != null
            ? Text(h.actionAt!.substring(0, 10),
                style: const TextStyle(fontSize: 11, color: Colors.grey))
            : null,
      ),
    );
  }
}

// ---- Payment Schedule Tab ----

class _PaymentTab extends StatelessWidget {
  final VariationOrderDetail vo;
  final NumberFormat currency;

  const _PaymentTab({required this.vo, required this.currency});

  @override
  Widget build(BuildContext context) {
    final ps = vo.paymentSchedule;
    if (ps == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.schedule_outlined, size: 52, color: Colors.grey),
              SizedBox(height: 12),
              Text('Payment schedule will be created\nonce the VO is approved.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 14)),
            ],
          ),
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _trancheCard('Advance', ps.advancePct, ps.advanceAmount,
            ps.advanceStatus, ps.advanceDueDate, ps.advancePaidDate),
        const SizedBox(height: 10),
        _trancheCard('Progress', ps.progressPct, ps.progressAmount,
            ps.progressStatus, null, ps.progressPaidDate),
        const SizedBox(height: 10),
        _trancheCard('Completion', ps.completionPct, ps.completionAmount,
            ps.completionStatus, null, ps.completionPaidDate,
            trigger: ps.completionTrigger),
      ],
    );
  }

  Widget _trancheCard(String label, int pct, double amount, String status,
      String? dueDate, String? paidDate,
      {String? trigger}) {
    final statusColors = {
      'PENDING': Colors.grey,
      'INVOICED': Colors.orange,
      'PAID': Colors.green,
      'OVERDUE': Colors.red,
    };
    final color = statusColors[status] ?? Colors.grey;
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('$label ($pct%)',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(status,
                      style: TextStyle(
                          color: color,
                          fontSize: 11,
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(currency.format(amount),
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.coralRed)),
            if (dueDate != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('Due: $dueDate',
                    style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ),
            if (paidDate != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('Paid: $paidDate',
                    style: const TextStyle(
                        fontSize: 12, color: Colors.green)),
              ),
            if (trigger != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('Trigger: $trigger',
                    style: const TextStyle(
                        fontSize: 12, color: Colors.indigo)),
              ),
          ],
        ),
      ),
    );
  }
}
