import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:admin/constants.dart';
import 'package:admin/theme/app_theme.dart';
import 'package:admin/providers/inventory_provider.dart';
import 'package:admin/models/inventory_models.dart';
import 'add_material_screen.dart';

class MaterialListScreen extends StatefulWidget {
  const MaterialListScreen({super.key});

  @override
  State<MaterialListScreen> createState() => _MaterialListScreenState();
}

class _MaterialListScreenState extends State<MaterialListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InventoryProvider>().fetchMaterials();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.all(defaultPadding),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Material Catalog", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ElevatedButton.icon(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AddMaterialScreen())),
                  icon: const Icon(Icons.add),
                  label: const Text("Add New Material"),
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.coralRed, foregroundColor: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Consumer<InventoryProvider>(
                builder: (context, provider, child) {
                  if (provider.isLoading) return const Center(child: CircularProgressIndicator());
                  if (provider.error != null) return Center(child: Text("Error: ${provider.error}"));
                  if (provider.materials.isEmpty) return const Center(child: Text("No materials in catalog."));

                  return ListView.builder(
                    itemCount: provider.materials.length,
                    itemBuilder: (context, index) {
                      final m = provider.materials[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: const CircleAvatar(child: Icon(Icons.category)),
                          title: Text(m.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text("${m.category} | Unit: ${m.unit}"),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.orange),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => AddMaterialScreen(existingMaterial: m)),
                                  );
                                },
                                tooltip: "Edit Material",
                              ),
                              IconButton(
                                icon: const Icon(Icons.block, color: Colors.red),
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text("Deactivate Material"),
                                      content: Text("Are you sure you want to deactivate '${m.name}'? "
                                          "It will no longer appear in selection lists."),
                                      actions: [
                                        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
                                        TextButton(
                                          onPressed: () async {
                                            Navigator.pop(context);
                                            final success = await provider.deactivateMaterial(m.id!);
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                                content: Text(success ? "Material deactivated" : "Error: ${provider.error}"),
                                              ));
                                            }
                                          },
                                          child: const Text("Deactivate", style: TextStyle(color: Colors.red)),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                                tooltip: "Deactivate Material",
                              ),
                            ],
                          ),
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
    );
  }
}
