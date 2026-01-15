import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:admin/constants.dart';
import 'package:admin/theme/app_theme.dart';
import 'package:admin/providers/finance_provider.dart';
import 'package:admin/models/finance_models.dart';
import 'package:admin/screens/finance/add_project_invoice_screen.dart';
import 'package:intl/intl.dart';

class FinanceDashboardScreen extends StatefulWidget {
  const FinanceDashboardScreen({super.key});

  @override
  State<FinanceDashboardScreen> createState() => _FinanceDashboardScreenState();
}

class _FinanceDashboardScreenState extends State<FinanceDashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Finance & Billing"),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "Project Invoices", icon: Icon(Icons.receipt_long)),
            Tab(text: "Vendor Bills", icon: Icon(Icons.shopping_cart)),
            Tab(text: "Labour Payments", icon: Icon(Icons.engineering)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          const ProjectInvoicesTab(),
          const VendorBillsTab(),
          const LabourPaymentsTab(),
        ],
      ),
    );
  }
}

class ProjectInvoicesTab extends StatelessWidget {
  const ProjectInvoicesTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Client Receivables", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AddProjectInvoiceScreen()),
                  );
                },
                icon: const Icon(Icons.add),
                label: const Text("New Invoice"),
                style: ElevatedButton.styleFrom(backgroundColor: WalldotColors.primary),
              ),
            ],
          ),
        ),
        Expanded(
          child: Consumer<FinanceProvider>(
            builder: (context, provider, child) {
              if (provider.isLoading) return const Center(child: CircularProgressIndicator());
              if (provider.projectInvoices.isEmpty) return const Center(child: Text("No invoices found"));

              return ListView.builder(
                itemCount: provider.projectInvoices.length,
                itemBuilder: (context, index) {
                  final inv = provider.projectInvoices[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: ListTile(
                      title: Text(inv.invoiceNumber ?? "Draft"),
                      subtitle: Text("Project: ${inv.projectName}\nDate: ${inv.invoiceDate}"),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text("₹${inv.totalAmount.toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text(inv.status, style: TextStyle(color: inv.status == 'PAID' ? Colors.green : Colors.orange)),
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
    );
  }
}

class VendorBillsTab extends StatelessWidget {
  const VendorBillsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text("Vendor Bills Management Coming Soon"));
  }
}

class LabourPaymentsTab extends StatelessWidget {
  const LabourPaymentsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text("Labour Payments Management Coming Soon"));
  }
}

