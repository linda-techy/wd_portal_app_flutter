import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../../theme/app_theme.dart';
import '../../../../models/procurement_models.dart'; // For Vendor if needed general
import '../../data/models/material_indent.dart';
import '../../data/models/vendor_quotation.dart';
import '../../data/services/material_indent_service.dart';
import 'package:admin/providers/procurement_provider.dart';

class QuotationManagementScreen extends StatefulWidget {
  final MaterialIndent indent;

  const QuotationManagementScreen({Key? key, required this.indent}) : super(key: key);

  @override
  _QuotationManagementScreenState createState() => _QuotationManagementScreenState();
}

class _QuotationManagementScreenState extends State<QuotationManagementScreen> {
  final _service = MaterialIndentService();
  bool _isLoading = true;
  List<VendorQuotation> _quotations = [];

  @override
  void initState() {
    super.initState();
    _loadQuotations();
    // Fetch vendors in background for the dropdown
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProcurementProvider>().fetchVendors();
    });
  }

  Future<void> _loadQuotations() async {
    setState(() => _isLoading = true);
    try {
      final list = await _service.getQuotations(widget.indent.id!);
      if (mounted) {
        setState(() {
          _quotations = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _showAddQuoteDialog() {
    showDialog(
      context: context,
      builder: (context) => _AddQuoteDialog(
        indentId: widget.indent.id!,
        onSuccess: _loadQuotations,
      ),
    );
  }

  Future<void> _selectQuotation(VendorQuotation quote) async {
    try {
      await _service.selectQuotation(quote.id!);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Quotation Selected. PO Draft Created.')));
      _loadQuotations();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Quotations: ${widget.indent.indentNumber}')),
      body: Column(
        children: [
          _buildIndentSummary(),
          const Divider(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _quotations.isEmpty
                    ? const Center(child: Text('No quotations received.'))
                    : ListView.builder(
                        itemCount: _quotations.length,
                        itemBuilder: (context, index) {
                          final quote = _quotations[index];
                          final isSelected = quote.status == 'SELECTED';
                          return Card(
                            color: isSelected ? Colors.green.shade50 : null,
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: ListTile(
                              title: Text(quote.vendorName ?? 'Unknown Vendor'),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Amount: ₹${quote.quotedAmount}'),
                                  if (quote.expectedDeliveryDate != null)
                                    Text('Delivery: ${DateFormat('MMM dd').format(quote.expectedDeliveryDate!)}'),
                                ],
                              ),
                              trailing: isSelected
                                  ? const Icon(Icons.check_circle, color: Colors.green)
                                  : ElevatedButton(
                                      onPressed: () => _selectQuotation(quote),
                                      child: const Text('Select'),
                                    ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddQuoteDialog,
        child: const Icon(Icons.add),
        tooltip: 'Add Quote',
      ),
    );
  }

  Widget _buildIndentSummary() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Indent Details', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text('Requested: ${widget.indent.requestDate}'),
          Text('Items: ${widget.indent.items.length}'),
          // List simplified items
          ...widget.indent.items.map((i) => Text('- ${i.itemName} (${i.quantityRequested} ${i.unit})')).take(3),
          if (widget.indent.items.length > 3) const Text('...'),
        ],
      ),
    );
  }
}

class _AddQuoteDialog extends StatefulWidget {
  final int indentId;
  final VoidCallback onSuccess;

  const _AddQuoteDialog({Key? key, required this.indentId, required this.onSuccess}) : super(key: key);

  @override
  __AddQuoteDialogState createState() => __AddQuoteDialogState();
}

class __AddQuoteDialogState extends State<_AddQuoteDialog> {
  final _formKey = GlobalKey<FormState>();
  final _service = MaterialIndentService();
  int? _selectedVendorId;
  final _amountCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  DateTime? _deliveryDate;
  bool _submitting = false;

  @override
  Widget build(BuildContext context) {
    // Access providers
    final vendors = context.watch<ProcurementProvider>().vendors;

    return AlertDialog(
      title: const Text('Add Vendor Quote'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int>(
                decoration: const InputDecoration(labelText: 'Vendor'),
                items: vendors.map((v) => DropdownMenuItem(value: v.id, child: Text(v.name))).toList(),
                onChanged: (val) => setState(() => _selectedVendorId = val),
                validator: (val) => val == null ? 'Select Vendor' : null,
              ),
              TextFormField(
                controller: _amountCtrl,
                decoration: const InputDecoration(labelText: 'Quoted Amount (₹)'),
                keyboardType: TextInputType.number,
                validator: (val) => val == null || val.isEmpty ? 'Enter Amount' : null,
              ),
              TextFormField(
                controller: _notesCtrl,
                decoration: const InputDecoration(labelText: 'Notes / Inclusions'),
              ),
              ListTile(
                title: Text(_deliveryDate == null ? 'Select Delivery Date' : 'Delivery: ${DateFormat('MMM dd').format(_deliveryDate!)}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) setState(() => _deliveryDate = picked);
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: _submitting ? null : _submit,
          child: _submitting ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Add Quote'),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);

    try {
      final quote = VendorQuotation(
        indentId: widget.indentId,
        vendorId: _selectedVendorId!,
        quotedAmount: double.parse(_amountCtrl.text),
        notes: _notesCtrl.text,
        expectedDeliveryDate: _deliveryDate,
      );

      await _service.createQuotation(widget.indentId, _selectedVendorId!, quote);
      widget.onSuccess();
      Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        setState(() => _submitting = false);
      }
    }
  }
}
