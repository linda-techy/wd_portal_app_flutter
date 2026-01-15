import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:admin/models/project_variation.dart';
import 'package:admin/providers/project_variation_provider.dart';
import 'package:admin/widgets/common/search_bar_widget.dart';
import 'package:admin/theme/app_theme.dart';
import 'package:admin/providers/permission_provider.dart';

class ProjectVariationsScreen extends StatelessWidget {
  const ProjectVariationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ProjectVariationProvider()..fetch(),
      child: Consumer<ProjectVariationProvider>(
        builder: (context, provider, _) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Project Variations'),
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
            body: Column(
              children: [
                _buildSearchAndFilters(context, provider),
                Expanded(child: _buildVariationList(context, provider)),
                if (provider.totalPages > 1)
                  _buildPagination(context, provider),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSearchAndFilters(BuildContext context, ProjectVariationProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[100],
      child: Column(
        children: [
          SearchBarWidget(
            onSearch: (query) => provider.search(query),
            hintText: 'Search project variations...',
          ),
          const SizedBox(height: 12),
          _buildFilterChips(context, provider),
        ],
      ),
    );
  }

  Widget _buildFilterChips(BuildContext context, ProjectVariationProvider provider) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildFilterChip(
          context,
          label: 'All',
          isSelected: provider.filters['approvalStatus'] == null,
          onTap: () => provider.clearFilters(),
        ),
        _buildFilterChip(
          context,
          label: 'Pending',
          isSelected: provider.filters['approvalStatus'] == 'PENDING',
          onTap: () => provider.updateFilter('approvalStatus', 'PENDING'),
          color: AppTheme.statusWarning,
        ),
        _buildFilterChip(
          context,
          label: 'Approved',
          isSelected: provider.filters['approvalStatus'] == 'APPROVED',
          onTap: () => provider.updateFilter('approvalStatus', 'APPROVED'),
          color: AppTheme.statusSuccess,
        ),
        _buildFilterChip(
          context,
          label: 'Rejected',
          isSelected: provider.filters['approvalStatus'] == 'REJECTED',
          onTap: () => provider.updateFilter('approvalStatus', 'REJECTED'),
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

  Widget _buildVariationList(BuildContext context, ProjectVariationProvider provider) {
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
            Icon(Icons.change_circle, size: 48, color: Colors.grey),
            SizedBox(height: 16),
            Text('No project variations found', style: TextStyle(fontSize: 16)),
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
          final variation = provider.items[index];
          return _buildVariationCard(context, variation);
        },
      ),
    );
  }

  Widget _buildVariationCard(BuildContext context, ProjectVariation variation) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: () => _navigateToDetail(context, variation),
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
                          variation.variationType ?? 'Variation',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (variation.projectName != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            variation.projectName!,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (variation.approvalStatus != null)
                    _buildStatusBadge(variation.approvalStatus!),
                ],
              ),
              if (variation.description != null && variation.description!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  variation.description!,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  if (variation.requestedByName != null)
                    _buildInfoChip(
                      icon: Icons.person,
                      label: variation.requestedByName!,
                    ),
                  if (variation.estimatedCost != null)
                    _buildInfoChip(
                      icon: Icons.currency_rupee,
                      label: '₹${variation.estimatedCost!.toStringAsFixed(2)}',
                      color: _getCostColor(variation.estimatedCost!),
                    ),
                  if (variation.requestDate != null)
                    _buildInfoChip(
                      icon: Icons.calendar_today,
                      label: _formatDate(variation.requestDate!),
                    ),
                  if (variation.approvedDate != null)
                    _buildInfoChip(
                      icon: Icons.check_circle,
                      label: 'Approved: ${_formatDate(variation.approvedDate!)}',
                      color: AppTheme.statusSuccess,
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

  Widget _buildPagination(BuildContext context, ProjectVariationProvider provider) {
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
      case 'REJECTED':
        return AppTheme.statusError;
      default:
        return Colors.grey;
    }
  }

  Color _getCostColor(double cost) {
    if (cost > 100000) return AppTheme.statusError;
    if (cost > 50000) return AppTheme.statusWarning;
    return AppTheme.statusSuccess;
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _navigateToDetail(BuildContext context, ProjectVariation variation) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('View details for variation ${variation.id}')),
    );
  }

  void _navigateToCreate(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Create project variation - to be implemented')),
    );
  }
}


