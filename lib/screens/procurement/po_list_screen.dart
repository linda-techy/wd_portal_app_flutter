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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProcurementProvider>().fetchPurchaseOrders();
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
            Expanded(
              child: Consumer<ProcurementProvider>(
                builder: (context, provider, child) {
                  if (provider.isLoading) return const Center(child: CircularProgressIndicator());
                  if (provider.error != null) return Center(child: Text("Error: ${provider.error}", style: const TextStyle(color: Colors.red)));
                  if (provider.purchaseOrders.isEmpty) return const Center(child: Text("No Purchase Orders found."));

                  return ListView.builder(
                    itemCount: provider.purchaseOrders.length,
                    itemBuilder: (context, index) {
                      final po = provider.purchaseOrders[index];
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
                            ],
                          ),
                          onTap: () {
                            // View Details
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
