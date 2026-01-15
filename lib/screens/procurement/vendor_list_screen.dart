import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:admin/constants.dart';
import 'package:admin/theme/app_theme.dart';
import 'package:admin/providers/procurement_provider.dart';
import 'package:admin/models/procurement_models.dart';
import 'package:admin/screens/procurement/add_vendor_screen.dart';

class VendorListScreen extends StatefulWidget {
  const VendorListScreen({super.key});

  @override
  State<VendorListScreen> createState() => _VendorListScreenState();
}

class _VendorListScreenState extends State<VendorListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProcurementProvider>().fetchVendors();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.all(defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Vendor Directory",
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.deepSlate,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AddVendorScreen()),
                    );
                  },
                  icon: const Icon(Icons.add),
                  label: const Text("Add Vendor"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.coralRed,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: defaultPadding),
            Expanded(
              child: Consumer<ProcurementProvider>(
                builder: (context, provider, child) {
                  if (provider.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (provider.error != null) {
                    return Center(
                      child: Text(
                        "Error: ${provider.error}",
                        style: const TextStyle(color: Colors.red),
                      ),
                    );
                  }

                  if (provider.vendors.isEmpty) {
                    return const Center(
                      child: Text("No vendors found. Add your first vendor!"),
                    );
                  }

                  return ListView.builder(
                    itemCount: provider.vendors.length,
                    itemBuilder: (context, index) {
                      final vendor = provider.vendors[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          title: Text(vendor.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text("${vendor.vendorType} | ${vendor.phone}"),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.orange),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => AddVendorScreen(existingVendor: vendor)),
                                  );
                                },
                                tooltip: "Edit Vendor",
                              ),
                              IconButton(
                                icon: const Icon(Icons.block, color: Colors.red),
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text("Deactivate Vendor"),
                                      content: Text("Are you sure you want to deactivate '${vendor.name}'? "
                                          "This vendor will no longer appear in selection lists."),
                                      actions: [
                                        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
                                        TextButton(
                                          onPressed: () async {
                                            Navigator.pop(context);
                                            final success = await provider.deactivateVendor(vendor.id!);
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                                content: Text(success ? "Vendor deactivated" : "Error: ${provider.error}"),
                                              ));
                                            }
                                          },
                                          child: const Text("Deactivate", style: TextStyle(color: Colors.red)),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                                tooltip: "Deactivate Vendor",
                              ),
                            ],
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => AddVendorScreen(existingVendor: vendor)),
                            );
                          },
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

