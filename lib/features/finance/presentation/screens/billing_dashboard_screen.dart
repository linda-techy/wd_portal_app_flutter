import 'package:flutter/material.dart';
import 'package:admin/constants.dart';
import 'package:admin/features/finance/presentation/screens/milestone_list_screen.dart';
import 'package:admin/features/finance/data/models/billing_models.dart';
import 'package:admin/models/finance_models.dart';
import 'package:admin/services/finance_service.dart';
import 'package:intl/intl.dart';

class BillingDashboardScreen extends StatefulWidget {
  final int projectId;

  const BillingDashboardScreen({super.key, required this.projectId});

  @override
  State<BillingDashboardScreen> createState() => _BillingDashboardScreenState();
}

class _BillingDashboardScreenState extends State<BillingDashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          labelColor: Theme.of(context).primaryColor,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'Milestones'),
            Tab(text: 'Invoices & Receipts'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              MilestoneListScreen(projectId: widget.projectId),
              _InvoicesReceiptsTab(projectId: widget.projectId),
            ],
          ),
        ),
      ],
    );
  }
}

class _InvoicesReceiptsTab extends StatefulWidget {
  final int projectId;
  const _InvoicesReceiptsTab({required this.projectId});

  @override
  State<_InvoicesReceiptsTab> createState() => _InvoicesReceiptsTabState();
}

class _InvoicesReceiptsTabState extends State<_InvoicesReceiptsTab> {
  final FinanceService _financeService = FinanceService();
  final _currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '\u20B9');

  List<ProjectInvoice> _invoices = [];
  List<Receipt> _receipts = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final results = await Future.wait([
        _financeService.getProjectInvoices(widget.projectId),
        _financeService.getProjectReceipts(widget.projectId),
      ]);
      setState(() {
        _invoices = results[0] as List<ProjectInvoice>;
        _receipts = results[1] as List<Receipt>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PAID': return successColor;
      case 'SENT': return infoColor;
      case 'DRAFT': return Colors.grey;
      case 'OVERDUE': return errorColor;
      default: return warningColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: errorColor),
            const SizedBox(height: 8),
            const Text('Failed to load data', style: TextStyle(color: errorColor)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _loadData, child: const Text('Retry')),
          ],
        ),
      );
    }

    final totalInvoiced = _invoices.fold<double>(0, (s, i) => s + i.totalAmount);
    final totalReceived = _receipts.fold<double>(0, (s, r) => s + r.amount);

    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary
            Row(
              children: [
                Expanded(
                  child: _buildSummaryCard('Total Invoiced', _currencyFormat.format(totalInvoiced), Icons.receipt_long, primaryColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSummaryCard('Total Received', _currencyFormat.format(totalReceived), Icons.payments, successColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSummaryCard('Outstanding', _currencyFormat.format(totalInvoiced - totalReceived), Icons.pending, warningColor),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Invoices
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Invoices', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text('${_invoices.length} total', style: const TextStyle(color: textSecondary, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 8),
            if (_invoices.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: containerBorder),
                ),
                child: const Center(child: Text('No invoices yet', style: TextStyle(color: textSecondary))),
              )
            else
              ..._invoices.map((inv) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _getStatusColor(inv.status).withOpacity(0.1),
                    child: Icon(Icons.receipt, color: _getStatusColor(inv.status), size: 20),
                  ),
                  title: Text(inv.invoiceNumber ?? 'Draft', style: const TextStyle(fontWeight: FontWeight.w500)),
                  subtitle: Text('Date: ${inv.invoiceDate}${inv.dueDate != null ? ' | Due: ${inv.dueDate}' : ''}',
                      style: const TextStyle(fontSize: 12, color: textSecondary)),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(_currencyFormat.format(inv.totalAmount), style: const TextStyle(fontWeight: FontWeight.bold)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _getStatusColor(inv.status).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(inv.status, style: TextStyle(fontSize: 11, color: _getStatusColor(inv.status))),
                      ),
                    ],
                  ),
                ),
              )),

            const SizedBox(height: 24),

            // Receipts
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Receipts', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text('${_receipts.length} total', style: const TextStyle(color: textSecondary, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 8),
            if (_receipts.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: containerBorder),
                ),
                child: const Center(child: Text('No receipts yet', style: TextStyle(color: textSecondary))),
              )
            else
              ..._receipts.map((receipt) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: successColor.withOpacity(0.1),
                    child: const Icon(Icons.payments, color: successColor, size: 20),
                  ),
                  title: Text(receipt.receiptNumber, style: const TextStyle(fontWeight: FontWeight.w500)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Date: ${DateFormat('dd MMM yyyy').format(receipt.paymentDate)}', style: const TextStyle(fontSize: 12, color: textSecondary)),
                      if (receipt.paymentMethod != null)
                        Text('Method: ${receipt.paymentMethod}', style: const TextStyle(fontSize: 12, color: textMuted)),
                      if (receipt.transactionReference != null)
                        Text('Ref: ${receipt.transactionReference}', style: const TextStyle(fontSize: 11, color: textMuted)),
                    ],
                  ),
                  trailing: Text(_currencyFormat.format(receipt.amount),
                      style: const TextStyle(fontWeight: FontWeight.bold, color: successColor, fontSize: 15)),
                ),
              )),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color), overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 11, color: color.withOpacity(0.8))),
        ],
      ),
    );
  }
}
