import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:admin/features/warranties/data/models/project_warranty.dart';
import 'package:admin/providers/project_warranty_provider.dart';
import 'package:admin/widgets/common/search_bar_widget.dart';
import 'package:admin/theme/app_theme.dart';
import 'package:admin/providers/permission_provider.dart';

class ProjectWarrantiesScreen extends StatelessWidget {
  const ProjectWarrantiesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ProjectWarrantyProvider()..fetch(),
      child: Consumer<ProjectWarrantyProvider>(
        builder: (context, provider, _) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Project Warranties'),
              actions: [
                Consumer<PermissionProvider>(
                  builder: (context, permissionProvider, _) {
                    if (permissionProvider.hasPermission('project:edit')) {
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
                      Expanded(child: _buildWarrantyList(context, provider)),
                      if (provider.totalPages > 1)
                        _buildPagination(context, provider),
                    ],
                  ),
          );
        },
      ),
    );
  }

  Widget _buildSearchAndFilters(BuildContext context, ProjectWarrantyProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[100],
      child: Column(
        children: [
          SearchBarWidget(
            onSearch: (query) => provider.search(query),
            hintText: 'Search warranties...',
          ),
          const SizedBox(height: 12),
          _buildFilterChips(context, provider),
        ],
      ),
    );
  }

  Widget _buildFilterChips(BuildContext context, ProjectWarrantyProvider provider) {
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
          label: 'Active',
          isSelected: provider.filters['status'] == 'ACTIVE',
          onTap: () => provider.updateFilter('status', 'ACTIVE'),
          color: AppTheme.statusSuccess,
        ),
        _buildFilterChip(
          context,
          label: 'Expired',
          isSelected: provider.filters['status'] == 'EXPIRED',
          onTap: () => provider.updateFilter('status', 'EXPIRED'),
          color: Colors.grey,
        ),
        _buildFilterChip(
          context,
          label: 'Claimed',
          isSelected: provider.filters['status'] == 'CLAIMED',
          onTap: () => provider.updateFilter('status', 'CLAIMED'),
          color: AppTheme.statusWarning,
        ),
        _buildFilterChip(
          context,
          label: 'Void',
          isSelected: provider.filters['status'] == 'VOID',
          onTap: () => provider.updateFilter('status', 'VOID'),
          color: AppTheme.statusError,
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

  Widget _buildWarrantyList(BuildContext context, ProjectWarrantyProvider provider) {
    if (provider.isLoading && provider.items.isEmpty) {
      return const SizedBox(); // Loader is handled at body level now
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
            Icon(Icons.shield, size: 48, color: Colors.grey),
            SizedBox(height: 16),
            Text('No project warranties found', style: TextStyle(fontSize: 16)),
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
          final warranty = provider.items[index];
          return _buildWarrantyCard(context, warranty);
        },
      ),
    );
  }

  Widget _buildWarrantyCard(BuildContext context, ProjectWarranty warranty) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: () => _navigateToDetail(context, warranty),
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
                          warranty.warrantyType ?? 'Warranty',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (warranty.projectName != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            warranty.projectName!,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  _buildStatusBadge(warranty.status),
                ],
              ),
              if (warranty.description != null && warranty.description!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  warranty.description!,
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
                  if (warranty.startDate != null)
                    _buildInfoChip(
                      icon: Icons.play_arrow,
                      label: 'Start: ${_formatDate(warranty.startDate!)}',
                    ),
                  if (warranty.endDate != null)
                    _buildInfoChip(
                      icon: Icons.event_available,
                      label: 'End: ${_formatDate(warranty.endDate!)}',
                      color: _getEndDateColor(warranty.endDate!),
                    ),
                  if (warranty.durationMonths != null)
                    _buildInfoChip(
                      icon: Icons.timer,
                      label: '${warranty.durationMonths} months',
                    ),
                  if (warranty.provider != null)
                    _buildInfoChip(
                      icon: Icons.business,
                      label: warranty.provider!,
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

  Widget _buildPagination(BuildContext context, ProjectWarrantyProvider provider) {
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
      case 'ACTIVE':
        return AppTheme.statusSuccess;
      case 'CLAIMED':
        return AppTheme.statusWarning;
      case 'EXPIRED':
        return Colors.grey;
      case 'VOID':
        return AppTheme.statusError;
      default:
        return Colors.grey;
    }
  }

  Color _getEndDateColor(DateTime date) {
    final now = DateTime.now();
    final diff = date.difference(now).inDays;
    if (diff < 0) return AppTheme.statusError;
    if (diff <= 90) return AppTheme.statusWarning;
    return AppTheme.statusSuccess;
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _navigateToDetail(BuildContext context, ProjectWarranty warranty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('View details for warranty ${warranty.id}')),
    );
  }

  void _navigateToCreate(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Create warranty - to be implemented')),
    );
  }
}


