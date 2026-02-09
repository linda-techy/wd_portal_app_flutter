import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:admin/models/procurement_models.dart';
import 'package:admin/providers/purchase_order_provider.dart';
import 'package:admin/screens/procurement/add_purchase_order_screen.dart';
import 'package:admin/widgets/common/search_bar_widget.dart';
import 'package:admin/theme/app_theme.dart';
import 'package:admin/providers/permission_provider.dart';

class PurchaseOrdersScreen extends StatelessWidget {
  const PurchaseOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PurchaseOrderProvider()..fetch(),
      child: Consumer<PurchaseOrderProvider>(
        builder: (context, provider, _) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Purchase Orders'),
              actions: [
                Consumer<PermissionProvider>(
                  builder: (context, permissionProvider, _) {
                    if (permissionProvider.hasPermission('procurement:create')) {
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
                Expanded(child: _buildPOList(context, provider)),
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
      BuildContext context, PurchaseOrderProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[100],
      child: Column(
        children: [
          SearchBarWidget(
            onSearch: (query) => provider.search(query),
            hintText: 'Search purchase orders...',
          ),
          const SizedBox(height: 12),
          _buildFilterChips(context, provider),
        ],
      ),
    );
  }

  Widget _buildFilterChips(BuildContext context, PurchaseOrderProvider provider) {
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
          label: 'Pending',
          isSelected: provider.filters['status'] == 'PENDING',
          onTap: () => provider.updateFilter('status', 'PENDING'),
          color: Colors.orange,
        ),
        _buildFilterChip(
          context,
          label: 'Approved',
          isSelected: provider.filters['status'] == 'APPROVED',
          onTap: () => provider.updateFilter('status', 'APPROVED'),
          color: Colors.green,
        ),
        _buildFilterChip(
          context,
          label: 'Completed',
          isSelected: provider.filters['status'] == 'COMPLETED',
          onTap: () => provider.updateFilter('status', 'COMPLETED'),
          color: Colors.blue,
        ),
        _buildFilterChip(
          context,
          label: 'Cancelled',
          isSelected: provider.filters['status'] == 'CANCELLED',
          onTap: () => provider.updateFilter('status', 'CANCELLED'),
          color: Colors.red,
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

  Widget _buildPOList(BuildContext context, PurchaseOrderProvider provider) {
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
            Icon(Icons.shopping_cart, size: 48, color: Colors.grey),
            SizedBox(height: 16),
            Text('No purchase orders found', style: TextStyle(fontSize: 16)),
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
          final po = provider.items[index];
          return _buildPOCard(context, po);
        },
      ),
    );
  }

  Widget _buildPOCard(BuildContext context, PurchaseOrder po) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: () => _navigateToDetail(context, po),
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
                          po.poNumber ?? 'N/A',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (po.vendorName != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            po.vendorName!,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  _buildStatusBadge(po.status),
                ],
              ),
              if (po.notes != null && po.notes!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  po.notes!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  if (po.projectName != null)
                    _buildInfoChip(
                      icon: Icons.business,
                      label: po.projectName!,
                    ),
                  _buildInfoChip(
                    icon: Icons.currency_rupee,
                    label: '₹${po.totalAmount.toStringAsFixed(2)}',
                    color: AppTheme.statusSuccess,
                  ),
                  _buildInfoChip(
                    icon: Icons.calendar_today,
                    label: _formatDate(po.poDate),
                  ),
                  if (po.expectedDeliveryDate != null)
                    _buildInfoChip(
                      icon: Icons.local_shipping,
                      label: 'Exp: ${_formatDate(po.expectedDeliveryDate!)}',
                      color: _getDeliveryDateColor(po.expectedDeliveryDate!),
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
          style: TextStyle(
            fontSize: 12,
            color: color ?? Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildPagination(BuildContext context, PurchaseOrderProvider provider) {
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
      case 'APPROVED':
        return AppTheme.statusSuccess;
      case 'PENDING':
        return AppTheme.statusWarning;
      case 'COMPLETED':
        return Colors.blue;
      case 'CANCELLED':
        return AppTheme.statusError;
      default:
        return Colors.grey;
    }
  }

  Color _getDeliveryDateColor(DateTime date) {
    final now = DateTime.now();
    final diff = date.difference(now).inDays;
    if (diff < 0) return AppTheme.statusError;
    if (diff <= 3) return AppTheme.safetyOrange;
    return Colors.grey;
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _navigateToDetail(BuildContext context, PurchaseOrder po) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('View details for PO ${po.poNumber}')),
    );
  }

  void _navigateToCreate(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddPurchaseOrderScreen()),
    ).then((_) {
      Provider.of<PurchaseOrderProvider>(context, listen: false).fetch();
    });
  }
}
