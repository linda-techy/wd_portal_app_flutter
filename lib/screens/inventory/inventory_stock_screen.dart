import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:admin/models/inventory_models.dart';
import 'package:admin/utils/error_handler.dart';
import 'package:admin/providers/inventory_stock_provider.dart';
import 'package:admin/services/inventory_service.dart';
import 'package:admin/widgets/common/search_bar_widget.dart';
import 'package:admin/theme/app_theme.dart';
import 'package:admin/providers/permission_provider.dart';

class InventoryStockScreen extends StatelessWidget {
  const InventoryStockScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => InventoryStockProvider()..fetch(),
      child: Consumer<InventoryStockProvider>(
        builder: (context, provider, _) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Inventory Stock'),
              actions: [
                Consumer<PermissionProvider>(
                  builder: (context, permissionProvider, _) {
                    if (permissionProvider.hasPermission('inventory:create')) {
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
                Expanded(child: _buildStockList(context, provider)),
                if (provider.totalPages > 1)
                  _buildPagination(context, provider),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSearchAndFilters(
      BuildContext context, InventoryStockProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[100],
      child: Column(
        children: [
          SearchBarWidget(
            onSearch: (query) => provider.search(query),
            hintText: 'Search inventory stock...',
          ),
          const SizedBox(height: 12),
          _buildFilterChips(context, provider),
        ],
      ),
    );
  }

  Widget _buildFilterChips(
      BuildContext context, InventoryStockProvider provider) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildFilterChip(
          context,
          label: 'All',
          isSelected: provider.filters['lowStock'] == null,
          onTap: () => provider.clearFilters(),
        ),
        _buildFilterChip(
          context,
          label: 'Low Stock',
          isSelected: provider.filters['lowStock'] == true,
          onTap: () => provider.updateFilter('lowStock', true),
          color: AppTheme.statusError,
        ),
        _buildFilterChip(
          context,
          label: 'In Stock',
          isSelected: provider.filters['inStock'] == true,
          onTap: () => provider.updateFilter('inStock', true),
          color: AppTheme.statusSuccess,
        ),
      ],
    );
  }

  Widget _buildFilterChip(
    BuildContext context, {
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    Color? color,
  }) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
      backgroundColor: color?.withOpacity(0.1),
      selectedColor: color ?? Theme.of(context).primaryColor,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : (color ?? Colors.black87),
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildStockList(
      BuildContext context, InventoryStockProvider provider) {
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
            Icon(Icons.inventory, size: 48, color: Colors.grey),
            SizedBox(height: 16),
            Text('No inventory stock found', style: TextStyle(fontSize: 16)),
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
          final stock = provider.items[index];
          return _buildStockCard(context, stock);
        },
      ),
    );
  }

  Widget _buildStockCard(BuildContext context, InventoryStock stock) {
    final minLevel = stock.minStockLevel ?? 0.0;
    final isLowStock = minLevel > 0 && stock.currentStock <= minLevel;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: () => _navigateToDetail(context, stock),
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
                          stock.materialName ?? 'Material',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (stock.warehouseName != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            stock.warehouseName!,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (isLowStock)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.statusError,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'LOW STOCK',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  _buildInfoChip(
                    icon: Icons.inventory_2,
                    label: '${stock.currentStock} ${stock.unit ?? ''}',
                    color: isLowStock
                        ? AppTheme.statusError
                        : AppTheme.statusSuccess,
                  ),
                  if (stock.minStockLevel != null)
                    _buildInfoChip(
                      icon: Icons.warning,
                      label: 'Min: ${stock.minStockLevel} ${stock.unit ?? ''}',
                    ),
                  if (stock.projectName != null)
                    _buildInfoChip(
                      icon: Icons.business,
                      label: stock.projectName!,
                    ),
                  if (stock.lastUpdatedDate != null)
                    _buildInfoChip(
                      icon: Icons.update,
                      label: _formatDate(stock.lastUpdatedDate!),
                    ),
                ],
              ),
            ],
          ),
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
          style: TextStyle(
            fontSize: 12,
            color: color ?? Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildPagination(
      BuildContext context, InventoryStockProvider provider) {
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _navigateToDetail(BuildContext context, InventoryStock stock) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            Text(stock.materialName ?? 'Stock Item', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _detailRow('Project', stock.projectName ?? 'N/A'),
            _detailRow('Current Qty', '${stock.currentQuantity} ${stock.unit ?? ''}'),
            _detailRow('Last Updated', stock.lastUpdated),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(width: 120, child: Text(label, style: TextStyle(color: Colors.grey[600]))),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  void _navigateToCreate(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => _CreateStockAdjustmentDialog(
        onCreated: () {
          Provider.of<InventoryStockProvider>(context, listen: false).fetch();
        },
      ),
    );
  }
}

class _CreateStockAdjustmentDialog extends StatefulWidget {
  final VoidCallback onCreated;
  const _CreateStockAdjustmentDialog({required this.onCreated});

  @override
  State<_CreateStockAdjustmentDialog> createState() => _CreateStockAdjustmentDialogState();
}

class _CreateStockAdjustmentDialogState extends State<_CreateStockAdjustmentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _projectIdCtrl = TextEditingController();
  final _materialIdCtrl = TextEditingController();
  final _quantityCtrl = TextEditingController();
  final _reasonCtrl = TextEditingController();
  String _adjustmentType = 'CORRECTION';
  bool _isSaving = false;

  final List<String> _types = [
    'WASTAGE', 'THEFT', 'DAMAGE', 'CORRECTION', 'TRANSFER_OUT',
  ];

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      final service = InventoryService();
      final adj = StockAdjustment(
        projectId: int.parse(_projectIdCtrl.text),
        materialId: int.parse(_materialIdCtrl.text),
        adjustmentType: _adjustmentType,
        quantity: double.parse(_quantityCtrl.text),
        reason: _reasonCtrl.text.isNotEmpty ? _reasonCtrl.text : null,
      );
      await service.createStockAdjustment(adj);
      widget.onCreated();
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Adjustment recorded'), backgroundColor: AppTheme.successGreen),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ErrorHandler.showErrorSnackBar(context, e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Stock Adjustment'),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _projectIdCtrl,
                  decoration: const InputDecoration(labelText: 'Project ID *'),
                  keyboardType: TextInputType.number,
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _materialIdCtrl,
                  decoration: const InputDecoration(labelText: 'Material ID *'),
                  keyboardType: TextInputType.number,
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _adjustmentType,
                  decoration: const InputDecoration(labelText: 'Adjustment Type'),
                  items: _types.map((t) => DropdownMenuItem(value: t, child: Text(t.replaceAll('_', ' ')))).toList(),
                  onChanged: (v) => setState(() => _adjustmentType = v!),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _quantityCtrl,
                  decoration: const InputDecoration(labelText: 'Quantity *'),
                  keyboardType: TextInputType.number,
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _reasonCtrl,
                  decoration: const InputDecoration(labelText: 'Reason'),
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: _isSaving ? null : _submit,
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.deepSlate),
          child: _isSaving
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Record', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}

