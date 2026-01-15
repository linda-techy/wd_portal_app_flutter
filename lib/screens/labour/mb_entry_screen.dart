import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:admin/constants.dart';
import 'package:admin/theme/app_theme.dart';
import 'package:admin/providers/labour_provider.dart';
import 'package:admin/models/labour_models.dart';
import 'package:admin/models/customer_project.dart';

class MBEntryScreen extends StatefulWidget {
  final CustomerProject project;
  const MBEntryScreen({super.key, required this.project});

  @override
  State<MBEntryScreen> createState() => _MBEntryScreenState();
}

class _MBEntryScreenState extends State<MBEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descController = TextEditingController();
  final _lController = TextEditingController(text: '0');
  final _bController = TextEditingController(text: '0');
  final _dController = TextEditingController(text: '0');
  final _qtyController = TextEditingController(text: '0');
  final _rateController = TextEditingController(text: '0');
  String _unit = 'SFT';
  Labour? _selectedLabour;

  @override
  void initState() {
    super.initState();
    context.read<LabourProvider>().fetch();
    _lController.addListener(_calculateQty);
    _bController.addListener(_calculateQty);
    _dController.addListener(_calculateQty);
  }

  void _calculateQty() {
    double l = double.tryParse(_lController.text) ?? 0;
    double b = double.tryParse(_bController.text) ?? 0;
    double d = double.tryParse(_dController.text) ?? 0;

    // If all 3 are 0, might be manual entry, otherwise multiply
    if (l != 0 || b != 0 || d != 0) {
      double qty = (l == 0 ? 1 : l) * (b == 0 ? 1 : b) * (d == 0 ? 1 : d);
      _qtyController.text = qty.toStringAsFixed(2);
    }
  }

  double get _totalAmount =>
      (double.tryParse(_qtyController.text) ?? 0) *
      (double.tryParse(_rateController.text) ?? 0);

  @override
  Widget build(BuildContext context) {
    final labourList = context.watch<LabourProvider>().items;

    return Scaffold(
      appBar: AppBar(title: Text("New MB Entry - ${widget.project.name}")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(defaultPadding),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTextField(
                  _descController, "Work Description", Icons.description,
                  required: true),
              const SizedBox(height: 16),
              DropdownButtonFormField<Labour>(
                value: _selectedLabour,
                decoration: const InputDecoration(
                    labelText: "Labour/Group (Optional)",
                    prefixIcon: Icon(Icons.people)),
                items: labourList
                    .map((l) => DropdownMenuItem(value: l, child: Text(l.name)))
                    .toList(),
                onChanged: (val) => setState(() => _selectedLabour = val),
              ),
              const SizedBox(height: 24),
              const Text("Dimensions",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: _buildNumField(_lController, "Length")),
                  const SizedBox(width: 8),
                  Expanded(child: _buildNumField(_bController, "Breadth")),
                  const SizedBox(width: 8),
                  Expanded(child: _buildNumField(_dController, "Depth/H")),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                      child: _buildNumField(_qtyController, "Quantity",
                          required: true)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _unit,
                      decoration: const InputDecoration(labelText: "Unit"),
                      items: ['SFT', 'CFT', 'SQM', 'CUM', 'RMT', 'NOS']
                          .map(
                              (u) => DropdownMenuItem(value: u, child: Text(u)))
                          .toList(),
                      onChanged: (val) => setState(() => _unit = val!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildNumField(_rateController, "Unit Rate (₹)", required: true),
              const SizedBox(height: 24),
              Card(
                color: AppTheme.surfaceElevated,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Total Final Amount",
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      Text("₹${_totalAmount.toStringAsFixed(2)}",
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: AppTheme.deepSlate)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _saveMB,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.coralRed),
                  child: const Text("Commit MB Record",
                      style: TextStyle(color: Colors.white, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
      TextEditingController controller, String label, IconData icon,
      {bool required = false}) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: const OutlineInputBorder()),
      validator: (val) => required && (val == null || val.isEmpty)
          ? "$label is required"
          : null,
    );
  }

  Widget _buildNumField(TextEditingController controller, String label,
      {bool required = false}) {
    return TextFormField(
      controller: controller,
      onChanged: (v) => setState(() {}),
      keyboardType: TextInputType.number,
      decoration:
          InputDecoration(labelText: label, border: const OutlineInputBorder()),
      validator: (val) => required && (val == null || val.isEmpty)
          ? "$label is required"
          : null,
    );
  }

  void _saveMB() async {
    if (_formKey.currentState!.validate()) {
      final mb = MeasurementBook(
        projectId: widget.project.id!,
        labourId: _selectedLabour?.id,
        description: _descController.text,
        measurementDate: DateTime.now().toIso8601String().split('T')[0],
        length: double.tryParse(_lController.text) ?? 0,
        breadth: double.tryParse(_bController.text) ?? 0,
        depth: double.tryParse(_dController.text) ?? 0,
        quantity: double.tryParse(_qtyController.text) ?? 0,
        unit: _unit,
        rate: double.tryParse(_rateController.text) ?? 0,
        totalAmount: _totalAmount,
      );

      final success = await context.read<LabourProvider>().createMBEntry(mb);
      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text("MB Entry saved!")));
          Navigator.pop(context);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text("Error: ${context.read<LabourProvider>().error}")));
        }
      }
    }
  }
}
