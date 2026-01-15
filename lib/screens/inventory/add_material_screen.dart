import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:admin/constants.dart';
import 'package:admin/theme/app_theme.dart';
import 'package:admin/providers/inventory_provider.dart';
import 'package:admin/models/inventory_models.dart';

class AddMaterialScreen extends StatefulWidget {
  final MaterialModel? existingMaterial;
  const AddMaterialScreen({super.key, this.existingMaterial});

  @override
  State<AddMaterialScreen> createState() => _AddMaterialScreenState();
}

class _AddMaterialScreenState extends State<AddMaterialScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  String _category = 'CEMENT';
  String _unit = 'BAGS';

  final List<String> _categories = ['CEMENT', 'STEEL', 'BRICKS', 'ELECTRICAL', 'PLUMBING', 'FLOORING', 'PAINT'];
  final List<String> _units = ['BAGS', 'KG', 'TONS', 'CUM', 'SQM', 'NOS', 'RMT'];

  @override
  void initState() {
    super.initState();
    if (widget.existingMaterial != null) {
      final m = widget.existingMaterial!;
      _nameController.text = m.name;
      _category = m.category ?? 'CEMENT';
      _unit = m.unit ?? 'BAGS';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.existingMaterial == null ? "Add New Material" : "Edit Material")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(defaultPadding),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: "Material Name", prefixIcon: Icon(Icons.inventory), border: OutlineInputBorder()),
                validator: (val) => val == null || val.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _category,
                decoration: const InputDecoration(labelText: "Category"),
                items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (val) => setState(() => _category = val!),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _unit,
                decoration: const InputDecoration(labelText: "Standard Unit"),
                items: _units.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                onChanged: (val) => setState(() => _unit = val!),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _saveMaterial,
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.coralRed),
                  child: Text(widget.existingMaterial == null ? "Save Material" : "Update Material", style: const TextStyle(color: Colors.white, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _saveMaterial() async {
    if (_formKey.currentState!.validate()) {
      final material = MaterialModel(
        id: widget.existingMaterial?.id,
        name: _nameController.text,
        category: _category,
        unit: _unit,
      );

      bool success;
      if (widget.existingMaterial != null) {
        success = await context.read<InventoryProvider>().updateMaterial(widget.existingMaterial!.id!, material);
      } else {
        success = await context.read<InventoryProvider>().createMaterial(material);
      }
      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Material added successfully!")));
          Navigator.pop(context);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: ${context.read<InventoryProvider>().error}")));
        }
      }
    }
  }
}

