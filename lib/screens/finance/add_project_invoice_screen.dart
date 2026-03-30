import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:admin/theme/app_theme.dart';
import 'package:admin/utils/error_handler.dart';
import 'package:admin/providers/finance_provider.dart';
import 'package:admin/models/finance_models.dart';
import 'package:admin/models/customer_project.dart';
import 'package:admin/services/crm_service.dart';
import 'package:admin/config/app_config.dart';
import 'package:intl/intl.dart';

class AddProjectInvoiceScreen extends StatefulWidget {
  const AddProjectInvoiceScreen({super.key});

  @override
  State<AddProjectInvoiceScreen> createState() =>
      _AddProjectInvoiceScreenState();
}

class _AddProjectInvoiceScreenState extends State<AddProjectInvoiceScreen> {
  final _formKey = GlobalKey<FormState>();
  CustomerProject? _selectedProject;
  List<CustomerProject> _projects = [];

  final TextEditingController _subTotalController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  DateTime _invoiceDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  Future<void> _loadProjects() async {
    try {
      final projectsResponse =
          await CRMService().getCustomerProjectsPaginated(page: 0, size: 100);
      setState(() {
        _projects = projectsResponse.data;
      });
    } catch (e) {
      debugPrint("Error loading projects: $e");
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _invoiceDate,
      firstDate: AppConfig.datePickerFirstDate,
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != _invoiceDate) {
      setState(() {
        _invoiceDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Create Customer Invoice")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<CustomerProject>(
                value: _selectedProject,
                decoration: const InputDecoration(
                    labelText: "Select Project",
                    prefixIcon: Icon(Icons.business)),
                items: _projects
                    .map((p) => DropdownMenuItem(value: p, child: Text(p.name)))
                    .toList(),
                onChanged: (val) => setState(() => _selectedProject = val),
                validator: (val) =>
                    val == null ? "Please select a project" : null,
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text("Invoice Date"),
                subtitle: Text(DateFormat('yyyy-MM-dd').format(_invoiceDate)),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => _selectDate(context),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _subTotalController,
                decoration: const InputDecoration(
                    labelText: "Subtotal (₹)", prefixIcon: Icon(Icons.money)),
                keyboardType: TextInputType.number,
                validator: (val) =>
                    val == null || val.isEmpty ? "Please enter amount" : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                    labelText: "Notes", prefixIcon: Icon(Icons.note)),
                maxLines: 3,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _submitForm,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: WalldotColors.primary),
                  child: const Text("Generate Invoice",
                      style: TextStyle(color: Colors.white, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      try {
        final subTotal = double.parse(_subTotalController.text);
        final gstAmount = subTotal * 0.18;
        final totalAmount = subTotal + gstAmount;

        final invoice = ProjectInvoice(
          projectId: _selectedProject!.id!,
          invoiceDate: DateFormat('yyyy-MM-dd').format(_invoiceDate),
          subTotal: subTotal,
          gstPercentage: 18.0,
          gstAmount: gstAmount,
          totalAmount: totalAmount,
          notes: _notesController.text,
        );

        await context.read<FinanceProvider>().createInvoice(invoice);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Invoice generated successfully")));
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
