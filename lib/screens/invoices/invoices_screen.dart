import 'package:flutter/material.dart';
import 'package:admin/constants.dart';
import 'package:admin/models/finance_models.dart';
import 'package:admin/models/customer_project.dart';
import 'package:admin/services/finance_service.dart';
import 'package:admin/services/crm_service.dart';
import 'package:admin/screens/finance/add_project_invoice_screen.dart';
import 'package:intl/intl.dart';

class InvoicesScreen extends StatefulWidget {
  const InvoicesScreen({super.key});

  @override
  State<InvoicesScreen> createState() => InvoicesScreenState();
}

class InvoicesScreenState extends State<InvoicesScreen> {
  final FinanceService _financeService = FinanceService();
  final CRMService _crmService = CRMService();
  final _currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '\u20B9');

  List<CustomerProject> _projects = [];
  CustomerProject? _selectedProject;
  List<ProjectInvoice> _invoices = [];
  bool _isLoadingProjects = true;
  bool _isLoadingInvoices = false;
  String? _error;
  String _statusFilter = 'All';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  final List<String> _statuses = ['All', 'DRAFT', 'SENT', 'PAID', 'OVERDUE', 'CANCELLED'];

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProjects() async {
    setState(() => _isLoadingProjects = true);
    try {
      final projects = await _crmService.getAllCustomerProjects();
      setState(() {
        _projects = projects;
        _isLoadingProjects = false;
        if (_projects.isNotEmpty) {
          _selectedProject = _projects.first;
          _loadInvoices();
        }
      });
    } catch (e) {
      setState(() { _error = e.toString(); _isLoadingProjects = false; });
    }
  }

  Future<void> _loadInvoices() async {
    if (_selectedProject == null) return;
    setState(() { _isLoadingInvoices = true; _error = null; });
    try {
      final invoices = await _financeService.getProjectInvoices(_selectedProject!.id!);
      setState(() { _invoices = invoices; _isLoadingInvoices = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _isLoadingInvoices = false; });
    }
  }

  List<ProjectInvoice> get _filteredInvoices {
    return _invoices.where((inv) {
      final matchesSearch = _searchQuery.isEmpty ||
          (inv.invoiceNumber?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
          (inv.projectName?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
      final matchesStatus = _statusFilter == 'All' || inv.status == _statusFilter;
      return matchesSearch && matchesStatus;
    }).toList();
  }

  double get _totalAmount => _filteredInvoices.fold(0, (sum, inv) => sum + inv.totalAmount);
  double get _paidAmount => _filteredInvoices.where((i) => i.status == 'PAID').fold(0, (sum, inv) => sum + inv.totalAmount);
  double get _pendingAmount => _totalAmount - _paidAmount;

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PAID': return successColor;
      case 'SENT': return infoColor;
      case 'DRAFT': return Colors.grey;
      case 'OVERDUE': return errorColor;
      case 'CANCELLED': return Colors.brown;
      default: return warningColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredInvoices;

    return Scaffold(
      body: Container(
        padding: const EdgeInsets.all(defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Invoices Management", style: Theme.of(context).textTheme.headlineMedium),
                Row(
                  children: [
                    IconButton(icon: const Icon(Icons.refresh), onPressed: _loadInvoices, tooltip: 'Refresh'),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () async {
                        await Navigator.push(context, MaterialPageRoute(builder: (_) => const AddProjectInvoiceScreen()));
                        _loadInvoices();
                      },
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text("New Invoice"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: defaultPadding),

            // Project Selector
            Container(
              padding: const EdgeInsets.all(defaultPadding),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: containerBorder),
              ),
              child: Row(
                children: [
                  const Icon(Icons.business, size: 20, color: textSecondary),
                  const SizedBox(width: 8),
                  const Text('Project:', style: TextStyle(fontWeight: FontWeight.w500)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _isLoadingProjects
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : DropdownButtonFormField<CustomerProject>(
                            value: _selectedProject,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              isDense: true,
                            ),
                            items: _projects.map((p) => DropdownMenuItem(
                              value: p,
                              child: Text(p.projectName.isNotEmpty ? p.projectName : 'Project #${p.id}', overflow: TextOverflow.ellipsis),
                            )).toList(),
                            onChanged: (v) {
                              setState(() => _selectedProject = v);
                              _loadInvoices();
                            },
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search invoices...',
                        prefixIcon: const Icon(Icons.search, size: 20),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        isDense: true,
                      ),
                      onChanged: (v) => setState(() => _searchQuery = v),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 140,
                    child: DropdownButtonFormField<String>(
                      value: _statusFilter,
                      decoration: InputDecoration(
                        labelText: 'Status',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        isDense: true,
                      ),
                      items: _statuses.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                      onChanged: (v) => setState(() => _statusFilter = v ?? 'All'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: defaultPadding),

            // Summary Cards
            if (!_isLoadingInvoices && _invoices.isNotEmpty)
              Row(
                children: [
                  _buildSummaryCard('Total Invoiced', _currencyFormat.format(_totalAmount), Icons.receipt_long, primaryColor),
                  const SizedBox(width: 12),
                  _buildSummaryCard('Paid', _currencyFormat.format(_paidAmount), Icons.check_circle, successColor),
                  const SizedBox(width: 12),
                  _buildSummaryCard('Pending', _currencyFormat.format(_pendingAmount), Icons.pending, warningColor),
                  const SizedBox(width: 12),
                  _buildSummaryCard('Count', '${filtered.length}', Icons.format_list_numbered, infoColor),
                ],
              ),
            if (!_isLoadingInvoices && _invoices.isNotEmpty) const SizedBox(height: defaultPadding),

            // Content
            Expanded(
              child: _isLoadingInvoices
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.error_outline, size: 48, color: errorColor),
                              const SizedBox(height: 8),
                              const Text('Failed to load invoices', style: TextStyle(color: errorColor)),
                              const SizedBox(height: 16),
                              ElevatedButton(onPressed: _loadInvoices, child: const Text('Retry')),
                            ],
                          ),
                        )
                      : _selectedProject == null
                          ? const Center(child: Text('Select a project to view invoices', style: TextStyle(color: textSecondary)))
                          : filtered.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.receipt_long_outlined, size: 48, color: Colors.grey[400]),
                                      const SizedBox(height: 8),
                                      const Text('No invoices found', style: TextStyle(color: textSecondary)),
                                    ],
                                  ),
                                )
                              : Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: containerBorder),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: SingleChildScrollView(
                                      child: SizedBox(
                                        width: double.infinity,
                                        child: DataTable(
                                          headingRowColor: WidgetStateProperty.all(boxSecondary),
                                          columnSpacing: 16,
                                          horizontalMargin: 16,
                                          columns: const [
                                            DataColumn(label: Text('Invoice #', style: TextStyle(fontWeight: FontWeight.bold))),
                                            DataColumn(label: Text('Project', style: TextStyle(fontWeight: FontWeight.bold))),
                                            DataColumn(label: Text('Date', style: TextStyle(fontWeight: FontWeight.bold))),
                                            DataColumn(label: Text('Due Date', style: TextStyle(fontWeight: FontWeight.bold))),
                                            DataColumn(label: Text('Sub Total', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
                                            DataColumn(label: Text('GST', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
                                            DataColumn(label: Text('Total', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
                                            DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                                          ],
                                          rows: filtered.map((inv) => DataRow(
                                            cells: [
                                              DataCell(Text(inv.invoiceNumber ?? 'Draft', style: const TextStyle(fontWeight: FontWeight.w500))),
                                              DataCell(Text(inv.projectName ?? '-', overflow: TextOverflow.ellipsis)),
                                              DataCell(Text(inv.invoiceDate)),
                                              DataCell(Text(inv.dueDate ?? '-')),
                                              DataCell(Text(_currencyFormat.format(inv.subTotal))),
                                              DataCell(Text('${inv.gstPercentage}%')),
                                              DataCell(Text(_currencyFormat.format(inv.totalAmount), style: const TextStyle(fontWeight: FontWeight.bold))),
                                              DataCell(
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                  decoration: BoxDecoration(
                                                    color: _getStatusColor(inv.status).withOpacity(0.1),
                                                    borderRadius: BorderRadius.circular(12),
                                                    border: Border.all(color: _getStatusColor(inv.status).withOpacity(0.3)),
                                                  ),
                                                  child: Text(inv.status, style: TextStyle(fontSize: 12, color: _getStatusColor(inv.status))),
                                                ),
                                              ),
                                            ],
                                          )).toList(),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(fontSize: 12, color: color.withOpacity(0.8))),
                  const SizedBox(height: 2),
                  Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color), overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
