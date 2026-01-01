import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/vendor_payment_provider.dart';
import '../../theme/app_theme.dart';

/// Accounts Payable Dashboard
/// Shows AP aging, vendor outstanding, and overdue invoices
class AccountsPayableDashboard extends StatefulWidget {
  const AccountsPayableDashboard({Key? key}) : super(key: key);

  @override
  State<AccountsPayableDashboard> createState() => _AccountsPayableDashboardState();
}

class _AccountsPayableDashboardState extends State<AccountsPayableDashboard> {
  final _currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VendorPaymentProvider>().loadDashboardData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Accounts Payable', style: TextStyle(color: Colors.white)),
        backgroundColor: AppTheme.deepSlate,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () => context.read<VendorPaymentProvider>().loadDashboardData(),
          ),
        ],
      ),
      body: Consumer<VendorPaymentProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.apAging == null) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: ${provider.error}'),
                  ElevatedButton(
                    onPressed: () => provider.loadDashboardData(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => provider.loadDashboardData(),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // AP Aging Summary Cards
                  _buildAgingSummary(provider),
                  const SizedBox(height: 24),

                  // Aging Breakdown Chart
                  _buildAgingChart(provider),
                  const SizedBox(height: 24),

                  // Overdue Invoices Alert
                  if (provider.hasOverduePayments) _buildOverdueAlert(provider),
                  if (provider.hasOverduePayments) const SizedBox(height: 24),

                  // Vendor Outstanding Table
                  _buildVendorOutstandingSection(provider),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAgingSummary(VendorPaymentProvider provider) {
    final aging = provider.apAging;
    if (aging == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'AP Aging Summary',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.deepSlate,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                'Total Outstanding',
                _currencyFormat.format(aging.totalOutstanding),
                AppTheme.deepSlate,
                Icons.account_balance_wallet,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                'Overdue',
                _currencyFormat.format(aging.overdue),
                AppTheme.coralRed,
                Icons.warning,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                '0-30 Days',
                _currencyFormat.format(aging.due_0_30_days),
                AppTheme.tealAccent,
                Icons.schedule,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                '31-60 Days',
                _currencyFormat.format(aging.due_31_60_days),
                AppTheme.amber,
                Icons.access_time,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryCard(String label, String value, Color color, IconData icon) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAgingChart(VendorPaymentProvider provider) {
    final aging = provider.apAging;
    if (aging == null) return const SizedBox.shrink();

    final total = aging.totalOutstanding;
    if (total == 0) return const SizedBox.shrink();

    final current = (aging.due_0_30_days / total) * 100;
    final due = (aging.due_31_60_days / total) * 100;
    final overdue = (aging.overdue / total) * 100;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Aging Breakdown',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            // Simple bar chart representation
            Column(
              children: [
                _buildAgingBar('0-30 Days', current, AppTheme.tealAccent),
                const SizedBox(height: 8),
                _buildAgingBar('31-60 Days', due, AppTheme.amber),
                const SizedBox(height: 8),
                _buildAgingBar('Overdue (>60)', overdue, AppTheme.coralRed),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAgingBar(String label, double percentage, Color color) {
    return Row(
      children: [
        SizedBox(
          width: 100,
          child: Text(label, style: const TextStyle(fontSize: 12)),
        ),
        Expanded(
          child: Stack(
            children: [
              Container(
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              FractionallySizedBox(
                widthFactor: percentage / 100,
                child: Container(
                  height: 24,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 50,
          child: Text(
            '${percentage.toStringAsFixed(1)}%',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildOverdueAlert(VendorPaymentProvider provider) {
    return Card(
      color: AppTheme.coralRed.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.warning, color: AppTheme.coralRed),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${provider.overdueInvoiceCount} Overdue Invoices',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.coralRed,
                    ),
                  ),
                  Text(
                    'Total: ${_currencyFormat.format(provider.overdueAmount)}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: () {
                // Navigate to overdue invoices
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.coralRed,
              ),
              child: const Text('View'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVendorOutstandingSection(VendorPaymentProvider provider) {
    final vendors = provider.vendorOutstanding;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Vendor Outstanding',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.deepSlate,
              ),
            ),
            Text(
              '${vendors.length} vendors',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (vendors.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: Text('No outstanding payments'),
              ),
            ),
          )
        else
          ...vendors.take(10).map((vendor) => _buildVendorCard(vendor)),
      ],
    );
  }

  Widget _buildVendorCard(vendor) {
    final isOverdue = vendor.hasOverduePayments;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isOverdue ? AppTheme.coralRed : AppTheme.tealAccent,
          child: Icon(
            isOverdue ? Icons.warning : Icons.business,
            color: Colors.white,
          ),
        ),
        title: Text(
          vendor.vendorName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${vendor.totalInvoices ?? 0} invoices'),
            if (isOverdue)
              Text(
                '${vendor.overdueInvoiceCount} overdue',
                style: TextStyle(color: AppTheme.coralRed, fontSize: 12),
              ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              _currencyFormat.format(vendor.totalOutstanding),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isOverdue ? AppTheme.coralRed : AppTheme.deepSlate,
              ),
            ),
            if (isOverdue)
              Text(
                _currencyFormat.format(vendor.overdueAmount ?? 0),
                style: TextStyle(fontSize: 12, color: AppTheme.coralRed),
              ),
          ],
        ),
        onTap: () {
          // Navigate to vendor detail
        },
      ),
    );
  }
}
