import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:admin/constants.dart';
import 'package:admin/theme/app_theme.dart';
import 'package:admin/providers/finance_provider.dart';
import 'package:admin/models/finance_models.dart';
import 'package:admin/models/customer_project.dart';
import 'package:admin/services/crm_service.dart';
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
        children: const [
          ProjectInvoicesTab(),
          VendorBillsTab(),
          LabourPaymentsTab(),
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
                          Text("\u20B9${inv.totalAmount.toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.bold)),
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

class VendorBillsTab extends StatefulWidget {
  const VendorBillsTab({super.key});

  @override
  State<VendorBillsTab> createState() => _VendorBillsTabState();
}

class _VendorBillsTabState extends State<VendorBillsTab> {
  final CRMService _crmService = CRMService();
  final _currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '\u20B9');

  List<CustomerProject> _projects = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  Future<void> _loadProjects() async {
    try {
      final projects = await _crmService.getAllCustomerProjects();
      setState(() {
        _projects = projects;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              const Text("Vendor Bills / Purchase Invoices", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: _isLoading ? null : () => _showRecordBillDialog(),
                icon: const Icon(Icons.add, size: 18),
                label: const Text("Record Bill"),
                style: ElevatedButton.styleFrom(backgroundColor: primaryColor, foregroundColor: Colors.white),
              ),
            ],
          ),
        ),
        Expanded(
          child: Consumer<FinanceProvider>(
            builder: (context, provider, child) {
              if (provider.purchaseInvoices.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.shopping_cart_outlined, size: 48, color: Colors.grey[400]),
                      const SizedBox(height: 8),
                      const Text("No vendor bills recorded yet", style: TextStyle(color: textSecondary)),
                      const SizedBox(height: 4),
                      const Text("Use 'Record Bill' to add vendor purchase invoices", style: TextStyle(fontSize: 12, color: textMuted)),
                    ],
                  ),
                );
              }

              return ListView.builder(
                itemCount: provider.purchaseInvoices.length,
                itemBuilder: (context, index) {
                  final bill = provider.purchaseInvoices[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: infoColor.withOpacity(0.1),
                        child: const Icon(Icons.store, color: infoColor),
                      ),
                      title: Text(bill.vendorName ?? 'Vendor #${bill.vendorId}', style: const TextStyle(fontWeight: FontWeight.w500)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Invoice: ${bill.vendorInvoiceNumber}', style: const TextStyle(fontSize: 12)),
                          Text('Project: ${bill.projectName ?? '#${bill.projectId}'} | Date: ${bill.invoiceDate}',
                              style: const TextStyle(fontSize: 12, color: textSecondary)),
                        ],
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(_currencyFormat.format(bill.amount), style: const TextStyle(fontWeight: FontWeight.bold)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: bill.status == 'PAID' ? boxSuccess : boxWarning,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(bill.status, style: TextStyle(
                              fontSize: 11,
                              color: bill.status == 'PAID' ? successColor : warningColor,
                            )),
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
    );
  }

  void _showRecordBillDialog() {
    final vendorIdCtrl = TextEditingController();
    final invoiceNumCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    final dateCtrl = TextEditingController(text: DateFormat('yyyy-MM-dd').format(DateTime.now()));
    CustomerProject? selectedProject;
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Record Vendor Bill'),
          content: SizedBox(
            width: 450,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<CustomerProject>(
                      value: selectedProject,
                      decoration: const InputDecoration(labelText: 'Project *', border: OutlineInputBorder()),
                      items: _projects.map((p) => DropdownMenuItem(
                        value: p,
                        child: Text(p.projectName.isNotEmpty ? p.projectName : 'Project #${p.id}', overflow: TextOverflow.ellipsis),
                      )).toList(),
                      onChanged: (v) => setDialogState(() => selectedProject = v),
                      validator: (v) => v == null ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: vendorIdCtrl,
                      decoration: const InputDecoration(labelText: 'Vendor ID *', border: OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: invoiceNumCtrl,
                      decoration: const InputDecoration(labelText: 'Vendor Invoice Number *', border: OutlineInputBorder()),
                      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: amountCtrl,
                      decoration: const InputDecoration(labelText: 'Amount (\u20B9) *', border: OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                      validator: (v) => v == null || v.isEmpty || double.tryParse(v) == null ? 'Enter valid amount' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: dateCtrl,
                      decoration: const InputDecoration(labelText: 'Invoice Date *', border: OutlineInputBorder()),
                      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                final bill = PurchaseInvoice(
                  vendorId: int.parse(vendorIdCtrl.text),
                  projectId: selectedProject!.id!,
                  vendorInvoiceNumber: invoiceNumCtrl.text.trim(),
                  invoiceDate: dateCtrl.text.trim(),
                  amount: double.parse(amountCtrl.text),
                );
                try {
                  await Provider.of<FinanceProvider>(context, listen: false).recordVendorBill(bill);
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Vendor bill recorded'), backgroundColor: successColor),
                    );
                  }
                } catch (e) {
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(content: Text('Error: $e'), backgroundColor: errorColor),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: primaryColor, foregroundColor: Colors.white),
              child: const Text('Record'),
            ),
          ],
        ),
      ),
    );
  }
}

class LabourPaymentsTab extends StatefulWidget {
  const LabourPaymentsTab({super.key});

  @override
  State<LabourPaymentsTab> createState() => _LabourPaymentsTabState();
}

class _LabourPaymentsTabState extends State<LabourPaymentsTab> {
  final CRMService _crmService = CRMService();
  final _currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '\u20B9');

  List<CustomerProject> _projects = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  Future<void> _loadProjects() async {
    try {
      final projects = await _crmService.getAllCustomerProjects();
      setState(() { _projects = projects; _isLoading = false; });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              const Text("Labour Payments", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: _isLoading ? null : () => _showRecordPaymentDialog(),
                icon: const Icon(Icons.add, size: 18),
                label: const Text("Record Payment"),
                style: ElevatedButton.styleFrom(backgroundColor: primaryColor, foregroundColor: Colors.white),
              ),
            ],
          ),
        ),
        Expanded(
          child: Consumer<FinanceProvider>(
            builder: (context, provider, child) {
              if (provider.labourPayments.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.engineering_outlined, size: 48, color: Colors.grey[400]),
                      const SizedBox(height: 8),
                      const Text("No labour payments recorded yet", style: TextStyle(color: textSecondary)),
                      const SizedBox(height: 4),
                      const Text("Use 'Record Payment' to add labour payments", style: TextStyle(fontSize: 12, color: textMuted)),
                    ],
                  ),
                );
              }

              final total = provider.labourPayments.fold<double>(0, (s, p) => s + p.amount);

              return Column(
                children: [
                  // Summary
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: boxInfo,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: boxBorderInfo),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            Text('${provider.labourPayments.length}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: primaryColor)),
                            const Text('Total Payments', style: TextStyle(fontSize: 12, color: textSecondary)),
                          ],
                        ),
                        Column(
                          children: [
                            Text(_currencyFormat.format(total), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: primaryColor)),
                            const Text('Total Amount', style: TextStyle(fontSize: 12, color: textSecondary)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.builder(
                      itemCount: provider.labourPayments.length,
                      itemBuilder: (context, index) {
                        final payment = provider.labourPayments[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: warningColor.withOpacity(0.1),
                              child: const Icon(Icons.engineering, color: warningColor),
                            ),
                            title: Text(payment.labourName ?? 'Labour #${payment.labourId}', style: const TextStyle(fontWeight: FontWeight.w500)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Project: ${payment.projectName ?? '#${payment.projectId}'}', style: const TextStyle(fontSize: 12)),
                                Row(
                                  children: [
                                    Text('Date: ${payment.paymentDate}', style: const TextStyle(fontSize: 12, color: textSecondary)),
                                    if (payment.paymentMethod != null) ...[
                                      const SizedBox(width: 8),
                                      Text('via ${payment.paymentMethod}', style: const TextStyle(fontSize: 12, color: textMuted)),
                                    ],
                                  ],
                                ),
                                if (payment.notes != null && payment.notes!.isNotEmpty)
                                  Text(payment.notes!, style: const TextStyle(fontSize: 11, color: textMuted), maxLines: 1, overflow: TextOverflow.ellipsis),
                              ],
                            ),
                            trailing: Text(_currencyFormat.format(payment.amount),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  void _showRecordPaymentDialog() {
    final labourIdCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    final dateCtrl = TextEditingController(text: DateFormat('yyyy-MM-dd').format(DateTime.now()));
    final notesCtrl = TextEditingController();
    String? paymentMethod;
    CustomerProject? selectedProject;
    final formKey = GlobalKey<FormState>();
    final methods = ['CASH', 'BANK_TRANSFER', 'UPI', 'CHEQUE'];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Record Labour Payment'),
          content: SizedBox(
            width: 450,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<CustomerProject>(
                      value: selectedProject,
                      decoration: const InputDecoration(labelText: 'Project *', border: OutlineInputBorder()),
                      items: _projects.map((p) => DropdownMenuItem(
                        value: p,
                        child: Text(p.projectName.isNotEmpty ? p.projectName : 'Project #${p.id}', overflow: TextOverflow.ellipsis),
                      )).toList(),
                      onChanged: (v) => setDialogState(() => selectedProject = v),
                      validator: (v) => v == null ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: labourIdCtrl,
                      decoration: const InputDecoration(labelText: 'Labour ID *', border: OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: amountCtrl,
                      decoration: const InputDecoration(labelText: 'Amount (\u20B9) *', border: OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                      validator: (v) => v == null || v.isEmpty || double.tryParse(v) == null ? 'Enter valid amount' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: dateCtrl,
                      decoration: const InputDecoration(labelText: 'Payment Date *', border: OutlineInputBorder()),
                      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: paymentMethod,
                      decoration: const InputDecoration(labelText: 'Payment Method', border: OutlineInputBorder()),
                      items: methods.map((m) => DropdownMenuItem(value: m, child: Text(m.replaceAll('_', ' ')))).toList(),
                      onChanged: (v) => setDialogState(() => paymentMethod = v),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: notesCtrl,
                      decoration: const InputDecoration(labelText: 'Notes', border: OutlineInputBorder()),
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                final payment = LabourPayment(
                  labourId: int.parse(labourIdCtrl.text),
                  projectId: selectedProject!.id!,
                  amount: double.parse(amountCtrl.text),
                  paymentDate: dateCtrl.text.trim(),
                  paymentMethod: paymentMethod,
                  notes: notesCtrl.text.trim().isNotEmpty ? notesCtrl.text.trim() : null,
                );
                try {
                  await Provider.of<FinanceProvider>(context, listen: false).recordLabourPayment(payment);
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Labour payment recorded'), backgroundColor: successColor),
                    );
                  }
                } catch (e) {
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(content: Text('Error: $e'), backgroundColor: errorColor),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: primaryColor, foregroundColor: Colors.white),
              child: const Text('Record'),
            ),
          ],
        ),
      ),
    );
  }
}
