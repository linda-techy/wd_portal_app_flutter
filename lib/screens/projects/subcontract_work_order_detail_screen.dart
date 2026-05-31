import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:admin/utils/error_handler.dart';
import '../../services/subcontract_service.dart';
import '../../services/api_service.dart';
import '../../models/subcontract_models.dart';
import '../../theme/app_theme.dart';
import '../../config/app_config.dart';
import 'record_subcontract_payment_screen.dart';

/// Subcontract Work Order Detail Screen
/// Shows detailed view with tabs for details, measurements, and payments
class SubcontractWorkOrderDetailScreen extends StatefulWidget {
  final int workOrderId;

  const SubcontractWorkOrderDetailScreen({
    super.key,
    required this.workOrderId,
  });

  @override
  State<SubcontractWorkOrderDetailScreen> createState() =>
      _SubcontractWorkOrderDetailScreenState();
}

class _SubcontractWorkOrderDetailScreenState
    extends State<SubcontractWorkOrderDetailScreen>
    with SingleTickerProviderStateMixin {
  final _currencyFormat =
      NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
  final _dateFormat = DateFormat('dd MMM yyyy');
  late TabController _tabController;
  final SubcontractService _service = SubcontractService(ApiService());

  SubcontractSummary? _summary;
  List<SubcontractMeasurement> _measurements = [];
  List<SubcontractPayment> _payments = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        _service.getWorkOrderSummary(widget.workOrderId),
        _service.getWorkOrderMeasurements(widget.workOrderId),
        _service.getWorkOrderPayments(widget.workOrderId),
      ]);

      if (!mounted) return;
      setState(() {
        _summary = results[0] as SubcontractSummary;
        _measurements = results[1] as List<SubcontractMeasurement>;
        _payments = results[2] as List<SubcontractPayment>;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _issueWorkOrder() async {
    try {
      await _service.issueWorkOrder(widget.workOrderId);
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Work order issued'),
              backgroundColor: AppTheme.successGreen),
        );
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showErrorSnackBar(context, e);
      }
    }
  }

  Future<void> _completeWorkOrder() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: AppConfig.datePickerFirstDate,
      lastDate: DateTime(2100),
    );
    if (date == null) return;

    try {
      await _service.completeWorkOrder(widget.workOrderId, date);
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Work order completed'),
              backgroundColor: AppTheme.successGreen),
        );
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showErrorSnackBar(context, e);
      }
    }
  }

  Future<void> _terminateWorkOrder() async {
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Terminate Work Order'),
        content: TextField(
          controller: controller,
          decoration:
              const InputDecoration(labelText: 'Reason for termination'),
          maxLines: 3,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            style:
                ElevatedButton.styleFrom(backgroundColor: AppTheme.coralRed),
            child:
                const Text('Terminate', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (reason == null || reason.isEmpty) return;

    try {
      await _service.terminateWorkOrder(widget.workOrderId, reason);
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Work order terminated')),
        );
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showErrorSnackBar(context, e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Work Order Details',
            style: TextStyle(color: Colors.white)),
        backgroundColor: AppTheme.deepSlate,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: _buildActions(),
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 48, color: Colors.red),
                      const SizedBox(height: 16),
                      Text('Error loading data',
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Text(_error!, style: const TextStyle(color: Colors.grey)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                          onPressed: _loadData, child: const Text('Retry')),
                    ],
                  ),
                )
              : _summary == null
                  ? const Center(child: Text('Work order not found'))
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildDetailsTab(_summary!),
                        _buildMeasurementsTab(),
                        _buildPaymentsTab(),
                      ],
                    ),
      floatingActionButton: _buildFab(),
    );
  }

  List<Widget> _buildActions() {
    if (_summary == null) return [];
    final status = _summary!.status;

    return [
      PopupMenuButton<String>(
        icon: const Icon(Icons.more_vert, color: Colors.white),
        onSelected: (action) {
          switch (action) {
            case 'issue':
              _issueWorkOrder();
              break;
            case 'complete':
              _completeWorkOrder();
              break;
            case 'terminate':
              _terminateWorkOrder();
              break;
            case 'edit':
              _showEditDialog();
              break;
            case 'delete':
              _confirmDelete();
              break;
          }
        },
        itemBuilder: (ctx) => [
          if (status == 'DRAFT' || status == 'ISSUED')
            const PopupMenuItem(
                value: 'edit',
                child: ListTile(
                  leading: Icon(Icons.edit),
                  title: Text('Edit Work Order'),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                )),
          if (status == 'DRAFT')
            const PopupMenuItem(
                value: 'issue', child: Text('Issue Work Order')),
          if (status == 'ISSUED' || status == 'IN_PROGRESS')
            const PopupMenuItem(
                value: 'complete', child: Text('Mark Complete')),
          if (status == 'DRAFT')
            const PopupMenuItem(
                value: 'delete',
                child: ListTile(
                  leading: Icon(Icons.delete, color: Colors.red),
                  title: Text('Delete', style: TextStyle(color: Colors.red)),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                )),
          if (status != 'COMPLETED' && status != 'TERMINATED')
            const PopupMenuItem(
                value: 'terminate',
                child:
                    Text('Terminate', style: TextStyle(color: Colors.red))),
        ],
      ),
    ];
  }

  Widget? _buildFab() {
    return ValueListenableBuilder(
      valueListenable: _tabController.animation!,
      builder: (context, value, child) {
        if (_tabController.index == 1 && _summary != null) {
          // Measurements tab
          return FloatingActionButton.extended(
            heroTag: 'measurement',
            onPressed: _showRecordMeasurementDialog,
            label: const Text('Record Measurement'),
            icon: const Icon(Icons.straighten),
            backgroundColor: AppTheme.tealAccent,
          );
        }
        if (_tabController.index == 2 && _summary != null) {
          // Payments tab
          return FloatingActionButton.extended(
            heroTag: 'payment',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => RecordSubcontractPaymentScreen(
                    workOrderId: widget.workOrderId,
                    balanceDue: _summary!.balanceDue,
                  ),
                ),
              ).then((_) => _loadData());
            },
            label: const Text('Record Payment'),
            icon: const Icon(Icons.payment),
            backgroundColor: AppTheme.coralRed,
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  // ===== DETAILS TAB =====

  Widget _buildDetailsTab(SubcontractSummary summary) {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
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

            // Status chip
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(summary.status),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    summary.status.replaceAll('_', ' '),
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),

            // Work Order Details
            _buildDetailRow('Work Order', summary.workOrderNumber),
            _buildDetailRow('Vendor', summary.vendorName ?? 'N/A'),
            _buildDetailRow('Project', summary.projectName ?? 'N/A'),
            _buildDetailRow('Measurement Basis', summary.measurementBasis),

            const SizedBox(height: 16),
            const Text(
              'Scope of Work',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Text(summary.scopeDescription),
            ),

            const SizedBox(height: 24),

            // Progress (for unit-rate)
            if (summary.measurementBasis == 'UNIT_RATE' &&
                summary.percentageCompleted != null) ...[
              const Text(
                'Progress',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (summary.percentageCompleted ?? 0) / 100,
                  backgroundColor: Colors.grey[200],
                  color: AppTheme.tealAccent,
                  minHeight: 10,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${summary.percentageCompleted?.toStringAsFixed(1)}% Complete',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                '${summary.approvedMeasurements ?? 0} of ${summary.totalMeasurements ?? 0} measurements approved',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ===== MEASUREMENTS TAB =====

  Widget _buildMeasurementsTab() {
    if (_measurements.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.straighten, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            const Text('No measurements recorded',
                style: TextStyle(fontSize: 16, color: Colors.grey)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _measurements.length,
        itemBuilder: (context, index) {
          return _buildMeasurementCard(_measurements[index]);
        },
      ),
    );
  }

  // ===== PAYMENTS TAB =====

  Widget _buildPaymentsTab() {
    if (_payments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.payment, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            const Text('No payments recorded',
                style: TextStyle(fontSize: 16, color: Colors.grey)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _payments.length,
        itemBuilder: (context, index) {
          return _buildPaymentCard(_payments[index]);
        },
      ),
    );
  }

  // ===== DIALOGS =====

  Future<void> _showRecordMeasurementDialog() async {
    final descCtrl = TextEditingController();
    final qtyCtrl = TextEditingController();
    final unitCtrl = TextEditingController();
    final rateCtrl = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Record Measurement'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: descCtrl,
                decoration: const InputDecoration(labelText: 'Description *'),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: qtyCtrl,
                      decoration: const InputDecoration(labelText: 'Quantity *'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: unitCtrl,
                      decoration: const InputDecoration(labelText: 'Unit'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: rateCtrl,
                decoration:
                    const InputDecoration(labelText: 'Rate *', prefixText: '₹ '),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (descCtrl.text.isEmpty ||
                  qtyCtrl.text.isEmpty ||
                  rateCtrl.text.isEmpty) {
                ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
                    content: Text('Fill required fields')));
                return;
              }
              try {
                final qty = double.parse(qtyCtrl.text);
                final rate = double.parse(rateCtrl.text);
                final measurement = SubcontractMeasurement(
                  workOrderId: widget.workOrderId,
                  description: descCtrl.text,
                  quantity: qty,
                  unit: unitCtrl.text.isNotEmpty ? unitCtrl.text : 'unit',
                  rate: rate,
                  amount: qty * rate,
                  status: 'PENDING',
                  measurementDate: DateTime.now(),
                );
                await _service.recordMeasurement(
                    widget.workOrderId, measurement);
                if (ctx.mounted) Navigator.pop(ctx, true);
              } catch (e) {
                if (ctx.mounted) {
                  ErrorHandler.showErrorSnackBar(ctx, e);
                }
              }
            },
            child: const Text('Record'),
          ),
        ],
      ),
    );

    if (result == true) {
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Measurement recorded'),
              backgroundColor: AppTheme.successGreen),
        );
      }
    }
  }

  // ===== EDIT / DELETE =====

  void _showEditDialog() {
    final scopeCtrl = TextEditingController(text: _summary?.scopeDescription ?? '');
    final amountCtrl = TextEditingController(
        text: _summary?.totalContractAmount.toStringAsFixed(0) ?? '');
    final termsCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Work Order'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: scopeCtrl,
                decoration: const InputDecoration(labelText: 'Scope of Work'),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amountCtrl,
                decoration: const InputDecoration(
                    labelText: 'Negotiated Amount', prefixText: '\u20B9 '),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: termsCtrl,
                decoration: const InputDecoration(labelText: 'Payment Terms'),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                final updates = <String, dynamic>{};
                if (scopeCtrl.text.isNotEmpty) {
                  updates['scopeDescription'] = scopeCtrl.text;
                }
                final amt = double.tryParse(amountCtrl.text);
                if (amt != null) updates['negotiatedAmount'] = amt;
                if (termsCtrl.text.isNotEmpty) {
                  updates['paymentTerms'] = termsCtrl.text;
                }
                await _service.updateWorkOrder(widget.workOrderId, updates);
                await _loadData();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Work order updated'),
                        backgroundColor: AppTheme.successGreen),
                  );
                }
              } catch (e) {
                if (mounted) ErrorHandler.showErrorSnackBar(context, e);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Work Order'),
        content: const Text(
            'This will permanently delete this draft work order. Continue?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.coralRed),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await _service.deleteWorkOrder(widget.workOrderId);
                if (mounted) Navigator.pop(context);
              } catch (e) {
                if (mounted) ErrorHandler.showErrorSnackBar(context, e);
              }
            },
            child:
                const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ===== MEASUREMENT APPROVAL =====

  Future<void> _approveMeasurement(int measurementId) async {
    try {
      await _service.approveMeasurementPatch(measurementId);
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Measurement approved'),
              backgroundColor: AppTheme.successGreen),
        );
      }
    } catch (e) {
      if (mounted) ErrorHandler.showErrorSnackBar(context, e);
    }
  }

  void _showRejectDialog(int measurementId) {
    final reasonCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject Measurement'),
        content: TextField(
          controller: reasonCtrl,
          decoration: const InputDecoration(
              labelText: 'Rejection Reason', hintText: 'Required'),
          maxLines: 3,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.coralRed),
            onPressed: () async {
              if (reasonCtrl.text.trim().isEmpty) return;
              Navigator.pop(ctx);
              try {
                await _service.rejectMeasurementPatch(
                    measurementId, reasonCtrl.text.trim());
                await _loadData();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Measurement rejected')),
                  );
                }
              } catch (e) {
                if (mounted) ErrorHandler.showErrorSnackBar(context, e);
              }
            },
            child:
                const Text('Reject', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ===== CARD BUILDERS =====

  Widget _buildStatCard(
      String label, String value, Color color, IconData icon) {
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
                Expanded(
                  child: Text(
                    measurement.billNumber ?? 'Measurement',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    measurement.statusDisplay,
                    style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold),
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
            const SizedBox(height: 4),
            Text(
              'Date: ${_dateFormat.format(measurement.measurementDate)}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            if (measurement.isPending) ...[
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    icon: const Icon(Icons.close, color: Colors.red, size: 18),
                    label: const Text('Reject',
                        style: TextStyle(color: Colors.red)),
                    onPressed: () => _showRejectDialog(measurement.id!),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Approve'),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.tealAccent),
                    onPressed: () => _approveMeasurement(measurement.id!),
                  ),
                ],
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.deepSlate.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    payment.paymentModeDisplay,
                    style:
                        const TextStyle(color: AppTheme.deepSlate, fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildPaymentRow('Gross Amount', payment.grossAmount),
            _buildPaymentRow(
                'TDS (${payment.tdsPercentage}%)', -payment.tdsAmount),
            if (payment.otherDeductions != null &&
                payment.otherDeductions! > 0)
              _buildPaymentRow(
                  'Other Deductions', -(payment.otherDeductions!)),
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

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'DRAFT':
        return Colors.grey;
      case 'ISSUED':
        return AppTheme.primaryBlue;
      case 'IN_PROGRESS':
        return AppTheme.amber;
      case 'COMPLETED':
        return AppTheme.successGreen;
      case 'TERMINATED':
        return AppTheme.coralRed;
      default:
        return Colors.grey;
    }
  }
}
