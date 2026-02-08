import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:admin/constants.dart';
import 'package:admin/theme/app_theme.dart';
import 'package:admin/providers/procurement_provider.dart';
import 'package:admin/providers/portal_auth_provider.dart';
import 'package:admin/models/procurement_models.dart';
import 'package:admin/models/customer_project.dart';
import 'package:admin/services/crm_service.dart';
import 'package:admin/providers/inventory_provider.dart';
import 'package:admin/models/inventory_models.dart';
import 'package:intl/intl.dart';

class AddPurchaseOrderScreen extends StatefulWidget {
  final PurchaseOrder? existingPO;
  const AddPurchaseOrderScreen({super.key, this.existingPO});

  @override
  State<AddPurchaseOrderScreen> createState() => _AddPurchaseOrderScreenState();
}

class _AddPurchaseOrderScreenState extends State<AddPurchaseOrderScreen> {
  final _formKey = GlobalKey<FormState>();
  final CRMService _crmService = CRMService();
  
  List<CustomerProject> _projects = [];
  CustomerProject? _selectedProject;
  Vendor? _selectedVendor;
  DateTime _poDate = DateTime.now();
  DateTime? _expectedDeliveryDate;
  final _notesController = TextEditingController();

  List<PORow> _items = [PORow()];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    try {
      final projectsResponse = await _crmService.getCustomerProjectsPaginated(page: 0, size: 100);
      setState(() {
        _projects = projectsResponse.data;
      });
      if (mounted) {
        await context.read<ProcurementProvider>().fetchVendors();
      }
      if (mounted) {
        await context.read<InventoryProvider>().fetchMaterials();
      }

      // Populate if editing
      if (widget.existingPO != null) {
        final po = widget.existingPO!;
        setState(() {
          _selectedProject = _projects.firstWhere((p) => p.id == po.projectId, orElse: () => _projects.first); // Fallback safe
          try {
             final vendors = context.read<ProcurementProvider>().vendors;
             _selectedVendor = vendors.firstWhere((v) => v.id == po.vendorId);
          } catch (e) {
            // Vendor might not be in loaded list if paginated or inactive
          }
           _poDate = po.poDate;
           _expectedDeliveryDate = po.expectedDeliveryDate;
           _notesController.text = po.notes ?? '';
           
           if (po.items.isNotEmpty) {
             _items = po.items.map((item) {
               final row = PORow();
               row.description = item.description;
               row.quantity = item.quantity;
               row.rate = item.rate;
               row.gstPercentage = item.gstPercentage;
               // Material linking is tricky without full object, we skip pre-selecting material dropdown for now
               return row;
             }).toList();
           }
        });
      }
    } catch (e) {
      debugPrint("Error loading data: $e");
    }
  }

  double get _totalAmount => _items.fold(0, (sum, item) => sum + item.amount);
  double get _gstAmount => _items.fold(0, (sum, item) => sum + (item.amount * item.gstPercentage / 100));
  double get _netAmount => _totalAmount + _gstAmount;

  @override
  Widget build(BuildContext context) {
    final vendors = context.watch<ProcurementProvider>().vendors;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingPO == null ? "Create Purchase Order" : "Edit Purchase Order"),
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
              // Header Section
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
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<Vendor>(
                      value: _selectedVendor,
                      decoration: const InputDecoration(labelText: "Vendor", prefixIcon: Icon(Icons.business)),
                      items: vendors.map((v) => DropdownMenuItem(value: v, child: Text(v.name))).toList(),
                      onChanged: (val) => setState(() => _selectedVendor = val),
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      title: const Text("Expected Delivery Date"),
                      subtitle: Text(_expectedDeliveryDate == null ? "Not Selected" : DateFormat('dd-MM-yyyy').format(_expectedDeliveryDate!)),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now().add(const Duration(days: 7)),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (picked != null) setState(() => _expectedDeliveryDate = picked);
                      },
                    ),
                  ],
                ),
              ),
            ),
              const SizedBox(height: 24),
              // Items Section
              Text("Line Items", style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              ..._items.asMap().entries.map((entry) => _buildItemRow(entry.key, entry.value)),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () => setState(() => _items.add(PORow())),
                icon: const Icon(Icons.add),
                label: const Text("Add Item"),
              ),
              const SizedBox(height: 24),
              // Summary Section
              Card(
                color: AppTheme.surfaceElevated,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                  children: [
                    _buildSummaryRow("Subtotal", _totalAmount),
                    _buildSummaryRow("GST Amount", _gstAmount),
                    const Divider(),
                    _buildSummaryRow("Net Total", _netAmount, isBold: true),
                  ],
                ),
              ),
            ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(labelText: "Notes", border: OutlineInputBorder()),
                maxLines: 3,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _savePO,
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.coralRed),
                  child: Text(widget.existingPO == null ? "Create PO" : "Update PO", style: const TextStyle(color: Colors.white, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildItemRow(int index, PORow row) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    children: [
                      Consumer<InventoryProvider>(
                        builder: (context, invProvider, child) {
                          return DropdownButtonFormField<MaterialModel>(
                            value: row.selectedMaterial,
                            decoration: const InputDecoration(labelText: "Link to Catalog Material (Optional)", prefixIcon: Icon(Icons.inventory)),
                            items: invProvider.materials.map((m) => DropdownMenuItem(value: m, child: Text(m.name))).toList(),
                            onChanged: (val) {
                              setState(() {
                                row.selectedMaterial = val;
                                if (val != null && (row.description.isEmpty)) {
                                  row.description = val.name;
                                }
                              });
                            },
                          );
                        },
                      ),
                      TextFormField(
                    initialValue: row.description,
                    decoration: const InputDecoration(labelText: "Description"),
                    onChanged: (val) => row.description = val,
                  ),
                    ],
                  ),
                ),

                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => setState(() => _items.removeAt(index)),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(child: _buildNumField("Qty", row.quantity, (v) => setState(() => row.quantity = v))),
                const SizedBox(width: 8),
                Expanded(child: _buildNumField("Rate", row.rate, (v) => setState(() => row.rate = v))),
                const SizedBox(width: 8),
                Expanded(child: _buildNumField("GST %", row.gstPercentage, (v) => setState(() => row.gstPercentage = v))),
              ],
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: Text("Amount: ₹${row.amount.toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNumField(String label, double val, Function(double) onChanged) {
    return TextFormField(
      initialValue: val.toString(),
      decoration: InputDecoration(labelText: label),
      keyboardType: TextInputType.number,
      onChanged: (v) => onChanged(double.tryParse(v) ?? 0),
    );
  }

  Widget _buildSummaryRow(String label, double amount, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text("₹${amount.toStringAsFixed(2)}", style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }

  void _savePO() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedProject == null || _selectedVendor == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select Project and Vendor")));
        return;
      }

      final userId = context.read<PortalAuthProvider>().currentUser?.id;
      final po = PurchaseOrder(
        id: widget.existingPO?.id, // ID required for update
        createdById: userId,
        projectId: _selectedProject!.id ?? 0,
        projectName: _selectedProject!.name,
        vendorId: _selectedVendor!.id,
        vendorName: _selectedVendor!.name,
        poDate: _poDate,
        expectedDeliveryDate: _expectedDeliveryDate,
        totalAmount: _totalAmount,
        gstAmount: _gstAmount,
        netAmount: _netAmount,
        status: widget.existingPO?.status ?? 'DRAFT', // Keep status if editing
        notes: _notesController.text,
        items: _items.map((item) => PurchaseOrderItem(
          description: item.description,
          quantity: item.quantity,
          unit: 'NOS', // Default for now
          rate: item.rate,
          gstPercentage: item.gstPercentage,
          amount: item.amount,
          materialId: item.selectedMaterial?.id,
        )).toList(),
      );
      
      bool success;
      if (widget.existingPO != null) {
         success = await context.read<ProcurementProvider>().updatePurchaseOrder(widget.existingPO!.id!, po);
      } else {
         success = await context.read<ProcurementProvider>().createPurchaseOrder(po);
      }

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(widget.existingPO != null ? "PO Updated Successfully!" : "PO Created Successfully!")));
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

class PORow {
  String description = '';
  double quantity = 0;
  double rate = 0;
  double gstPercentage = 18;
  MaterialModel? selectedMaterial;
  double get amount => quantity * rate;
}

