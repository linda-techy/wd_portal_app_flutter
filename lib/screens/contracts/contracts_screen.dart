import 'package:flutter/material.dart';
import 'package:admin/constants.dart';
import 'package:admin/features/subcontracting/data/models/subcontract_models.dart';
import 'package:admin/features/subcontracting/data/services/subcontract_service.dart';
import 'package:admin/models/customer_project.dart';
import 'package:admin/services/crm_service.dart';
import 'package:intl/intl.dart';

class ContractsScreen extends StatefulWidget {
  const ContractsScreen({super.key});

  @override
  ContractsScreenState createState() => ContractsScreenState();
}

class ContractsScreenState extends State<ContractsScreen> {
  final SubcontractService _subcontractService = SubcontractService();
  final CRMService _crmService = CRMService();
  final _currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '\u20B9');

  List<CustomerProject> _projects = [];
  CustomerProject? _selectedProject;
  List<SubcontractWorkOrder> _workOrders = [];
  bool _isLoadingProjects = true;
  bool _isLoadingWorkOrders = false;
  String? _error;
  String _statusFilter = 'All';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  final List<String> _statuses = ['All', 'DRAFT', 'ACTIVE', 'COMPLETED', 'CANCELLED'];

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
          _loadWorkOrders();
        }
      });
    } catch (e) {
      setState(() { _error = e.toString(); _isLoadingProjects = false; });
    }
  }

  Future<void> _loadWorkOrders() async {
    if (_selectedProject == null) return;
    setState(() { _isLoadingWorkOrders = true; _error = null; });
    try {
      final orders = await _subcontractService.getProjectWorkOrders(_selectedProject!.id!);
      setState(() { _workOrders = orders; _isLoadingWorkOrders = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _isLoadingWorkOrders = false; });
    }
  }

  List<SubcontractWorkOrder> get _filteredOrders {
    return _workOrders.where((wo) {
      final matchesSearch = _searchQuery.isEmpty ||
          wo.workOrderNumber.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (wo.vendorName?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
          wo.scopeDescription.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesStatus = _statusFilter == 'All' || wo.status == _statusFilter;
      return matchesSearch && matchesStatus;
    }).toList();
  }

  double get _totalContractValue => _filteredOrders.fold(0, (sum, wo) => sum + wo.negotiatedAmount);
  double get _totalRetention => _filteredOrders.fold(0, (sum, wo) => sum + wo.totalRetentionAccumulated);

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'ACTIVE': return successColor;
      case 'DRAFT': return Colors.grey;
      case 'COMPLETED': return infoColor;
      case 'CANCELLED': return errorColor;
      default: return warningColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredOrders;

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
                Text("Contracts & Work Orders", style: Theme.of(context).textTheme.headlineMedium),
                IconButton(icon: const Icon(Icons.refresh), onPressed: _loadWorkOrders, tooltip: 'Refresh'),
              ],
            ),
            const SizedBox(height: defaultPadding),

            // Project Selector & Filters
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
                    flex: 2,
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
                              _loadWorkOrders();
                            },
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search contracts...',
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
            if (!_isLoadingWorkOrders && _workOrders.isNotEmpty)
              Row(
                children: [
                  _buildSummaryCard('Total Contracts', '${filtered.length}', Icons.assignment, primaryColor),
                  const SizedBox(width: 12),
                  _buildSummaryCard('Contract Value', _currencyFormat.format(_totalContractValue), Icons.payments, successColor),
                  const SizedBox(width: 12),
                  _buildSummaryCard('Retention Held', _currencyFormat.format(_totalRetention), Icons.lock, warningColor),
                  const SizedBox(width: 12),
                  _buildSummaryCard('Active', '${_workOrders.where((w) => w.status == 'ACTIVE').length}', Icons.play_circle, infoColor),
                ],
              ),
            if (!_isLoadingWorkOrders && _workOrders.isNotEmpty) const SizedBox(height: defaultPadding),

            // Content
            Expanded(
              child: _isLoadingWorkOrders
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.error_outline, size: 48, color: errorColor),
                              const SizedBox(height: 8),
                              const Text('Failed to load contracts', style: TextStyle(color: errorColor)),
                              const SizedBox(height: 16),
                              ElevatedButton(onPressed: _loadWorkOrders, child: const Text('Retry')),
                            ],
                          ),
                        )
                      : _selectedProject == null
                          ? const Center(child: Text('Select a project to view contracts', style: TextStyle(color: textSecondary)))
                          : filtered.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.assignment_outlined, size: 48, color: Colors.grey[400]),
                                      const SizedBox(height: 8),
                                      const Text('No contracts found', style: TextStyle(color: textSecondary)),
                                    ],
                                  ),
                                )
                              : RefreshIndicator(
                                  onRefresh: _loadWorkOrders,
                                  child: ListView.builder(
                                  itemCount: filtered.length,
                                  itemBuilder: (ctx, i) {
                                    final wo = filtered[i];
                                    return Card(
                                      margin: const EdgeInsets.only(bottom: 8),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      child: Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Row(
                                                  children: [
                                                    const Icon(Icons.assignment, size: 20, color: primaryColor),
                                                    const SizedBox(width: 8),
                                                    Text(wo.workOrderNumber, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                                  ],
                                                ),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: _getStatusColor(wo.status).withOpacity(0.1),
                                                    borderRadius: BorderRadius.circular(12),
                                                    border: Border.all(color: _getStatusColor(wo.status).withOpacity(0.3)),
                                                  ),
                                                  child: Text(wo.status, style: TextStyle(fontSize: 12, color: _getStatusColor(wo.status), fontWeight: FontWeight.w500)),
                                                ),
                                              ],
                                            ),
                                            const Divider(height: 20),
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: _buildDetailItem('Vendor', wo.vendorName ?? 'Unknown', Icons.store),
                                                ),
                                                Expanded(
                                                  child: _buildDetailItem('Contract Value', _currencyFormat.format(wo.negotiatedAmount), Icons.payments),
                                                ),
                                                Expanded(
                                                  child: _buildDetailItem('Measurement', wo.measurementBasis.replaceAll('_', ' '), Icons.straighten),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: _buildDetailItem('Retention %', '${wo.retentionPercentage}%', Icons.lock),
                                                ),
                                                Expanded(
                                                  child: _buildDetailItem('Retention Held', _currencyFormat.format(wo.totalRetentionAccumulated), Icons.account_balance),
                                                ),
                                                Expanded(
                                                  child: _buildDetailItem('Payment Terms', wo.paymentTerms ?? 'Not specified', Icons.schedule),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                            const Text('Scope:', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                                            const SizedBox(height: 4),
                                            Text(wo.scopeDescription, style: const TextStyle(fontSize: 13, color: textSecondary), maxLines: 3, overflow: TextOverflow.ellipsis),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 14, color: textMuted),
        const SizedBox(width: 4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 10, color: textMuted)),
              Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ],
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
