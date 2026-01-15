import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../theme/responsive_utils.dart';
import '../../models/customer_project.dart';
import '../../models/payment_models.dart';
import '../../services/crm_service.dart';
import '../../services/payment_service.dart';
import '../../utils/motion_toast.dart';
import 'package:intl/intl.dart';

class DesignPackagePaymentScreen extends StatefulWidget {
  const DesignPackagePaymentScreen({
    super.key,
    required this.project,
    required this.packageDetails,
  });

  final CustomerProject project;
  final Map<String, dynamic> packageDetails;

  @override
  State<DesignPackagePaymentScreen> createState() =>
      _DesignPackagePaymentScreenState();
}

class _DesignPackagePaymentScreenState
    extends State<DesignPackagePaymentScreen> {
  bool _isSubmitting = false;
  bool _isCustomPayment = false; // Default to pay in full (discount applied)
  final CRMService _crmService = CRMService();
  final PaymentService _paymentService = PaymentService();
  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 2,
  );

  double get _sqFeet => widget.project.sqfeet ?? 0.0;

  double get _basePrice {
    final pricePerSqFt = widget.packageDetails['priceValue'] as double;
    return pricePerSqFt * _sqFeet;
  }

  double get _discountPercentage {
    if (_isCustomPayment) return 0.0;
    final packageName = widget.packageDetails['name'].toString().toLowerCase();
    return packageName == 'custom' ? 10.0 : 15.0;
  }

  double get _discountAmount {
    return _basePrice * (_discountPercentage / 100);
  }

  double get _discountedPrice => _basePrice - _discountAmount;
  double get _gstAmount => _discountedPrice * 0.18;
  double get _totalAmount => _discountedPrice + _gstAmount;

  Future<void> _signAgreement() async {
    if (widget.project.id == null) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      // 1. Create the payment record first
      final paymentRequest = CreateDesignPaymentRequest(
        projectId: widget.project.id!,
        packageName: widget.packageDetails['name'],
        ratePerSqft: widget.packageDetails['priceValue'],
        totalSqft: _sqFeet,
        discountPercentage: _discountPercentage,
        paymentType: _isCustomPayment ? 'INSTALLMENT' : 'FULL',
      );
      
      await _paymentService.createDesignPayment(paymentRequest);

      // 2. Update the project with design package and agreement signed
      final updatedProject = widget.project.copyWith(
        designPackage: widget.packageDetails['name'],
        isDesignAgreementSigned: true,
      );

      await _crmService.updateCustomerProject(widget.project.id!, updatedProject);

      if (mounted) {
        MotionToast.show(
          context,
          message: 'Design package confirmed and agreement signed!',
          isError: false,
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        MotionToast.show(
          context,
          message: 'Failed to sign agreement: ${e.toString()}',
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Package Details & Agreement'),
      ),
      body: AdaptiveContainer(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppTheme.spacingMD),
                children: [
                  _buildSummaryCard(),
                  const SizedBox(height: AppTheme.spacingMD),
                  _buildPaymentOptions(),
                  const SizedBox(height: AppTheme.spacingMD),
                  _buildInclusionsCard(),
                  const SizedBox(height: AppTheme.spacingMD),
                  if (_isCustomPayment) _buildPaymentScheduleCard(),
                ],
              ),
            ),
            _buildBottomNav(),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingMD),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cost Summary',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppTheme.spacingMD),
            _buildRow('Package', widget.packageDetails['name']),
            _buildRow('Area', '${_sqFeet.toStringAsFixed(2)} sq.ft.'),
            _buildRow('Base Price', _currencyFormat.format(_basePrice)),
            if (!_isCustomPayment)
              _buildRow('Discount', '- ${_currencyFormat.format(_discountAmount)}', color: AppTheme.successGreen),
            const Divider(),
            _buildRow('Taxable Amount', _currencyFormat.format(_discountedPrice)),
            _buildRow('GST (18%)', _currencyFormat.format(_gstAmount)),
            const Divider(),
            _buildRow(
              'Total Amount',
              _currencyFormat.format(_totalAmount),
              isBold: true,
              color: AppTheme.coralRed,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentOptions() {
    final packageName = widget.packageDetails['name'].toString().toLowerCase();
    final discountPercent = packageName == 'custom' ? 10 : 15;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'Payment Options',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        Row(
          children: [
            Expanded(
              child: _buildOptionCard(
                title: 'Pay in full',
                subtitle: '$discountPercent% OFF',
                isSelected: !_isCustomPayment,
                onTap: () => setState(() => _isCustomPayment = false),
              ),
            ),
            const SizedBox(width: AppTheme.spacingSM),
            Expanded(
              child: _buildOptionCard(
                title: 'Pay in installment',
                subtitle: 'Equal Split',
                isSelected: _isCustomPayment,
                onTap: () => setState(() => _isCustomPayment = true),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOptionCard({
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusMD),
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacingMD),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryBlue.withOpacity(0.05) : AppTheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusMD),
          border: Border.all(
            color: isSelected ? AppTheme.primaryBlue : AppTheme.borderLight,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: isSelected ? AppTheme.primaryBlue : AppTheme.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primaryBlue.withOpacity(0.1) : AppTheme.background,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isSelected ? AppTheme.primaryBlue : AppTheme.textSecondary,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value, {bool isBold = false, Color? color}) {
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
                  color: color,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildInclusionsCard() {
    final color = widget.packageDetails['color'] as Color;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingMD),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Package Inclusions',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppTheme.spacingSM),
            ...widget.packageDetails['features'].map<Widget>((feature) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle_outline, size: 16, color: color),
                      const SizedBox(width: AppTheme.spacingSM),
                      Expanded(child: Text(feature, style: Theme.of(context).textTheme.bodySmall)),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentScheduleCard() {
    final stageAmount = _totalAmount / 3;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingMD),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Payment Schedule (3 Equal Installments)',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppTheme.spacingMD),
            _buildScheduleItem('1. Advance', '33.33%', stageAmount),
            _buildScheduleItem('2. Design Phase', '33.33%', stageAmount),
            _buildScheduleItem('3. Post-Design', '33.33%', stageAmount),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleItem(String label, String percentage, double amount) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(child: Text(label, style: Theme.of(context).textTheme.bodyMedium)),
          SizedBox(width: 60, child: Text(percentage, style: Theme.of(context).textTheme.bodySmall)),
          Text(_currencyFormat.format(amount), style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMD),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        boxShadow: AppTheme.shadowLG,
      ),
      child: SafeArea(
        child: ElevatedButton(
          onPressed: _isSubmitting ? null : _signAgreement,
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
          ),
          child: _isSubmitting
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Sign Design Agreement'),
        ),
      ),
    );
  }
}

