import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:admin/utils/error_handler.dart';
import '../../providers/subcontract_provider.dart';
import '../../models/subcontract_models.dart';
import '../../theme/app_theme.dart';
import '../../config/app_config.dart';

class RecordSubcontractPaymentScreen extends StatefulWidget {
  final int workOrderId;
  final double balanceDue;

  const RecordSubcontractPaymentScreen({
    super.key,
    required this.workOrderId,
    required this.balanceDue,
  });

  @override
  State<RecordSubcontractPaymentScreen> createState() =>
      _RecordSubcontractPaymentScreenState();
}

class _RecordSubcontractPaymentScreenState
    extends State<RecordSubcontractPaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _grossAmountController = TextEditingController();
  final _tdsRateController = TextEditingController(
      text: '1.0'); // Default 1% for Individual/HUF, 2% otherwise
  final _otherDeductionsController = TextEditingController(text: '0');
  final _referenceController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime _paymentDate = DateTime.now();
  String _paymentMode = 'BANK_TRANSFER';
  double _calculatedNet = 0;
  double _calculatedTds = 0;

  final List<String> _paymentModes = [
    'BANK_TRANSFER',
    'CHEQUE',
    'CASH',
    'UPI',
    'DEMAND_DRAFT'
  ];

  @override
  void initState() {
    super.initState();
    _grossAmountController.addListener(_calculateNet);
    _tdsRateController.addListener(_calculateNet);
    _otherDeductionsController.addListener(_calculateNet);
  }

  @override
  void dispose() {
    _grossAmountController.dispose();
    _tdsRateController.dispose();
    _otherDeductionsController.dispose();
    _referenceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _calculateNet() {
    final gross = double.tryParse(_grossAmountController.text) ?? 0;
    final tdsRate = double.tryParse(_tdsRateController.text) ?? 0;
    final deductions = double.tryParse(_otherDeductionsController.text) ?? 0;

    final tdsAmount = gross * (tdsRate / 100);
    final net = gross - tdsAmount - deductions;

    setState(() {
      _calculatedTds = tdsAmount;
      _calculatedNet = net;
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _paymentDate,
      firstDate: AppConfig.datePickerFirstDate,
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _paymentDate) {
      setState(() {
        _paymentDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SubcontractProvider>();
    final currencyFormat =
        NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(
        title:
            const Text('Record Payment', style: TextStyle(color: Colors.white)),
        backgroundColor: AppTheme.deepSlate,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Balance Info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.account_balance_wallet,
                        color: Colors.blue),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Current Balance Due',
                            style: TextStyle(color: Colors.blue, fontSize: 12)),
                        Text(
                          currencyFormat.format(widget.balanceDue),
                          style: const TextStyle(
                              color: Colors.blue,
                              fontSize: 18,
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Payment Details
              TextFormField(
                controller: _grossAmountController,
                decoration: const InputDecoration(
                  labelText: 'Gross Amount *',
                  prefixIcon: Icon(Icons.currency_rupee),
                  border: OutlineInputBorder(),
                  helperText: 'Amount before TDS and deductions',
                ),
                keyboardType: TextInputType.number,
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Required';
                  if (double.tryParse(val) == null) return 'Invalid number';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _tdsRateController,
                      decoration: const InputDecoration(
                        labelText: 'TDS Rate (%)',
                        suffixText: '%',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _otherDeductionsController,
                      decoration: const InputDecoration(
                        labelText: 'Other Deductions',
                        prefixText: '₹ ',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Calculation Preview
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    _buildCalcRow('Gross Amount', _grossAmountController.text),
                    _buildCalcRow('Less: TDS (${_tdsRateController.text}%)',
                        '- ${currencyFormat.format(_calculatedTds)}',
                        color: Colors.red),
                    _buildCalcRow('Less: Deductions',
                        '- ${currencyFormat.format(double.tryParse(_otherDeductionsController.text) ?? 0)}',
                        color: Colors.red),
                    const Divider(),
                    _buildCalcRow(
                        'Net Payable', currencyFormat.format(_calculatedNet),
                        isBold: true, color: Colors.green),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Payment Meta
              DropdownButtonFormField<String>(
                value: _paymentMode,
                decoration: const InputDecoration(
                  labelText: 'Payment Mode',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category),
                ),
                items: _paymentModes
                    .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                    .toList(),
                onChanged: (val) => setState(() => _paymentMode = val!),
              ),
              const SizedBox(height: 16),

              InkWell(
                onTap: () => _selectDate(context),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Payment Date',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(DateFormat('dd MMM yyyy').format(_paymentDate)),
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _referenceController,
                decoration: const InputDecoration(
                  labelText: 'Transaction Reference / Cheque No.',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.confirmation_number),
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes / Remarks',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.note),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: provider.isLoading ? null : _submitPayment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.coralRed,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: provider.isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Record Payment',
                          style: TextStyle(fontSize: 16, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCalcRow(String label, String value,
      {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: color,
              fontSize: isBold ? 16 : 14,
            ),
          ),
        ],
      ),
    );
  }

  void _submitPayment() async {
    if (_formKey.currentState!.validate()) {
      if (_calculatedNet <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Net payable amount must be greater than zero')),
        );
        return;
      }

      final payment = SubcontractPayment(
        workOrderId: widget.workOrderId,
        paymentDate: _paymentDate,
        grossAmount: double.parse(_grossAmountController.text),
        tdsPercentage: double.parse(_tdsRateController.text),
        tdsAmount: _calculatedTds,
        otherDeductions: double.parse(_otherDeductionsController.text),
        netAmount: _calculatedNet,
        paymentMode: _paymentMode,
        transactionReference: _referenceController.text,
        notes: _notesController.text,
      );

      try {
        await context.read<SubcontractProvider>().recordPayment(payment);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Payment recorded successfully')),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ErrorHandler.showErrorSnackBar(context, e);
        }
      }
    }
  }
}
