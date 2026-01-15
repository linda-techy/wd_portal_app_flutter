import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:admin/models/payment_models.dart';
import 'package:admin/services/payment_service.dart';
import 'package:admin/theme/app_theme.dart';
import 'package:admin/utils/motion_toast.dart';
import 'package:admin/screens/payments/payment_history_screen.dart';

class PaymentsDashboardScreen extends StatefulWidget {
  const PaymentsDashboardScreen({super.key});

  @override
  State<PaymentsDashboardScreen> createState() => _PaymentsDashboardScreenState();
}

class _PaymentsDashboardScreenState extends State<PaymentsDashboardScreen> {
  final PaymentService _paymentService = PaymentService();
  final _currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
  
  List<DesignPackagePayment> _payments = [];
  bool _isLoading = true;
  String? _errorMessage;
  bool _showPendingOnly = true;
  int _pageSize = 10;

  int _currentPage = 0;
  int _totalPages = 0;
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _loadPayments();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _currentPage = 0;
        });
        _loadPayments();
      }
    });
  }

  Future<void> _loadPayments() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = _showPendingOnly
          ? await _paymentService.getPendingPayments(
              page: _currentPage,
              size: _pageSize,
              search: _searchController.text,
            )
          : await _paymentService.getAllPayments(
              page: _currentPage,
              size: _pageSize,
              search: _searchController.text,
            );
      
      if (mounted) {
        setState(() {
          _payments = result['content'] as List<DesignPackagePayment>;
          _totalPages = result['totalPages'] as int;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.payments_outlined, color: AppTheme.primaryBlue, size: 28),
              const SizedBox(width: 12),
              Text(
                'Payments Dashboard',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              // Search Bar
              SizedBox(
                width: 300,
                child: TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'Search payments...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: AppTheme.borderLight),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    filled: true,
                    fillColor: AppTheme.background,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              _buildFilterChip('Pending', _showPendingOnly, () {
                setState(() {
                  _showPendingOnly = true;
                  _currentPage = 0;
                });
                _loadPayments();
              }),
              const SizedBox(width: 8),
              _buildFilterChip('All', !_showPendingOnly, () {
                setState(() {
                  _showPendingOnly = false;
                  _currentPage = 0;
                });
                _loadPayments();
              }),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const PaymentHistoryScreen()),
                ),
                icon: const Icon(Icons.history, size: 18),
                label: const Text('View Ledger'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.walldotGold,
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _loadPayments,
                icon: const Icon(Icons.refresh),
                tooltip: 'Refresh',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool selected, VoidCallback onTap) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: AppTheme.primaryBlue.withOpacity(0.2),
      checkmarkColor: AppTheme.primaryBlue,
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: AppTheme.statusError),
            const SizedBox(height: 16),
            Text('Error: $_errorMessage'),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _loadPayments, child: const Text('Retry')),
          ],
        ),
      );
    }

    if (_payments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 64, color: AppTheme.statusSuccess),
            const SizedBox(height: 16),
            Text(
              _showPendingOnly ? 'No pending payments!' : 'No payments found',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: _buildPaymentsTable(),
          ),
        ),
        _buildPaginationControls(),
      ],
    );
  }

  Widget _buildPaginationControls() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: Border(top: BorderSide(color: AppTheme.borderLight)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            'Page ${_currentPage + 1} of $_totalPages',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(width: 16),
          IconButton(
            onPressed: _currentPage > 0
                ? () {
                    setState(() => _currentPage--);
                    _loadPayments();
                  }
                : null,
            icon: const Icon(Icons.chevron_left),
          ),
          IconButton(
            onPressed: _currentPage < _totalPages - 1
                ? () {
                    setState(() => _currentPage++);
                    _loadPayments();
                  }
                : null,
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentsTable() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(AppTheme.surfaceElevated),
          columns: const [
            DataColumn(label: Text('Customer & Project')),
            DataColumn(label: Text('Package')),
            DataColumn(label: Text('Type')),
            DataColumn(label: Text('Total')),
            DataColumn(label: Text('Paid')),
            DataColumn(label: Text('Balance')),
            DataColumn(label: Text('Status')),
            DataColumn(label: Text('Actions')),
          ],
          rows: _payments.map((payment) => _buildPaymentRow(payment)).toList(),
        ),
      ),
    );
  }

  DataRow _buildPaymentRow(DesignPackagePayment payment) {
    return DataRow(
      cells: [
        DataCell(Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              payment.customerName ?? 'Unknown Customer',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              payment.projectName ?? 'Project #${payment.projectId}',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
            ),
          ],
        )),
        DataCell(Text(payment.packageName)),
        DataCell(Text(payment.paymentType == 'FULL' ? 'Full' : 'Installment')),
        DataCell(Text(_currencyFormat.format(payment.totalAmount))),
        DataCell(Text(
          _currencyFormat.format(payment.totalPaid),
          style: TextStyle(color: AppTheme.statusSuccess),
        )),
        DataCell(Text(
          _currencyFormat.format(payment.balanceDue),
          style: TextStyle(
            color: payment.balanceDue > 0 ? AppTheme.statusError : AppTheme.statusSuccess,
            fontWeight: FontWeight.bold,
          ),
        )),
        DataCell(_buildStatusChip(payment.status)),
        DataCell(Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.add_card, size: 20, color: AppTheme.primaryBlue),
              onPressed: () => _showRecordPaymentDialog(payment),
              tooltip: 'Record Payment',
            ),
            IconButton(
              icon: const Icon(Icons.visibility, size: 20),
              onPressed: () => _showPaymentDetails(payment),
              tooltip: 'View Details',
            ),
          ],
        )),
      ],
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status) {
      case 'PAID':
        color = AppTheme.statusSuccess;
        break;
      case 'PARTIAL':
        color = AppTheme.safetyOrange;
        break;
      default:
        color = AppTheme.textSecondary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status,
        style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 11),
      ),
    );
  }

  void _showPaymentDetails(DesignPackagePayment payment) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 500,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Payment Details',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 8),
              _buildDetailRow('Customer', payment.customerName ?? 'N/A'),
              _buildDetailRow('Project', payment.projectName ?? 'N/A'),
              _buildDetailRow('Project ID', '#${payment.projectId}'),
              _buildDetailRow('Package', payment.packageName),
              _buildDetailRow('Payment Type', payment.paymentType),
              _buildDetailRow('Total Amount', _currencyFormat.format(payment.totalAmount)),
              _buildDetailRow('Paid', _currencyFormat.format(payment.totalPaid)),
              _buildDetailRow('Balance', _currencyFormat.format(payment.balanceDue)),
              const SizedBox(height: 16),
              Text('Installments', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              ...payment.schedules.map((s) => ListTile(
                dense: true,
                leading: CircleAvatar(
                  radius: 12,
                  backgroundColor: s.status == 'PAID' ? AppTheme.statusSuccess : AppTheme.primaryBlue,
                  child: s.status == 'PAID'
                      ? const Icon(Icons.check, size: 14, color: Colors.white)
                      : Text('${s.installmentNumber}', style: const TextStyle(color: Colors.white, fontSize: 11)),
                ),
                title: Text(s.description),
                subtitle: Text(_currencyFormat.format(s.amount)),
                trailing: _buildStatusChip(s.status),
              )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: AppTheme.textSecondary)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  void _showRecordPaymentDialog(DesignPackagePayment payment) {
    final amountController = TextEditingController();
    final refController = TextEditingController();
    final notesController = TextEditingController();
    PaymentScheduleItem? selectedSchedule;
    String selectedMethod = 'BANK_TRANSFER';

    // Default to the first pending schedule
    try {
      selectedSchedule = payment.schedules.firstWhere((s) => s.status != 'PAID');
      amountController.text = selectedSchedule.remainingAmount.toString();
    } catch (e) {
      // All paid
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            width: 500,
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.add_card, color: AppTheme.primaryBlue),
                    const SizedBox(width: 8),
                    Text(
                      'Record Payment',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                Text(
                  '${payment.customerName} - ${payment.projectName}',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                ),
                const Divider(),
                const SizedBox(height: 16),
                const Text('Select Installment', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                DropdownButtonFormField<PaymentScheduleItem>(
                  value: selectedSchedule,
                  isExpanded: true,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  items: payment.schedules
                      .map((s) => DropdownMenuItem(
                            value: s,
                            child: Text(
                                '${s.description} (${_currencyFormat.format(s.amount)}) - ${s.status}'),
                          ))
                      .toList(),
                  onChanged: (val) {
                    setState(() {
                      selectedSchedule = val;
                      if (val != null) {
                        amountController.text = val.remainingAmount.toString();
                      }
                    });
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Amount', style: TextStyle(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          TextField(
                            controller: amountController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              prefixText: '₹ ',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Method', style: TextStyle(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value: selectedMethod,
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'BANK_TRANSFER', child: Text('Bank Transfer')),
                              DropdownMenuItem(value: 'UPI', child: Text('UPI')),
                              DropdownMenuItem(value: 'CHEQUE', child: Text('Cheque')),
                              DropdownMenuItem(value: 'CASH', child: Text('Cash')),
                            ],
                            onChanged: (val) => setState(() => selectedMethod = val!),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text('Reference Number', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextField(
                  controller: refController,
                  decoration: InputDecoration(
                    hintText: 'Transaction ID / Cheque No.',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Notes', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextField(
                  controller: notesController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: 'Optional notes...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (selectedSchedule == null) return;
                      final amount = double.tryParse(amountController.text) ?? 0;
                      if (amount <= 0) return;

                      try {
                        await _paymentService.recordTransaction(
                          selectedSchedule!.id,
                          RecordTransactionRequest(
                            amount: amount,
                            paymentMethod: selectedMethod,
                            referenceNumber: refController.text,
                            paymentDate: DateTime.now(),
                            notes: notesController.text,
                          ),
                        );
                        if (mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Payment recorded successfully')),
                          );
                          _loadPayments();
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: ${e.toString()}')),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Confirm Payment', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

