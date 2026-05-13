import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:admin/models/customer_project.dart';
import 'package:admin/models/payment_models.dart';
import 'package:admin/services/payment_service.dart';
import 'package:admin/theme/app_theme.dart';
import 'package:admin/utils/motion_toast.dart';
import 'package:admin/utils/error_handler.dart';

class ProjectPaymentsScreen extends StatefulWidget {
  final CustomerProject project;

  const ProjectPaymentsScreen({
    super.key,
    required this.project,
  });

  @override
  State<ProjectPaymentsScreen> createState() => _ProjectPaymentsScreenState();
}

class _ProjectPaymentsScreenState extends State<ProjectPaymentsScreen> {
  final PaymentService _paymentService = PaymentService();
  final _currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
  
  DesignPackagePayment? _payment;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadPaymentData();
  }

  Future<void> _loadPaymentData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final payment = await _paymentService.getDesignPaymentByProject(widget.project.id!);
      setState(() {
        _payment = payment;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        await ErrorHandler.handleApiError(context, e, defaultMessage: 'Failed to load payment data', showToast: false);
        _errorMessage = ErrorHandler.getErrorMessage(e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text('Payments - ${widget.project.name}'),
        elevation: 0,
        backgroundColor: AppTheme.surface,
      ),
      body: _buildBody(),
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
            const Icon(Icons.error_outline, size: 64, color: AppTheme.statusError),
            const SizedBox(height: 16),
            const Text('Error loading payments', style: TextStyle(color: AppTheme.textSecondary)),
            const SizedBox(height: 8),
            ElevatedButton(onPressed: _loadPaymentData, child: const Text('Retry')),
          ],
        ),
      );
    }

    if (_payment == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.payment_outlined, size: 64, color: AppTheme.textSecondary),
              const SizedBox(height: 16),
              Text(
                'No design payment for this project yet',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Create the design package payment to start billing the customer for the design phase.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textTertiary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _openCreateDialog,
                icon: const Icon(Icons.add),
                label: const Text('Create Design Payment'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadPaymentData,
      child: ListView(
        padding: const EdgeInsets.all(AppTheme.spacingMD),
        children: [
          _buildPaymentSummaryCard(),
          const SizedBox(height: AppTheme.spacingMD),
          _buildScheduleSection(),
        ],
      ),
    );
  }

  Widget _buildPaymentSummaryCard() {
    final payment = _payment!;
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingMD),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                  ),
                  child: const Icon(Icons.design_services, color: AppTheme.primaryBlue, size: 28),
                ),
                const SizedBox(width: AppTheme.spacingMD),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Design Package: ${payment.packageName}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      _buildStatusChip(payment.status),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 32),
            _buildInfoRow('Rate per sqft', _currencyFormat.format(payment.ratePerSqft)),
            _buildInfoRow('Total sqft', '${payment.totalSqft.toStringAsFixed(0)} sqft'),
            _buildInfoRow('Base Amount', _currencyFormat.format(payment.baseAmount)),
            _buildInfoRow('GST (${payment.gstPercentage}%)', _currencyFormat.format(payment.gstAmount)),
            if (payment.discountPercentage > 0)
              _buildInfoRow(
                'Discount (${payment.discountPercentage}%)', 
                '- ${_currencyFormat.format(payment.discountAmount)}',
                valueColor: AppTheme.statusSuccess,
              ),
            const Divider(height: 16),
            _buildInfoRow('Total Amount', _currencyFormat.format(payment.totalAmount), isBold: true),
            _buildInfoRow('Paid', _currencyFormat.format(payment.totalPaid), 
              valueColor: AppTheme.statusSuccess),
            _buildInfoRow('Balance Due', _currencyFormat.format(payment.balanceDue), 
              valueColor: payment.balanceDue > 0 ? AppTheme.statusError : AppTheme.statusSuccess,
              isBold: true),
            const SizedBox(height: AppTheme.spacingSM),
            Row(
              children: [
                Icon(
                  payment.paymentType == 'FULL' ? Icons.payment : Icons.event_repeat,
                  size: 16,
                  color: AppTheme.textSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  payment.paymentType == 'FULL' ? 'Pay in Full' : 'Pay in Installment',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    IconData icon;
    
    switch (status) {
      case 'PAID':
        color = AppTheme.statusSuccess;
        icon = Icons.check_circle;
        break;
      case 'PARTIAL':
        color = AppTheme.safetyOrange;
        icon = Icons.timelapse;
        break;
      default:
        color = AppTheme.textSecondary;
        icon = Icons.pending;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            status,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isBold = false, Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleSection() {
    final schedules = _payment!.schedules;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Payment Schedule',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppTheme.spacingMD),
        ...schedules.map((schedule) => _buildScheduleCard(schedule)),
      ],
    );
  }

  Widget _buildScheduleCard(PaymentScheduleItem schedule) {
    final isPaid = schedule.status == 'PAID';
    
    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingMD),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        side: BorderSide(
          color: isPaid ? AppTheme.statusSuccess.withOpacity(0.3) : AppTheme.borderLight,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingMD),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isPaid ? AppTheme.statusSuccess : AppTheme.primaryBlue,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: isPaid
                      ? const Icon(Icons.check, color: Colors.white, size: 18)
                      : Text(
                          '${schedule.installmentNumber}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                  ),
                ),
                const SizedBox(width: AppTheme.spacingMD),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        schedule.description,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _currencyFormat.format(schedule.amount),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppTheme.primaryBlue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusChip(schedule.status),
              ],
            ),
            if (!isPaid && schedule.remainingAmount > 0) ...[
              const SizedBox(height: AppTheme.spacingMD),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Remaining: ${_currencyFormat.format(schedule.remainingAmount)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.statusError,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _showRecordPaymentDialog(schedule),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Record Payment'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      textStyle: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ],
            if (schedule.transactions.isNotEmpty) ...[
              const SizedBox(height: AppTheme.spacingSM),
              const Divider(),
              const SizedBox(height: AppTheme.spacingSM),
              Text(
                'Transactions',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textSecondary,
                ),
              ),
              ...schedule.transactions.map((tx) => _buildTransactionItem(tx)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionItem(PaymentTransactionItem transaction) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.check_circle, size: 14, color: AppTheme.statusSuccess),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _currencyFormat.format(transaction.amount),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          if (transaction.paymentMethod != null)
            Text(
              transaction.paymentMethod!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
          const SizedBox(width: 8),
          Text(
            DateFormat('dd/MM/yy').format(transaction.paymentDate),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  void _showRecordPaymentDialog(PaymentScheduleItem schedule) {
    final amountController = TextEditingController(
      text: schedule.remainingAmount.toStringAsFixed(2),
    );
    final referenceController = TextEditingController();
    String? selectedMethod = 'BANK_TRANSFER';

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Record Payment'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: amountController,
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  prefixText: '₹ ',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedMethod,
                decoration: const InputDecoration(
                  labelText: 'Payment Method',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'BANK_TRANSFER', child: Text('Bank Transfer')),
                  DropdownMenuItem(value: 'UPI', child: Text('UPI')),
                  DropdownMenuItem(value: 'CHEQUE', child: Text('Cheque')),
                  DropdownMenuItem(value: 'CASH', child: Text('Cash')),
                ],
                onChanged: (value) => selectedMethod = value,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: referenceController,
                decoration: const InputDecoration(
                  labelText: 'Reference Number (Optional)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final amount = double.tryParse(amountController.text);
              if (amount == null || amount <= 0) {
                if (!mounted) return;
                MotionToast.show(context, message: 'Please enter a valid amount', isError: true);
                return;
              }

              Navigator.pop(dialogContext);
              
              try {
                await _paymentService.recordTransaction(
                  schedule.id,
                  RecordTransactionRequest(
                    amount: amount,
                    paymentMethod: selectedMethod,
                    referenceNumber: referenceController.text.isNotEmpty 
                      ? referenceController.text 
                      : null,
                    // TDS and categorization (defaults for now - can be enhanced with UI)
                    tdsPercentage: null,  // Optional: Set to 2.0 for 2% TDS
                    tdsDeductedBy: 'CUSTOMER',
                    paymentCategory: 'PROGRESS',  // Default to progress payment
                  ),
                );
                
                if (!mounted) return;
                MotionToast.show(context, message: 'Payment recorded successfully', isError: false);
                _loadPaymentData();
              } catch (e) {
                if (!mounted) return;
                await ErrorHandler.handleApiError(context, e, defaultMessage: 'Failed to record payment');
              }
            },
            child: const Text('Record'),
          ),
        ],
      ),
    );
  }

  Future<void> _openCreateDialog() async {
    final created = await showDialog<bool>(
      context: context,
      builder: (_) => _CreateDesignPaymentDialog(
        projectId: widget.project.id!,
        projectName: widget.project.name,
      ),
    );
    if (created == true) {
      _loadPaymentData();
    }
  }
}

class _CreateDesignPaymentDialog extends StatefulWidget {
  final int projectId;
  final String projectName;

  const _CreateDesignPaymentDialog({
    required this.projectId,
    required this.projectName,
  });

  @override
  State<_CreateDesignPaymentDialog> createState() =>
      _CreateDesignPaymentDialogState();
}

class _CreateDesignPaymentDialogState
    extends State<_CreateDesignPaymentDialog> {
  // Indian-locale ₹ formatter — renders 11,21,000 (lakh grouping), not 1,121,000.
  static final _inr =
      NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

  // Soft caps — Kerala residential design fees rarely exceed these.
  static const double _maxRatePerSqft = 2000; // ₹/sqft
  static const double _maxDiscountPct = 25;
  static const double _gstPct = 18; // mirrors PaymentService.GST_PERCENTAGE

  final _formKey = GlobalKey<FormState>();
  final _packageNameController =
      TextEditingController(text: 'Standard Design Package');
  final _rateController = TextEditingController();
  final _sqftController = TextEditingController();
  final _discountController = TextEditingController(text: '0');
  String _paymentType = 'INSTALLMENT';
  bool _isSubmitting = false;

  final PaymentService _paymentService = PaymentService();

  @override
  void initState() {
    super.initState();
    // Live preview: any input change recomputes the totals card below.
    for (final c in [_rateController, _sqftController, _discountController]) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    _packageNameController.dispose();
    _rateController.dispose();
    _sqftController.dispose();
    _discountController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    try {
      await _paymentService.createDesignPayment(
        CreateDesignPaymentRequest(
          projectId: widget.projectId,
          packageName: _packageNameController.text.trim(),
          ratePerSqft: double.parse(_rateController.text),
          totalSqft: double.parse(_sqftController.text),
          discountPercentage: double.tryParse(_discountController.text),
          paymentType: _paymentType,
        ),
      );
      if (!mounted) return;
      MotionToast.show(context,
          message: 'Design payment created', isError: false);
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      await ErrorHandler.handleApiError(context, e,
          defaultMessage: 'Failed to create design payment');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  String? _requiredNumber(String? value, {bool allowZero = false}) {
    if (value == null || value.trim().isEmpty) return 'Required';
    final parsed = double.tryParse(value);
    if (parsed == null) return 'Enter a number';
    if (!allowZero && parsed <= 0) return 'Must be greater than 0';
    if (parsed < 0) return 'Cannot be negative';
    return null;
  }

  String? _validateRate(String? value) {
    final base = _requiredNumber(value);
    if (base != null) return base;
    final v = double.parse(value!);
    if (v > _maxRatePerSqft) {
      return 'Rate looks unusually high (max ₹${_maxRatePerSqft.toInt()}/sqft)';
    }
    return null;
  }

  String? _validateDiscount(String? value) {
    final base = _requiredNumber(value, allowZero: true);
    if (base != null) return base;
    final v = double.parse(value!);
    if (v > _maxDiscountPct) {
      return 'Discount above ${_maxDiscountPct.toInt()}% needs manager approval';
    }
    return null;
  }

  /// Mirrors PaymentService.createDesignPayment math so staff see exactly
  /// what the backend will persist — no surprises after submit.
  ({double base, double gst, double subtotal, double discount, double total})?
      _computeTotals() {
    final rate = double.tryParse(_rateController.text);
    final sqft = double.tryParse(_sqftController.text);
    if (rate == null || sqft == null || rate <= 0 || sqft <= 0) return null;
    final discountPct =
        (double.tryParse(_discountController.text) ?? 0).clamp(0, 100);
    final base = rate * sqft;
    final gst = base * _gstPct / 100;
    final subtotal = base + gst;
    final discount = subtotal * discountPct / 100;
    final total = subtotal - discount;
    return (
      base: base,
      gst: gst,
      subtotal: subtotal,
      discount: discount,
      total: total,
    );
  }

  @override
  Widget build(BuildContext context) {
    final totals = _computeTotals();
    return AlertDialog(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Create Design Payment'),
          const SizedBox(height: 2),
          Text(
            widget.projectName,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.normal,
                ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _packageNameController,
                decoration: const InputDecoration(labelText: 'Design Package'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _rateController,
                decoration: const InputDecoration(
                  labelText: 'Design Fee Rate (₹/sqft)',
                  helperText: 'Typical Kerala range: ₹50–250/sqft',
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: _validateRate,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _sqftController,
                decoration: const InputDecoration(
                  labelText: 'Built-up Area (sqft)',
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: _requiredNumber,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _discountController,
                decoration: const InputDecoration(
                    labelText: 'Discount % (optional)'),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: _validateDiscount,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _paymentType,
                decoration: const InputDecoration(labelText: 'Payment type'),
                items: const [
                  DropdownMenuItem(
                      value: 'FULL', child: Text('Pay in Full')),
                  DropdownMenuItem(
                      value: 'INSTALLMENT',
                      child: Text('3-Installment Plan (Advance / Mid / Final)')),
                ],
                onChanged: (v) => setState(() => _paymentType = v!),
              ),
              const SizedBox(height: 16),
              if (totals != null) _buildTotalsCard(totals),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed:
              _isSubmitting ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submit,
          child: _isSubmitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Create'),
        ),
      ],
    );
  }

  Widget _buildTotalsCard(
      ({
        double base,
        double gst,
        double subtotal,
        double discount,
        double total
      }) t) {
    final rate = double.tryParse(_rateController.text) ?? 0;
    final sqft = double.tryParse(_sqftController.text) ?? 0;
    final discountPct = double.tryParse(_discountController.text) ?? 0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.primaryBlue.withOpacity(0.06),
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Preview',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryBlue,
                ),
          ),
          const SizedBox(height: 8),
          _row('Base (${_inr.format(rate)} × ${sqft.toStringAsFixed(0)} sqft)',
              _inr.format(t.base)),
          _row('GST (${_gstPct.toInt()}%)', _inr.format(t.gst)),
          _row('Subtotal', _inr.format(t.subtotal)),
          if (discountPct > 0)
            _row(
              'Discount (${discountPct.toStringAsFixed(discountPct.truncateToDouble() == discountPct ? 0 : 1)}%)',
              '− ${_inr.format(t.discount)}',
              valueColor: AppTheme.statusSuccess,
            ),
          const Divider(height: 16),
          _row('Total Payable', _inr.format(t.total), bold: true),
          if (_paymentType == 'INSTALLMENT') ...[
            const SizedBox(height: 12),
            Text(
              'Installment plan',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textSecondary,
                  ),
            ),
            const SizedBox(height: 4),
            ..._installmentPreview(t.total).map(
              (e) => _row(e.$1, _inr.format(e.$2)),
            ),
          ],
        ],
      ),
    );
  }

  /// Mirrors PaymentService's 3-installment split: equal thirds, with any
  /// rounding remainder bolted onto the first installment so the rows sum
  /// exactly to the total.
  List<(String, double)> _installmentPreview(double total) {
    final third = (total / 3 * 100).floorToDouble() / 100; // round down to 2dp
    final remainder = total - third * 3;
    return [
      ('1. Advance', third + remainder),
      ('2. Design Phase', third),
      ('3. Post-Design', third),
    ];
  }

  Widget _row(String label, String value,
      {bool bold = false, Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: bold ? FontWeight.bold : FontWeight.w500,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}

