import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:admin/constants.dart';
import 'package:admin/theme/app_theme.dart';
import 'package:admin/providers/inventory_provider.dart';
import 'package:admin/models/inventory_models.dart';
import 'package:admin/models/customer_project.dart';
import 'package:admin/services/crm_service.dart';

class AddStockAdjustmentScreen extends StatefulWidget {
  const AddStockAdjustmentScreen({super.key});

  @override
  State<AddStockAdjustmentScreen> createState() => _AddStockAdjustmentScreenState();
}

class _AddStockAdjustmentScreenState extends State<AddStockAdjustmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final CRMService _crmService = CRMService();
  
  List<CustomerProject> _projects = [];
  CustomerProject? _selectedProject;
  
  final _quantityController = TextEditingController();
  final _reasonController = TextEditingController();
  
  MaterialModel? _selectedMaterial;
  String _adjustmentType = 'WASTAGE';

  final List<String> _types = ['WASTAGE', 'THEFT', 'DAMAGE', 'CORRECTION', 'TRANSFER_OUT'];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final projectsResponse = await _crmService.getCustomerProjectsPaginated(page: 0, size: 100);
      setState(() {
        _projects = projectsResponse.data;
      });
      await context.read<InventoryProvider>().fetchMaterials();
    } catch (e) {
      debugPrint("Error loading data: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final materials = context.watch<InventoryProvider>().materials;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Stock Adjustment"),
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
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      DropdownButtonFormField<CustomerProject>(
                        value: _selectedProject,
                        decoration: const InputDecoration(labelText: "Project", prefixIcon: Icon(Icons.folder)),
                        items: _projects.map((p) => DropdownMenuItem(value: p, child: Text(p.name))).toList(),
                        onChanged: (val) => setState(() => _selectedProject = val),
                        validator: (val) => val == null ? "Required" : null,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<MaterialModel>(
                        value: _selectedMaterial,
                        decoration: const InputDecoration(labelText: "Material", prefixIcon: Icon(Icons.inventory)),
                        items: materials.map((m) => DropdownMenuItem(value: m, child: Text(m.name))).toList(),
                        onChanged: (val) => setState(() => _selectedMaterial = val),
                        validator: (val) => val == null ? "Required" : null,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _adjustmentType,
                        decoration: const InputDecoration(labelText: "Adjustment Type", prefixIcon: Icon(Icons.category)),
                        items: _types.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                        onChanged: (val) => setState(() => _adjustmentType = val!),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _quantityController,
                        decoration: const InputDecoration(labelText: "Quantity (use negative for reduction)", prefixIcon: Icon(Icons.numbers)),
                        keyboardType: TextInputType.number,
                        validator: (val) {
                          if (val == null || val.isEmpty) return "Required";
                          if (double.tryParse(val) == null) return "Invalid number";
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _reasonController,
                        decoration: const InputDecoration(labelText: "Reason / Notes", prefixIcon: Icon(Icons.note), border: OutlineInputBorder()),
                        maxLines: 3,
                        validator: (val) => (val == null || val.isEmpty) ? "Required" : null,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _saveAdjustment,
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.coralRed),
                  child: const Text("Record Adjustment", style: TextStyle(color: Colors.white, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _saveAdjustment() async {
    if (_formKey.currentState!.validate()) {
      final adjustment = StockAdjustment(
        projectId: _selectedProject!.id!,
        materialId: _selectedMaterial!.id!,
        adjustmentType: _adjustmentType,
        quantity: double.parse(_quantityController.text),
        reason: _reasonController.text,
      );

      final success = await context.read<InventoryProvider>().createStockAdjustment(adjustment);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Adjustment recorded successfully")));
        Navigator.pop(context);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: ${context.read<InventoryProvider>().error}")));
      }
    }
  }
}
