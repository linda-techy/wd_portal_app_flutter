import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:admin/constants.dart';
import 'package:admin/theme/app_theme.dart';
import 'package:admin/providers/procurement_provider.dart';
import 'package:admin/models/procurement_models.dart';

class AddVendorScreen extends StatefulWidget {
  final Vendor? existingVendor;
  const AddVendorScreen({super.key, this.existingVendor});

  @override
  State<AddVendorScreen> createState() => _AddVendorScreenState();
}

class _AddVendorScreenState extends State<AddVendorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _contactPersonController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _gstinController = TextEditingController();
  final _addressController = TextEditingController();
  String _vendorType = 'MATERIAL';

  @override
  void initState() {
    super.initState();
    // Pre-fill form if editing existing vendor
    if (widget.existingVendor != null) {
      final v = widget.existingVendor!;
      _nameController.text = v.name;
      _contactPersonController.text = v.contactName ?? '';
      _phoneController.text = v.phone ?? '';
      _emailController.text = v.email ?? '';
      _gstinController.text = v.gstNumber ?? '';
      _addressController.text = v.address ?? '';
      _vendorType = v.vendorType ?? 'MATERIAL';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingVendor == null ? "Add New Vendor" : "Edit Vendor"),
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
              _buildTextField(_nameController, "Vendor Name", Icons.business, required: true),
              const SizedBox(height: 16),
              _buildTextField(_contactPersonController, "Contact Person", Icons.person),
              const SizedBox(height: 16),
              _buildTextField(_phoneController, "Phone", Icons.phone, required: true),
              const SizedBox(height: 16),
              _buildTextField(_emailController, "Email", Icons.email),
              const SizedBox(height: 16),
              _buildTextField(_gstinController, "GSTIN", Icons.receipt_long),
              const SizedBox(height: 16),
              _buildTextField(_addressController, "Address", Icons.location_on, maxLines: 3),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _vendorType,
                decoration: InputDecoration(
                  labelText: "Vendor Type",
                  prefixIcon: const Icon(Icons.category),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                items: ['MATERIAL', 'LABOUR', 'SERVICES'].map((String type) {
                  return DropdownMenuItem(value: type, child: Text(type));
                }).toList(),
                onChanged: (val) => setState(() => _vendorType = val!),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _saveVendor,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlue,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text(widget.existingVendor == null ? "Save Vendor" : "Update Vendor", style: const TextStyle(color: Colors.white, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {bool required = false, int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
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

  void _saveVendor() async {
    if (_formKey.currentState!.validate()) {
      final vendor = Vendor(
        id: widget.existingVendor?.id ?? 0,
        name: _nameController.text,
        contactName: _contactPersonController.text,
        phone: _phoneController.text,
        email: _emailController.text,
        gstNumber: _gstinController.text.toUpperCase(),
        address: _addressController.text,
        vendorType: _vendorType,
        status: 'ACTIVE',
      );

      bool success;
      if (widget.existingVendor != null) {
        success = await context.read<ProcurementProvider>().updateVendor(widget.existingVendor!.id!, vendor);
      } else {
        success = await context.read<ProcurementProvider>().createVendor(vendor);
      }
      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Vendor added successfully!")),
          );
          Navigator.pop(context);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error: ${context.read<ProcurementProvider>().error}")),
          );
        }
      }
    }
  }
}

