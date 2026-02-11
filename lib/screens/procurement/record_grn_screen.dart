import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:admin/constants.dart';
import 'package:admin/theme/app_theme.dart';
import 'package:admin/providers/procurement_provider.dart';
import 'package:admin/providers/portal_auth_provider.dart';
import 'package:admin/models/procurement_models.dart';
import 'package:intl/intl.dart';

class RecordGRNScreen extends StatefulWidget {
  final PurchaseOrder po;
  const RecordGRNScreen({super.key, required this.po});

  @override
  State<RecordGRNScreen> createState() => _RecordGRNScreenState();
}

class _RecordGRNScreenState extends State<RecordGRNScreen> {
  final _formKey = GlobalKey<FormState>();
  final _invoiceNumberController = TextEditingController();
  final _invoiceAmountController = TextEditingController();
  final _notesController = TextEditingController ();
  DateTime _receivedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _invoiceAmountController.text = widget.po.netAmount.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Record GRN for ${widget.po.poNumber}"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppTheme.deepSlate,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(defaultPadding),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                color: AppTheme.surfaceElevated,
                child: ListTile(
                  title: const Text("Purchase Order Details"),
                  subtitle: Text("Vendor: ${widget.po.vendorName}\nProject: ${widget.po.projectName}\nAmount: ₹${widget.po.netAmount.toStringAsFixed(2)}"),
                ),
              ),
              const SizedBox(height: 24),
              ListTile(
                title: const Text("Received Date"),
                subtitle: Text(DateFormat('dd-MM-yyyy').format(_receivedDate)),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now().subtract(const Duration(days: 30)),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) setState(() => _receivedDate = picked);
                },
              ),
              const SizedBox(height: 16),
               // _buildTextField(_receivedByController, "Received By", Icons.person, required: true),
              const SizedBox(height: 16),
              _buildTextField(_invoiceNumberController, "Invoice Number", Icons.receipt),
              const SizedBox(height: 16),
              _buildTextField(_invoiceAmountController, "Invoice Amount", Icons.currency_rupee, keyboardType: TextInputType.number),
              const SizedBox(height: 16),
              _buildTextField(_notesController, "Notes", Icons.note, maxLines: 3),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _submitGRN,
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryBlue),
                  child: const Text("Record Successful Receipt", style: TextStyle(color: Colors.white, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {bool required = false, int maxLines = 1, TextInputType? keyboardType}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      validator: (val) {
        if (required && (val == null || val.isEmpty)) {
          return "$label is required";
        }
        return null;
      },
    );
  }

  void _submitGRN() async {
    if (_formKey.currentState!.validate()) {
      final userId = context.read<PortalAuthProvider>().currentUser?.id;
      final grnData = {
        'poId': widget.po.id,
        'receivedDate': _receivedDate.toIso8601String(),
        'receivedById': userId,
        'invoiceNumber': _invoiceNumberController.text,
        'invoiceAmount': double.tryParse(_invoiceAmountController.text) ?? 0,
        'notes': _notesController.text,
      };

      final success = await context.read<ProcurementProvider>().recordGRN(grnData);
      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("GRN Recorded Successfully!")));
          Navigator.pop(context);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: ${context.read<ProcurementProvider>().error}")));
        }
      }
    }
  }
}

