import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:admin/constants.dart';
import 'package:admin/theme/app_theme.dart';
import 'package:admin/providers/labour_provider.dart';
import 'package:admin/models/labour_models.dart';

class AddLabourScreen extends StatefulWidget {
  const AddLabourScreen({super.key});

  @override
  State<AddLabourScreen> createState() => _AddLabourScreenState();
}

class _AddLabourScreenState extends State<AddLabourScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _wageController = TextEditingController();
  final _idNumberController = TextEditingController();
  final _emergencyController = TextEditingController();
  String _tradeType = 'HELPER';
  String _idType = 'AADHAAR';

  final List<String> _trades = ['CARPENTER', 'PLUMBER', 'ELECTRICIAN', 'MASON', 'HELPER', 'CONTRACTOR'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Register New Worker")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(defaultPadding),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildTextField(_nameController, "Full Name", Icons.person, required: true),
              const SizedBox(height: 16),
              _buildTextField(_phoneController, "Phone Number", Icons.phone, required: true, keyboardType: TextInputType.phone),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _tradeType,
                decoration: const InputDecoration(labelText: "Trade Type", prefixIcon: Icon(Icons.handyman)),
                items: _trades.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                onChanged: (val) => setState(() => _tradeType = val!),
              ),
              const SizedBox(height: 16),
              _buildTextField(_wageController, "Daily Wage (₹)", Icons.currency_rupee, required: true, keyboardType: TextInputType.number),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _idType,
                      decoration: const InputDecoration(labelText: "ID Proof Type"),
                      items: ['AADHAAR', 'PAN', 'VOTER_ID'].map((i) => DropdownMenuItem(value: i, child: Text(i))).toList(),
                      onChanged: (val) => setState(() => _idType = val!),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: _buildTextField(_idNumberController, "ID Number", Icons.badge),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildTextField(_emergencyController, "Emergency Contact", Icons.contact_emergency),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _saveLabour,
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.coralRed),
                  child: const Text("Save Worker Profile", style: TextStyle(color: Colors.white, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {bool required = false, TextInputType? keyboardType}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
      ),
      validator: (val) => required && (val == null || val.isEmpty) ? "$label is required" : null,
    );
  }

  void _saveLabour() async {
    if (_formKey.currentState!.validate()) {
      final labour = Labour(
        name: _nameController.text,
        phone: _phoneController.text,
        tradeType: _tradeType,
        dailyWage: double.tryParse(_wageController.text) ?? 0,
        idProofType: _idType,
        idProofNumber: _idNumberController.text,
        emergencyContact: _emergencyController.text,
      );

      final success = await context.read<LabourProvider>().createLabour(labour);
      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Worker registered successfully!")));
          Navigator.pop(context);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: ${context.read<LabourProvider>().error}")));
        }
      }
    }
  }
}

