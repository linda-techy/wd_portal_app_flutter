import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:admin/features/customers/data/models/customer.dart';
import 'package:admin/features/customers/data/providers/customer_provider.dart';
import 'package:admin/features/customers/data/services/customer_service.dart';
import 'package:admin/widgets/common/search_bar_widget.dart';
import 'package:admin/theme/app_theme.dart';
import 'package:admin/providers/permission_provider.dart';
import 'package:admin/utils/error_handler.dart';
import 'customer_detail_screen.dart';
import 'add_customer_screen.dart';
import 'edit_customer_screen.dart';

class CustomersScreen extends StatelessWidget {
  const CustomersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CustomerProvider()..fetch(),
      child: Consumer<CustomerProvider>(
        builder: (context, provider, _) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Customers'),
              actions: [
                Consumer<PermissionProvider>(
                  builder: (context, permissionProvider, _) {
                    if (permissionProvider.hasPermission('customer:create')) {
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
            body: (provider.isLoading && provider.items.isEmpty)
                ? const Center(child: CircularProgressIndicator())
                : Column(
                    children: [
                      _buildSearchAndFilters(context, provider),
                      Expanded(child: _buildCustomerList(context, provider)),
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
      BuildContext context, CustomerProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[100],
      child: Column(
        children: [
          SearchBarWidget(
            onSearch: (query) => provider.search(query),
            hintText: 'Search customers...',
          ),
          const SizedBox(height: 12),
          _buildFilterChips(context, provider),
        ],
      ),
    );
  }

  Widget _buildFilterChips(BuildContext context, CustomerProvider provider) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildFilterChip(
          context,
          label: 'All',
          isSelected: provider.filters['customerType'] == null,
          onTap: () => provider.clearFilters(),
        ),
        _buildFilterChip(
          context,
          label: 'Individual',
          isSelected: provider.filters['customerType'] == 'INDIVIDUAL',
          onTap: () => provider.updateFilter('customerType', 'INDIVIDUAL'),
        ),
        _buildFilterChip(
          context,
          label: 'Corporate',
          isSelected: provider.filters['customerType'] == 'CORPORATE',
          onTap: () => provider.updateFilter('customerType', 'CORPORATE'),
        ),
        const SizedBox(width: 16),
        _buildFilterChip(
          context,
          label: 'Active',
          isSelected: provider.filters['active'] == 'true',
          onTap: () => provider.updateFilter('active', 'true'),
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

  Widget _buildCustomerList(BuildContext context, CustomerProvider provider) {
    if (provider.isLoading && provider.items.isEmpty) {
      return const SizedBox(); // Loader is handled at body level
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
            Icon(Icons.people, size: 48, color: Colors.grey),
            SizedBox(height: 16),
            Text('No customers found', style: TextStyle(fontSize: 16)),
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
          final customer = provider.items[index];
          return _buildCustomerCard(context, customer);
        },
      ),
    );
  }

  Widget _buildCustomerCard(BuildContext context, Customer customer) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: () => _navigateToDetail(context, customer),
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
                          customer.fullName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (customer.companyName != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            customer.companyName!,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  _buildStatusBadge(customer.enabled),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'delete') {
                        _deleteCustomer(context, customer);
                      } else if (value == 'edit') {
                        _navigateToEdit(context, customer);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 20),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 20, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  _buildInfoChip(
                    icon: Icons.email,
                    label: customer.email,
                  ),
                  if (customer.phone != null)
                    _buildInfoChip(
                      icon: Icons.phone,
                      label: customer.phone!,
                    ),
                  if (customer.address != null)
                    _buildInfoChip(
                      icon: Icons.location_on,
                      label: customer.address!,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(bool enabled) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: enabled ? AppTheme.statusSuccess : Colors.grey,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        enabled ? 'Active' : 'Inactive',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildInfoChip({required IconData icon, required String label}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildPagination(BuildContext context, CustomerProvider provider) {
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

  void _navigateToDetail(BuildContext context, Customer customer) {
    if (customer.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Customer ID is missing'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CustomerDetailScreen(
          customerId: customer.id!,
          initialCustomer: customer,
        ),
      ),
    );
  }

  void _navigateToCreate(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddCustomerScreen(),
      ),
    );

    // Refresh the customer list if a customer was created
    if (result == true && context.mounted) {
      final provider = Provider.of<CustomerProvider>(context, listen: false);
      provider.fetch();
    }
  }

  void _navigateToEdit(BuildContext context, Customer customer) async {
    if (customer.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Customer ID is missing'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditCustomerScreen(customer: customer),
      ),
    );

    // Refresh the customer list if a customer was updated
    if (result == true && context.mounted) {
      final provider = Provider.of<CustomerProvider>(context, listen: false);
      provider.fetch();
    }
  }

  void _deleteCustomer(BuildContext context, Customer customer) async {
    if (customer.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Customer ID is missing'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Customer'),
        content: Text(
          'Are you sure you want to delete "${customer.fullName}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        final customerService = CustomerService();
        await customerService.deleteCustomer(customer.id!);
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Customer deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
          
          // Refresh the customer list
          final provider = Provider.of<CustomerProvider>(context, listen: false);
          provider.fetch();
        }
      } catch (e) {
        if (context.mounted) {
          await ErrorHandler.handleApiError(
            context,
            e,
            defaultMessage: 'Failed to delete customer',
          );
        }
      }
    }
  }
}
