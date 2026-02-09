import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/subcontract_provider.dart';
import '../../models/subcontract_models.dart';
import '../../theme/app_theme.dart';
import '../../config/app_config.dart';

/// Measurement Entry Form
/// Form to record a new measurement for unit-rate subcontracts
class SubcontractMeasurementForm extends StatefulWidget {
  final int workOrderId;
  final String workOrderNumber;
  final String unit;
  final double rate;

  const SubcontractMeasurementForm({
    super.key,
    required this.workOrderId,
    required this.workOrderNumber,
    required this.unit,
    required this.rate,
  });

  @override
  State<SubcontractMeasurementForm> createState() => _SubcontractMeasurementFormState();
}

class _SubcontractMeasurementFormState extends State<SubcontractMeasurementForm> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _quantityController = TextEditingController();
  final _amountController = TextEditingController();

  DateTime _measurementDate = DateTime.now();
  bool _isCalculating = false;

  final _currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);

  @override
  void initState() {
    super.initState();
    _quantityController.addListener(_calculateAmount);
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _quantityController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _calculateAmount() {
    if (_isCalculating) return;
    _isCalculating = true;

    try {
      final quantity = double.tryParse(_quantityController.text) ?? 0;
      final amount = quantity * widget.rate;

      setState(() {
        _amountController.text = amount.toStringAsFixed(2);
      });
    } finally {
      _isCalculating = false;
    }
  }

  Future<void> _submitMeasurement() async {
    if (!_formKey.currentState!.validate()) return;

    final quantity = double.parse(_quantityController.text);
    final amount = double.parse(_amountController.text);

    final measurement = SubcontractMeasurement(
      workOrderId: widget.workOrderId,
      measurementDate: _measurementDate,
      description: _descriptionController.text,
      quantity: quantity,
      unit: widget.unit,
      rate: widget.rate,
      amount: amount,
      status: 'PENDING',
    );

    try {
      await context.read<SubcontractProvider>().recordMeasurement(
            widget.workOrderId,
            measurement,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Measurement recorded successfully'),
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
        title: const Text('Record Measurement', style: TextStyle(color: Colors.white)),
        backgroundColor: AppTheme.deepSlate,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Work Order Info Card
            Card(
              color: AppTheme.deepSlate.withOpacity(0.05),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.workOrderNumber,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          'Rate: ${_currencyFormat.format(widget.rate)} per ${widget.unit}',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Measurement Date
            ListTile(
              leading: const Icon(Icons.calendar_today, color: AppTheme.deepSlate),
              title: const Text('Measurement Date'),
              subtitle: Text(DateFormat('dd MMM yyyy').format(_measurementDate)),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _measurementDate,
                  firstDate: AppConfig.datePickerFirstDate,
                  lastDate: DateTime.now(),
                );
                if (date != null) {
                  setState(() => _measurementDate = date);
                }
              },
            ),

            const SizedBox(height: 16),

            // Description
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description *',
                border: OutlineInputBorder(),
                hintText: 'e.g., First floor plastering',
              ),
              maxLines: 2,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Description is required';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Quantity
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _quantityController,
                    decoration: InputDecoration(
                      labelText: 'Quantity *',
                      border: const OutlineInputBorder(),
                      suffixText: widget.unit,
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Required';
                      }
                      final qty = double.tryParse(value);
                      if (qty == null || qty <= 0) {
                        return 'Invalid quantity';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Rate',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '₹${widget.rate}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Calculated Amount (read-only)
            TextFormField(
              controller: _amountController,
              decoration: InputDecoration(
                labelText: 'Total Amount',
                prefixText: '₹ ',
                border: const OutlineInputBorder(),
                filled: true,
                fillColor: AppTheme.tealAccent.withOpacity(0.1),
                suffixIcon: const Icon(Icons.calculate, color: AppTheme.tealAccent),
              ),
              readOnly: true,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: AppTheme.tealAccent,
              ),
            ),

            const SizedBox(height: 8),

            // Calculation breakdown
            if (_quantityController.text.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  '${_quantityController.text} ${widget.unit} × ₹${widget.rate} = ₹${_amountController.text}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ),

            const SizedBox(height: 32),

            // Info card
            Card(
              color: AppTheme.azure.withOpacity(0.1),
              child: const Padding(
                padding: EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: AppTheme.azure, size: 20),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'This measurement will be pending approval before payment can be processed.',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Submit Button
            ElevatedButton(
              onPressed: _submitMeasurement,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.coralRed,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                'Record Measurement',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
