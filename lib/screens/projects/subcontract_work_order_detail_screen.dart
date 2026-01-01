import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/subcontract_provider.dart';
import '../../models/subcontract_models.dart';
import '../../theme/app_theme.dart';
import 'record_subcontract_payment_screen.dart';

/// Subcontract Work Order Detail Screen
/// Shows detailed view with tabs for measurements and payments
class SubcontractWorkOrderDetailScreen extends StatefulWidget {
  final int workOrderId;

  const SubcontractWorkOrderDetailScreen({
    Key? key,
    required this.workOrderId,
  }) : super(key: key);

  @override
  State<SubcontractWorkOrderDetailScreen> createState() => _SubcontractWorkOrderDetailScreenState();
}

class _SubcontractWorkOrderDetailScreenState extends State<SubcontractWorkOrderDetailScreen>
    with SingleTickerProviderStateMixin {
  final _currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
  final _dateFormat = DateFormat('dd MMM yyyy');
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<SubcontractProvider>();
      provider.loadWorkOrderSummary(widget.workOrderId);
      provider.loadWorkOrderMeasurements(widget.workOrderId);
      provider.loadWorkOrderPayments(widget.workOrderId);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Work Order Details', style: TextStyle(color: Colors.white)),
        backgroundColor: AppTheme.deepSlate,
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          indicatorColor: AppTheme.coralRed,
          tabs: const [
            Tab(text: 'Details'),
            Tab(text: 'Measurements'),
            Tab(text: 'Payments'),
          ],
        ),
      ),
      body: Consumer<SubcontractProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.currentSummary == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final summary = provider.currentSummary;
          if (summary == null) {
            return const Center(child: Text('Work order not found'));
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildDetailsTab(summary),
              _buildMeasurementsTab(provider),
              _buildPaymentsTab(provider),
            ],
          );
        },
      ),
      floatingActionButton: ValueListenableBuilder(
        valueListenable: _tabController.animation!,
        builder: (context, value, child) {
          if (_tabController.index == 2) { // Payments Tab
            return FloatingActionButton.extended(
              onPressed: () {
                final summary = context.read<SubcontractProvider>().currentSummary;
                if (summary != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RecordSubcontractPaymentScreen(
                        workOrderId: widget.workOrderId,
                        balanceDue: summary.balanceDue,
                      ),
                    ),
                  ).then((_) {
                    // Refresh data
                    final p = context.read<SubcontractProvider>();
                    p.loadWorkOrderPayments(widget.workOrderId);
                    p.loadWorkOrderSummary(widget.workOrderId);
                  });
                }
              },
              label: const Text('Record Payment'),
              icon: const Icon(Icons.payment),
              backgroundColor: AppTheme.coralRed,
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildDetailsTab(SubcontractSummary summary) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Financial Summary Cards
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Contract Amount',
                  _currencyFormat.format(summary.totalContractAmount),
                  AppTheme.deepSlate,
                  Icons.description,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Total Paid',
                  _currencyFormat.format(summary.totalPaid),
                  AppTheme.tealAccent,
                  Icons.payment,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Balance Due',
                  _currencyFormat.format(summary.balanceDue),
                  summary.balanceDue > 0 ? AppTheme.amber : Colors.green,
                  Icons.account_balance_wallet,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'TDS Deducted',
                  _currencyFormat.format(summary.totalTds),
                  Colors.grey,
                  Icons.calculate,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),
          const Divider(),

          // Work Order Details
          const SizedBox(height: 16),
          _buildDetailRow('Work Order', summary.workOrderNumber),
          _buildDetailRow('Status', summary.status),
          _buildDetailRow('Vendor', summary.vendorName ?? 'N/A'),
          _buildDetailRow('Project', summary.projectName ?? 'N/A'),
          _buildDetailRow('Measurement Basis', summary.measurementBasis),

          const SizedBox(height: 16),
          const Text(
            'Scope of Work',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(summary.scopeDescription),

          const SizedBox(height: 24),

          // Progress (for unit-rate)
          if (summary.measurementBasis == 'UNIT_RATE' && summary.percentageCompleted != null) ...[
            const Text(
              'Progress',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: (summary.percentageCompleted ?? 0) / 100,
              backgroundColor: Colors.grey[200],
              color: AppTheme.tealAccent,
              minHeight: 8,
            ),
            const SizedBox(height: 8),
            Text(
              '${summary.percentageCompleted?.toStringAsFixed(1)}% Complete',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('${summary.approvedMeasurements ?? 0} of ${summary.totalMeasurements ?? 0} measurements approved'),
          ],
        ],
      ),
    );
  }

  Widget _buildMeasurementsTab(SubcontractProvider provider) {
    final measurements = provider.measurements;

    return Column(
      children: [
        if (measurements.isEmpty)
          const Expanded(
            child: Center(child: Text('No measurements recorded')),
          )
        else
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: measurements.length,
              itemBuilder: (context, index) {
                final measurement = measurements[index];
                return _buildMeasurementCard(measurement);
              },
            ),
          ),
      ],
    );
  }

  Widget _buildPaymentsTab(SubcontractProvider provider) {
    final payments = provider.payments;

    return Column(
      children: [
        if (payments.isEmpty)
          const Expanded(
            child: Center(child: Text('No payments recorded')),
          )
        else
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: payments.length,
              itemBuilder: (context, index) {
                final payment = payments[index];
                return _buildPaymentCard(payment);
              },
            ),
          ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, Color color, IconData icon) {
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
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMeasurementCard(SubcontractMeasurement measurement) {
    final statusColor = measurement.isPending
        ? AppTheme.amber
        : measurement.isApproved
            ? AppTheme.tealAccent
            : AppTheme.coralRed;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  measurement.billNumber ?? 'Measurement',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    measurement.statusDisplay,
                    style: TextStyle(color: statusColor, fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(measurement.description),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  '${measurement.quantity} ${measurement.unit} × ₹${measurement.rate}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                const Spacer(),
                Text(
                  _currencyFormat.format(measurement.amount),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            if (measurement.measuredByName != null) ...[
              const SizedBox(height: 4),
              Text(
                'Measured by: ${measurement.measuredByName}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentCard(SubcontractPayment payment) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _dateFormat.format(payment.paymentDate),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.deepSlate.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    payment.paymentModeDisplay,
                    style: TextStyle(color: AppTheme.deepSlate, fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildPaymentRow('Gross Amount', payment.grossAmount),
            _buildPaymentRow('TDS (${payment.tdsPercentage}%)', -payment.tdsAmount),
            if (payment.otherDeductions != null && payment.otherDeductions! > 0)
              _buildPaymentRow('Other Deductions', -(payment.otherDeductions!)),
            const Divider(),
            _buildPaymentRow('Net Paid', payment.netAmount, isBold: true),
            if (payment.transactionReference != null) ...[
              const SizedBox(height: 8),
              Text(
                'Ref: ${payment.transactionReference}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentRow(String label, double amount, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: isBold ? null : Colors.grey[600],
            ),
          ),
          Text(
            _currencyFormat.format(amount),
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: amount < 0 ? AppTheme.coralRed : null,
            ),
          ),
        ],
      ),
    );
  }
}
