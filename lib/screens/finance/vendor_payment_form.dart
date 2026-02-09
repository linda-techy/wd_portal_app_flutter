import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/vendor_payment_provider.dart';
import '../../models/vendor_payment_models.dart';
import '../../theme/app_theme.dart';
import '../../config/app_config.dart';

/// Vendor Payment Recording Form
/// Form to record a payment against a vendor invoice
class VendorPaymentForm extends StatefulWidget {
  final int invoiceId;
  final double invoiceAmount;
  final String vendorName;

  const VendorPaymentForm({
    super.key,
    required this.invoiceId,
    required this.invoiceAmount,
    required this.vendorName,
  });

  @override
  State<VendorPaymentForm> createState() => _VendorPaymentFormState();
}

class _VendorPaymentFormState extends State<VendorPaymentForm> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _tdsPercentageController = TextEditingController(text: '1.0');
  final _tdsAmountController = TextEditingController();
  final _otherDeductionsController = TextEditingController(text: '0');
  final _netAmountController = TextEditingController();
  final _transactionRefController = TextEditingController();
  final _chequeNumberController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime _paymentDate = DateTime.now();
  String _paymentMode = 'NEFT';
  bool _isCalculating = false;

  final _currencyFormat =
      NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);

  @override
  void initState() {
    super.initState();
    _amountController.addListener(_calculateAmounts);
    _tdsPercentageController.addListener(_calculateAmounts);
    _otherDeductionsController.addListener(_calculateAmounts);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _tdsPercentageController.dispose();
    _tdsAmountController.dispose();
    _otherDeductionsController.dispose();
    _netAmountController.dispose();
    _transactionRefController.dispose();
    _chequeNumberController.dispose();
    _bankNameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _calculateAmounts() {
    if (_isCalculating) return;
    _isCalculating = true;

    try {
      final amount = double.tryParse(_amountController.text) ?? 0;
      final tdsPercentage = double.tryParse(_tdsPercentageController.text) ?? 0;
      final otherDeductions =
          double.tryParse(_otherDeductionsController.text) ?? 0;

      final tdsAmount = (amount * tdsPercentage / 100);
      final netAmount = amount - tdsAmount - otherDeductions;

      setState(() {
        _tdsAmountController.text = tdsAmount.toStringAsFixed(2);
        _netAmountController.text = netAmount.toStringAsFixed(2);
      });
    } finally {
      _isCalculating = false;
    }
  }

  Future<void> _submitPayment() async {
    if (!_formKey.currentState!.validate()) return;

    final payment = VendorPayment(
      invoiceId: widget.invoiceId,
      paymentDate: _paymentDate,
      amountPaid: double.parse(_amountController.text),
      tdsDeducted: double.parse(_tdsAmountController.text),
      otherDeductions: double.tryParse(_otherDeductionsController.text),
      netPaid: double.parse(_netAmountController.text),
      paymentMode: _paymentMode,
      transactionReference: _transactionRefController.text.isEmpty
          ? null
          : _transactionRefController.text,
      chequeNumber: _chequeNumberController.text.isEmpty
          ? null
          : _chequeNumberController.text,
      bankName:
          _bankNameController.text.isEmpty ? null : _bankNameController.text,
      notes: _notesController.text.isEmpty ? null : _notesController.text,
    );

    try {
      await context.read<VendorPaymentProvider>().recordPayment(payment);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment recorded successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            const Text('Record Payment', style: TextStyle(color: Colors.white)),
        backgroundColor: AppTheme.deepSlate,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Invoice Info Card
            Card(
              color: AppTheme.deepSlate.withOpacity(0.05),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.vendorName,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Invoice Amount: ${_currencyFormat.format(widget.invoiceAmount)}',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Payment Date
            ListTile(
              leading:
                  const Icon(Icons.calendar_today, color: AppTheme.deepSlate),
              title: const Text('Payment Date'),
              subtitle: Text(DateFormat('dd MMM yyyy').format(_paymentDate)),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _paymentDate,
                  firstDate: AppConfig.datePickerFirstDate,
                  lastDate: DateTime.now(),
                );
                if (date != null) {
                  setState(() => _paymentDate = date);
                }
              },
            ),

            const SizedBox(height: 16),

            // Amount Paid
            TextFormField(
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: 'Amount Paid *',
                prefixText: '₹ ',
                border: OutlineInputBorder(),
                suffixIcon:
                    Icon(Icons.currency_rupee, color: AppTheme.deepSlate),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) return 'Required';
                final amount = double.tryParse(value);
                if (amount == null || amount <= 0) return 'Invalid amount';
                if (amount > widget.invoiceAmount)
                  return 'Exceeds invoice amount';
                return null;
              },
            ),

            const SizedBox(height: 16),

            // TDS Percentage
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _tdsPercentageController,
                    decoration: const InputDecoration(
                      labelText: 'TDS %',
                      border: OutlineInputBorder(),
                      suffixText: '%',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _tdsAmountController,
                    decoration: const InputDecoration(
                      labelText: 'TDS Amount',
                      prefixText: '₹ ',
                      border: OutlineInputBorder(),
                    ),
                    readOnly: true,
                    style: const TextStyle(color: AppTheme.coralRed),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Other Deductions
            TextFormField(
              controller: _otherDeductionsController,
              decoration: const InputDecoration(
                labelText: 'Other Deductions',
                prefixText: '₹ ',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),

            const SizedBox(height: 16),

            // Net Amount (calculated)
            TextFormField(
              controller: _netAmountController,
              decoration: InputDecoration(
                labelText: 'Net Amount',
                prefixText: '₹ ',
                border: const OutlineInputBorder(),
                filled: true,
                fillColor: AppTheme.tealAccent.withOpacity(0.1),
              ),
              readOnly: true,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: AppTheme.tealAccent,
              ),
            ),

            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),

            // Payment Mode
            DropdownButtonFormField<String>(
              value: _paymentMode,
              decoration: const InputDecoration(
                labelText: 'Payment Mode *',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'CASH', child: Text('Cash')),
                DropdownMenuItem(value: 'CHEQUE', child: Text('Cheque')),
                DropdownMenuItem(value: 'NEFT', child: Text('NEFT')),
                DropdownMenuItem(value: 'RTGS', child: Text('RTGS')),
                DropdownMenuItem(value: 'UPI', child: Text('UPI')),
              ],
              onChanged: (value) => setState(() => _paymentMode = value!),
            ),

            const SizedBox(height: 16),

            // Transaction Reference (for electronic payments)
            if (_paymentMode != 'CASH')
              TextFormField(
                controller: _transactionRefController,
                decoration: const InputDecoration(
                  labelText: 'Transaction Reference',
                  border: OutlineInputBorder(),
                  hintText: 'UTR/Reference number',
                ),
              ),

            // Cheque details
            if (_paymentMode == 'CHEQUE') ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: _chequeNumberController,
                decoration: const InputDecoration(
                  labelText: 'Cheque Number',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _bankNameController,
                decoration: const InputDecoration(
                  labelText: 'Bank Name',
                  border: OutlineInputBorder(),
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Notes
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),

            const SizedBox(height: 24),

            // Submit Button
            ElevatedButton(
              onPressed: _submitPayment,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.coralRed,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                'Record Payment',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
