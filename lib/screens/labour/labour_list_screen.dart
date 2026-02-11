import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:admin/models/labour_models.dart';
import 'package:admin/providers/labour_provider.dart';
import 'package:admin/widgets/common/search_bar_widget.dart';
import 'package:admin/theme/app_theme.dart';
import 'package:admin/providers/permission_provider.dart';
import 'add_labour_screen.dart';

class LabourListScreen extends StatelessWidget {
  const LabourListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => LabourProvider()..fetch(),
      child: Consumer<LabourProvider>(
        builder: (context, provider, _) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Labour Management'),
              actions: [
                Consumer<PermissionProvider>(
                  builder: (context, permissionProvider, _) {
                    if (permissionProvider.hasPermission('labour:create')) {
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
                Expanded(child: _buildLabourList(context, provider)),
                if (provider.totalPages > 1)
                  _buildPagination(context, provider),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSearchAndFilters(BuildContext context, LabourProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[100],
      child: Column(
        children: [
          SearchBarWidget(
            onSearch: (query) => provider.search(query),
            hintText: 'Search labour...',
          ),
          const SizedBox(height: 12),
          _buildFilterChips(context, provider),
        ],
      ),
    );
  }

  Widget _buildFilterChips(BuildContext context, LabourProvider provider) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildFilterChip(
          context,
          label: 'All',
          isSelected: provider.filters['employmentType'] == null,
          onTap: () => provider.clearFilters(),
        ),
        _buildFilterChip(
          context,
          label: 'Daily Wage',
          isSelected: provider.filters['employmentType'] == 'DAILY_WAGE',
          onTap: () => provider.updateFilter('employmentType', 'DAILY_WAGE'),
        ),
        _buildFilterChip(
          context,
          label: 'Contract',
          isSelected: provider.filters['employmentType'] == 'CONTRACT',
          onTap: () => provider.updateFilter('employmentType', 'CONTRACT'),
        ),
        _buildFilterChip(
          context,
          label: 'Permanent',
          isSelected: provider.filters['employmentType'] == 'PERMANENT',
          onTap: () => provider.updateFilter('employmentType', 'PERMANENT'),
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

  Widget _buildLabourList(BuildContext context, LabourProvider provider) {
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
            Icon(Icons.people, size: 48, color: Colors.grey),
            SizedBox(height: 16),
            Text('No labour records found', style: TextStyle(fontSize: 16)),
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
          final labour = provider.items[index];
          return _buildLabourCard(context, labour);
        },
      ),
    );
  }

  Widget _buildLabourCard(BuildContext context, Labour labour) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: () => _navigateToDetail(context, labour),
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
                          labour.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          labour.tradeType,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusBadge(labour.active),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  _buildInfoChip(
                    icon: Icons.phone,
                    label: labour.phone,
                  ),
                  _buildInfoChip(
                    icon: Icons.work,
                    label: labour.tradeType,
                  ),
                  _buildInfoChip(
                    icon: Icons.currency_rupee,
                    label: '₹${labour.dailyWage.toStringAsFixed(2)}/day',
                    color: Colors.green,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(bool active) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: active ? AppTheme.statusSuccess : Colors.grey,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        active ? 'Active' : 'Inactive',
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

  Widget _buildPagination(BuildContext context, LabourProvider provider) {
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

  // Commented out unused method to avoid linter warning
  // Color _getTypeColor(String type) {
  //   switch (type.toUpperCase()) {
  //     case 'PERMANENT':
  //       return AppTheme.statusSuccess;
  //     case 'CONTRACT':
  //       return Colors.blue;
  //     case 'DAILY_WAGE':
  //       return AppTheme.statusWarning;
  //     default:
  //       return Colors.grey;
  //   }
  // }

  void _navigateToDetail(BuildContext context, Labour labour) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('View labour details: ${labour.name}')),
    );
  }

  void _navigateToCreate(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddLabourScreen(),
      ),
    );
  }
}
