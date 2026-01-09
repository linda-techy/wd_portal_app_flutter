import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:admin/constants.dart';
import 'package:admin/theme/app_theme.dart';
import 'package:admin/providers/procurement_provider.dart';
import 'package:admin/models/procurement_models.dart';

import 'package:admin/screens/procurement/add_purchase_order_screen.dart';
import 'package:admin/screens/procurement/record_grn_screen.dart';


class PurchaseOrderListScreen extends StatefulWidget {
  const PurchaseOrderListScreen({super.key});

  @override
  State<PurchaseOrderListScreen> createState() => _PurchaseOrderListScreenState();
}

class _PurchaseOrderListScreenState extends State<PurchaseOrderListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _statusFilter = 'All';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProcurementProvider>().fetchPurchaseOrders();
    });
    _searchController.addListener(() {
      setState(() {}); // Rebuild to filter
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
                  "Purchase Orders",
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.deepSlate,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AddPurchaseOrderScreen()),
                    );
                  },
                  icon: const Icon(Icons.add),
                  label: const Text("Create PO"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.coralRed,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: defaultPadding),
            
            // Search and Filter Bar
            Card(
              elevation: 0,
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: _searchController,
                        decoration: const InputDecoration(
                          hintText: "Search PO Number, Vendor, or Project...",
                          prefixIcon: Icon(Icons.search),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _statusFilter,
                        items: const [
                          DropdownMenuItem(value: 'All', child: Text("All Status")),
                          DropdownMenuItem(value: 'DRAFT', child: Text("Draft")),
                          DropdownMenuItem(value: 'ISSUED', child: Text("Issued")),
                          DropdownMenuItem(value: 'RECEIVED', child: Text("Received")),
                          DropdownMenuItem(value: 'CANCELLED', child: Text("Cancelled")),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => _statusFilter = val);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: defaultPadding),

            Expanded(
              child: Consumer<ProcurementProvider>(
                builder: (context, provider, child) {
                  if (provider.isLoading) return const Center(child: CircularProgressIndicator());
                  if (provider.error != null) return Center(child: Text("Error: ${provider.error}", style: const TextStyle(color: Colors.red)));
                  if (provider.purchaseOrders.isEmpty) return const Center(child: Text("No Purchase Orders found."));

                  // Filter Logic
                  final filteredList = provider.purchaseOrders.where((po) {
                    final matchesSearch = (po.poNumber?.toLowerCase() ?? "").contains(_searchController.text.toLowerCase()) ||
                                          (po.vendorName?.toLowerCase() ?? "").contains(_searchController.text.toLowerCase()) ||
                                          (po.projectName?.toLowerCase() ?? "").contains(_searchController.text.toLowerCase());
                    final matchesStatus = _statusFilter == 'All' || po.status == _statusFilter;
                    return matchesSearch && matchesStatus;
                  }).toList();

                  if (filteredList.isEmpty) return const Center(child: Text("No matching Purchase Orders found."));

                  return ListView.builder(
                    itemCount: filteredList.length,
                    itemBuilder: (context, index) {
                      final po = filteredList[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          title: Text(po.poNumber ?? "PO-${po.id}", style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text("${po.vendorName} | ${po.projectName}"),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text("₹${po.netAmount.toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.bold)),
                                  Text(po.status, style: TextStyle(color: _getStatusColor(po.status), fontSize: 12)),
                                ],
                              ),
                              if (po.status != 'RECEIVED') 
                                IconButton(
                                  icon: const Icon(Icons.inventory, color: AppTheme.primaryBlue),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => RecordGRNScreen(po: po)),
                                    );
                                  },
                                  tooltip: "Record Receipt",
                                ),
                              if (po.status == 'DRAFT' || po.status == 'ISSUED') ...[
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.orange),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => AddPurchaseOrderScreen(existingPO: po)),
                                    );
                                  },
                                  tooltip: "Edit PO",
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text("Delete Purchase Order"),
                                        content: const Text("Are you sure you want to delete this PO? This action cannot be undone."),
                                        actions: [
                                          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
                                          TextButton(
                                            onPressed: () async {
                                              Navigator.pop(context);
                                              final success = await provider.deletePurchaseOrder(po.id!);
                                              if (context.mounted) {
                                                if (success) {
                                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("PO Deleted Successfully")));
                                                } else {
                                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: ${provider.error}")));
                                                }
                                              }
                                            },
                                            child: const Text("Delete", style: TextStyle(color: Colors.red)),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                  tooltip: "Delete PO",
                                ),
                              ],
                              // Close button - only for RECEIVED status
                              if (po.status == 'RECEIVED')
                                IconButton(
                                  icon: const Icon(Icons.check_circle, color: Colors.green),
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text("Close Purchase Order"),
                                        content: const Text("This will mark the PO as fully processed. Continue?"),
                                        actions: [
                                          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
                                          TextButton(
                                            onPressed: () async {
                                              Navigator.pop(context);
                                              final success = await provider.closePurchaseOrder(po.id!);
                                              if (context.mounted) {
                                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                                  content: Text(success ? "PO Closed Successfully" : "Error: ${provider.error}"),
                                                ));
                                              }
                                            },
                                            child: const Text("Close PO", style: TextStyle(color: Colors.green)),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                  tooltip: "Close PO",
                                ),
                            ],
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => AddPurchaseOrderScreen(existingPO: po)),
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

  Color _getStatusColor(String status) {
    switch (status) {
      case 'DRAFT': return Colors.grey;
      case 'ISSUED': return Colors.blue;
      case 'RECEIVED': return Colors.green;
      case 'CANCELLED': return Colors.red;
      default: return Colors.black;
    }
  }
}
