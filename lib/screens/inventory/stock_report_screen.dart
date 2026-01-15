import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:admin/constants.dart';
import 'package:admin/theme/app_theme.dart';
import 'package:admin/providers/inventory_provider.dart';
import 'package:admin/models/customer_project.dart';
import 'package:admin/services/crm_service.dart';
import 'package:admin/screens/inventory/add_stock_adjustment_screen.dart';
import 'package:admin/screens/inventory/material_consumption_screen.dart';

class StockReportScreen extends StatefulWidget {
  const StockReportScreen({super.key});

  @override
  State<StockReportScreen> createState() => _StockReportScreenState();
}

class _StockReportScreenState extends State<StockReportScreen> {
  final CRMService _crmService = CRMService();
  List<CustomerProject> _projects = [];
  CustomerProject? _selectedProject;

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  Future<void> _loadProjects() async {
    try {
      final response = await _crmService.getCustomerProjectsPaginated(page: 0, size: 100);
      setState(() {
        _projects = response.data;
      });
    } catch (e) {
      debugPrint("Error loading projects: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.all(defaultPadding),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    DropdownButtonFormField<CustomerProject>(
                      value: _selectedProject,
                      decoration: const InputDecoration(labelText: "Select Project for Stock View", prefixIcon: Icon(Icons.folder)),
                      items: _projects.map((p) => DropdownMenuItem(value: p, child: Text(p.name))).toList(),
                      onChanged: (val) {
                        setState(() => _selectedProject = val);
                        if (val != null) context.read<InventoryProvider>().fetchProjectStock(val.id!);
                      },
                    ),
                    if (_selectedProject != null) ...[
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => MaterialConsumptionScreen(
                                  projectId: _selectedProject!.id!,
                                  projectName: _selectedProject!.name,
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.analytics),
                          label: const Text('View Consumption & Wastage Report'),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Consumer<InventoryProvider>(
                builder: (context, provider, child) {
                  if (provider.isLoading) return const Center(child: CircularProgressIndicator());
                  if (_selectedProject == null) return const Center(child: Text("Select a project to see inventory."));
                  
                  final stock = provider.getStock(_selectedProject!.id!);
                  if (stock.isEmpty) return const Center(child: Text("No stock records for this site."));

                  return ListView.builder(
                    itemCount: stock.length,
                    itemBuilder: (context, index) {
                      final s = stock[index];
                      return Card(
                        child: ListTile(
                          title: Text(s.materialName ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text("Last updated: ${s.lastUpdated}"),
                          trailing: Text("${s.currentQuantity} ${s.unit ?? ''}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.primaryBlue)),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddStockAdjustmentScreen()),
          ).then((_) {
            if (_selectedProject != null) {
              context.read<InventoryProvider>().fetchProjectStock(_selectedProject!.id!);
            }
          });
        },
        label: const Text("Adjust Stock"),
        icon: const Icon(Icons.edit),
        backgroundColor: AppTheme.primaryBlue,
      ),
    );
  }
}

