import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:admin/models/subcontract_models.dart';
import 'package:admin/providers/subcontract_provider.dart';
import 'package:admin/services/subcontract_service.dart';
import 'package:admin/services/api_service.dart';
import 'package:admin/widgets/common/search_bar_widget.dart';
import 'package:admin/theme/app_theme.dart';
import 'package:admin/providers/permission_provider.dart';
import 'subcontract_work_order_detail_screen.dart';

class SubcontractWorkOrdersScreen extends StatelessWidget {
  final int? projectId;
  final String? projectName;

  const SubcontractWorkOrdersScreen({
    super.key,
    this.projectId,
    this.projectName,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SubcontractProvider()..fetch(),
      child: Consumer<SubcontractProvider>(
        builder: (context, provider, _) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Subcontract Work Orders'),
              actions: [
                Consumer<PermissionProvider>(
                  builder: (context, permissionProvider, _) {
                    if (permissionProvider.hasPermission('subcontract:create')) {
                      return IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () => _navigateToCreate(context),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ],
            ),
            body: Column(
              children: [
                _buildSearchAndFilters(context, provider),
                Expanded(child: _buildSubcontractList(context, provider)),
                if (provider.totalPages > 1) _buildPagination(context, provider),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSearchAndFilters(BuildContext context, SubcontractProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[100],
      child: Column(
        children: [
          SearchBarWidget(
            onSearch: (query) => provider.search(query),
            hintText: 'Search subcontracts...',
          ),
          const SizedBox(height: 12),
          _buildFilterChips(context, provider),
        ],
      ),
    );
  }

  Widget _buildFilterChips(BuildContext context, SubcontractProvider provider) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildFilterChip(
          context,
          label: 'All',
          isSelected: provider.filters['status'] == null,
          onTap: () => provider.clearFilters(),
        ),
        _buildFilterChip(
          context,
          label: 'Draft',
          isSelected: provider.filters['status'] == 'DRAFT',
          onTap: () => provider.updateFilter('status', 'DRAFT'),
        ),
        _buildFilterChip(
          context,
          label: 'Active',
          isSelected: provider.filters['status'] == 'ACTIVE',
          onTap: () => provider.updateFilter('status', 'ACTIVE'),
        ),
        _buildFilterChip(
          context,
          label: 'Completed',
          isSelected: provider.filters['status'] == 'COMPLETED',
          onTap: () => provider.updateFilter('status', 'COMPLETED'),
        ),
      ],
    );
  }

  Widget _buildFilterChip(
    BuildContext context, {
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
      selectedColor: Theme.of(context).primaryColor,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildSubcontractList(BuildContext context, SubcontractProvider provider) {
    if (provider.isLoading && provider.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: ${provider.error}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => provider.fetch(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (provider.items.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.construction, size: 48, color: Colors.grey),
            SizedBox(height: 16),
            Text('No subcontracts found', style: TextStyle(fontSize: 16)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => provider.fetch(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: provider.items.length,
        itemBuilder: (context, index) {
          final subcontract = provider.items[index];
          return _buildSubcontractCard(context, subcontract);
        },
      ),
    );
  }

  Widget _buildSubcontractCard(BuildContext context, SubcontractWorkOrder subcontract) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: () => _navigateToDetail(context, subcontract),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          subcontract.workOrderNumber,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (subcontract.vendorName != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            subcontract.vendorName!,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  _buildStatusBadge(subcontract.status),
                ],
              ),
              if (subcontract.scopeDescription.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  subcontract.scopeDescription,
                  style: TextStyle(color: Colors.grey[600]),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  if (subcontract.projectName != null)
                    _buildInfoChip(
                      icon: Icons.business,
                      label: subcontract.projectName!,
                    ),
                  _buildInfoChip(
                    icon: Icons.currency_rupee,
                    label: '₹${subcontract.negotiatedAmount.toStringAsFixed(2)}',
                    color: Colors.green,
                  ),
                  if (subcontract.startDate != null)
                    _buildInfoChip(
                      icon: Icons.calendar_today,
                      label: _formatDate(subcontract.startDate!),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getStatusColor(status),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    Color? color,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color ?? Colors.grey[600]),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: color ?? Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildPagination(BuildContext context, SubcontractProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Page ${provider.currentPage + 1} of ${provider.totalPages}',
            style: const TextStyle(fontSize: 14),
          ),
          Row(
            children: [
              IconButton(
                onPressed: provider.currentPage > 0
                    ? () => provider.goToPage(provider.currentPage - 1)
                    : null,
                icon: const Icon(Icons.chevron_left),
              ),
              IconButton(
                onPressed: provider.currentPage < provider.totalPages - 1
                    ? () => provider.goToPage(provider.currentPage + 1)
                    : null,
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'COMPLETED':
        return AppTheme.statusSuccess;
      case 'ACTIVE':
        return Colors.blue;
      case 'DRAFT':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _navigateToDetail(BuildContext context, SubcontractWorkOrder subcontract) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SubcontractWorkOrderDetailScreen(
          workOrderId: subcontract.id!,
        ),
      ),
    );
  }

  void _navigateToCreate(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => _CreateSubcontractDialog(
        projectId: projectId,
        onCreated: () {
          Provider.of<SubcontractProvider>(context, listen: false).fetch();
        },
      ),
    );
  }
}

class _CreateSubcontractDialog extends StatefulWidget {
  final int? projectId;
  final VoidCallback onCreated;

  const _CreateSubcontractDialog({this.projectId, required this.onCreated});

  @override
  State<_CreateSubcontractDialog> createState() =>
      _CreateSubcontractDialogState();
}

class _CreateSubcontractDialogState extends State<_CreateSubcontractDialog> {
  final _formKey = GlobalKey<FormState>();
  final _woNumberController = TextEditingController();
  final _scopeController = TextEditingController();
  final _amountController = TextEditingController();
  final _unitController = TextEditingController();
  final _rateController = TextEditingController();
  final _notesController = TextEditingController();
  final _vendorIdController = TextEditingController();
  final _projectIdController = TextEditingController();

  String _measurementBasis = 'LUMPSUM';
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.projectId != null) {
      _projectIdController.text = widget.projectId.toString();
    }
    _woNumberController.text =
        'WO-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final service = SubcontractService(ApiService());
      final workOrder = SubcontractWorkOrder(
        workOrderNumber: _woNumberController.text,
        projectId: int.parse(_projectIdController.text),
        vendorId: int.parse(_vendorIdController.text),
        scopeDescription: _scopeController.text,
        measurementBasis: _measurementBasis,
        negotiatedAmount: double.parse(_amountController.text),
        unit: _measurementBasis == 'UNIT_RATE' && _unitController.text.isNotEmpty
            ? _unitController.text
            : null,
        rate: _measurementBasis == 'UNIT_RATE' && _rateController.text.isNotEmpty
            ? double.tryParse(_rateController.text)
            : null,
        status: 'DRAFT',
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      );

      await service.createWorkOrder(workOrder);
      widget.onCreated();
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Work order created'),
            backgroundColor: AppTheme.successGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create Work Order'),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _woNumberController,
                  decoration:
                      const InputDecoration(labelText: 'Work Order Number *'),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                if (widget.projectId == null)
                  TextFormField(
                    controller: _projectIdController,
                    decoration:
                        const InputDecoration(labelText: 'Project ID *'),
                    keyboardType: TextInputType.number,
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Required' : null,
                  ),
                if (widget.projectId == null) const SizedBox(height: 12),
                TextFormField(
                  controller: _vendorIdController,
                  decoration: const InputDecoration(
                      labelText: 'Vendor / Contractor ID *'),
                  keyboardType: TextInputType.number,
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _scopeController,
                  decoration: const InputDecoration(
                      labelText: 'Scope of Work *'),
                  maxLines: 3,
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _measurementBasis,
                  decoration:
                      const InputDecoration(labelText: 'Measurement Basis'),
                  items: const [
                    DropdownMenuItem(
                        value: 'LUMPSUM', child: Text('Lump Sum')),
                    DropdownMenuItem(
                        value: 'UNIT_RATE', child: Text('Unit Rate')),
                  ],
                  onChanged: (v) =>
                      setState(() => _measurementBasis = v!),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _amountController,
                  decoration: const InputDecoration(
                      labelText: 'Negotiated Amount *', prefixText: '₹ '),
                  keyboardType: TextInputType.number,
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Required' : null,
                ),
                if (_measurementBasis == 'UNIT_RATE') ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _unitController,
                          decoration:
                              const InputDecoration(labelText: 'Unit'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _rateController,
                          decoration:
                              const InputDecoration(labelText: 'Rate'),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                TextFormField(
                  controller: _notesController,
                  decoration: const InputDecoration(labelText: 'Notes'),
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _submit,
          style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.deepSlate),
          child: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : const Text('Create',
                  style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}

