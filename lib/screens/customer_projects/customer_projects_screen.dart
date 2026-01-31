import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:admin/models/customer_project.dart';
import 'package:admin/providers/customer_project_provider_paginated.dart';
import 'package:admin/widgets/common/search_bar_widget.dart';
import 'package:admin/theme/app_theme.dart';
import 'package:admin/providers/permission_provider.dart';
import 'package:admin/services/customer_project_service.dart';
import 'package:admin/utils/motion_toast.dart';
import 'add_customer_project_screen.dart';
import 'edit_customer_project_screen.dart';
import 'project_details_screen.dart';

class CustomerProjectsScreen extends StatelessWidget {
  const CustomerProjectsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CustomerProjectProviderPaginated()..fetch(),
      child: Consumer<CustomerProjectProviderPaginated>(
        builder: (context, provider, _) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Projects'),
              actions: [
                Consumer<PermissionProvider>(
                  builder: (context, permissionProvider, _) {
                    if (permissionProvider.hasPermission('project:create')) {
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
                      Expanded(child: _buildProjectList(context, provider)),
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
      BuildContext context, CustomerProjectProviderPaginated provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[100],
      child: Column(
        children: [
          SearchBarWidget(
            onSearch: (query) => provider.search(query),
            hintText: 'Search projects...',
          ),
          const SizedBox(height: 12),
          _buildFilterChips(context, provider),
        ],
      ),
    );
  }

  Widget _buildFilterChips(
      BuildContext context, CustomerProjectProviderPaginated provider) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        // Project Phase filters
        _buildFilterChip(
          context,
          label: 'All Phases',
          isSelected: provider.filters['projectPhase'] == null,
          onTap: () => provider.clearFilters(),
        ),
        _buildFilterChip(
          context,
          label: 'Planning',
          isSelected: provider.filters['projectPhase'] == 'PLANNING',
          onTap: () => provider.updateFilter('projectPhase', 'PLANNING'),
        ),
        _buildFilterChip(
          context,
          label: 'Design',
          isSelected: provider.filters['projectPhase'] == 'DESIGN',
          onTap: () => provider.updateFilter('projectPhase', 'DESIGN'),
        ),
        _buildFilterChip(
          context,
          label: 'Construction',
          isSelected: provider.filters['projectPhase'] == 'CONSTRUCTION',
          onTap: () => provider.updateFilter('projectPhase', 'CONSTRUCTION'),
        ),
        _buildFilterChip(
          context,
          label: 'Completed',
          isSelected: provider.filters['projectPhase'] == 'COMPLETED',
          onTap: () => provider.updateFilter('projectPhase', 'COMPLETED'),
        ),
        const SizedBox(width: 16),
        // Project Type filters
        _buildFilterChip(
          context,
          label: 'Residential',
          isSelected: provider.filters['projectType'] == 'RESIDENTIAL',
          onTap: () => provider.updateFilter('projectType', 'RESIDENTIAL'),
        ),
        _buildFilterChip(
          context,
          label: 'Commercial',
          isSelected: provider.filters['projectType'] == 'COMMERCIAL',
          onTap: () => provider.updateFilter('projectType', 'COMMERCIAL'),
        ),
        _buildFilterChip(
          context,
          label: 'Industrial',
          isSelected: provider.filters['projectType'] == 'INDUSTRIAL',
          onTap: () => provider.updateFilter('projectType', 'INDUSTRIAL'),
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

  Widget _buildProjectList(
      BuildContext context, CustomerProjectProviderPaginated provider) {
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
            Icon(Icons.business, size: 48, color: Colors.grey),
            SizedBox(height: 16),
            Text('No projects found', style: TextStyle(fontSize: 16)),
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
          final project = provider.items[index];
          return _buildProjectCard(context, project);
        },
      ),
    );
  }

  Widget _buildProjectCard(BuildContext context, CustomerProject project) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: () => _navigateToDetail(context, project),
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
                          project.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (project.code != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            project.code!,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (project.projectPhase != null)
                        _buildPhaseBadge(project.projectPhase!),
                      const SizedBox(width: 8),
                      Consumer<PermissionProvider>(
                        builder: (context, permissionProvider, _) {
                          return PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert),
                            onSelected: (value) {
                              if (value == 'edit') {
                                _navigateToEdit(context, project);
                              } else if (value == 'delete') {
                                _confirmAndDelete(context, project);
                              }
                            },
                            itemBuilder: (context) => [
                              if (permissionProvider.hasPermission('project:edit'))
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
                              if (permissionProvider.hasPermission('project:delete'))
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
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (project.progress != null) ...[
                Row(
                  children: [
                    Expanded(
                      child: LinearProgressIndicator(
                        value: project.progress! / 100.0,
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _getProgressColor(project.progress!),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${project.progress!.toStringAsFixed(0)}%',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  _buildInfoChip(
                    icon: Icons.location_on,
                    label: project.location,
                  ),
                  if (project.projectType != null)
                    _buildInfoChip(
                      icon: Icons.category,
                      label: project.projectType!,
                    ),
                  if (project.contractType != null)
                    _buildInfoChip(
                      icon: Icons.description,
                      label: project.contractType!,
                    ),
                  if (project.sqfeet != null)
                    _buildInfoChip(
                      icon: Icons.square_foot,
                      label: '${project.sqfeet!.toStringAsFixed(0)} sq.ft',
                    ),
                  if (project.startDate != null)
                    _buildInfoChip(
                      icon: Icons.calendar_today,
                      label: _formatDate(project.startDate!),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhaseBadge(String phase) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getPhaseColor(phase),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        phase,
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
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildPagination(
      BuildContext context, CustomerProjectProviderPaginated provider) {
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

  Color _getPhaseColor(String phase) {
    switch (phase.toUpperCase()) {
      case 'COMPLETED':
        return AppTheme.statusSuccess;
      case 'CONSTRUCTION':
        return AppTheme.statusWarning;
      case 'DESIGN':
        return Colors.blue;
      case 'PLANNING':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  Color _getProgressColor(double progress) {
    if (progress >= 75) return AppTheme.statusSuccess;
    if (progress >= 50) return AppTheme.statusWarning;
    if (progress >= 25) return Colors.orange;
    return AppTheme.statusError;
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _navigateToDetail(BuildContext context, CustomerProject project) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProjectDetailsScreen(project: project),
      ),
    ).then((_) {
      // Refresh the list when returning from detail screen
      final provider = Provider.of<CustomerProjectProviderPaginated>(context, listen: false);
      provider.fetch();
    });
  }

  void _navigateToCreate(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddCustomerProjectScreen(),
      ),
    ).then((_) {
      // Refresh the list when returning from create screen
      final provider = Provider.of<CustomerProjectProviderPaginated>(context, listen: false);
      provider.fetch();
    });
  }

  void _navigateToEdit(BuildContext context, CustomerProject project) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditCustomerProjectScreen(project: project),
      ),
    ).then((_) {
      // Refresh the list when returning from edit screen
      final provider = Provider.of<CustomerProjectProviderPaginated>(context, listen: false);
      provider.fetch();
    });
  }

  Future<void> _confirmAndDelete(BuildContext context, CustomerProject project) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Delete Project'),
          content: Text(
            'Are you sure you want to delete "${project.name}"? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed == true && context.mounted) {
      try {
        final service = CustomerProjectService();
        await service.deleteProject(project.id!);
        
        if (context.mounted) {
          MotionToast.showSuccess(
            context,
            message: 'Project deleted successfully',
          );
          
          // Refresh the list
          final provider = Provider.of<CustomerProjectProviderPaginated>(context, listen: false);
          provider.fetch();
        }
      } catch (e) {
        if (context.mounted) {
          MotionToast.showError(
            context,
            message: 'Failed to delete project: ${e.toString()}',
          );
        }
      }
    }
  }
}
