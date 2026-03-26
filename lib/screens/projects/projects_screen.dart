import 'package:flutter/material.dart';
import 'package:admin/constants.dart';
import 'package:admin/theme/app_theme.dart';
import 'package:admin/theme/responsive_utils.dart';
import 'package:provider/provider.dart';
import 'package:admin/providers/customer_project_provider.dart';
import 'package:admin/screens/projects/widgets/project_stats_widget.dart';
import 'package:admin/screens/projects/widgets/project_card.dart';
import 'package:admin/screens/projects/widgets/project_phase_badge.dart';
import 'package:admin/screens/projects/widgets/project_filters_widget.dart';
import 'package:admin/screens/projects/project_detail_screen.dart';
import 'package:admin/screens/projects/project_form_dialog.dart';
import 'package:admin/widgets/error_state_widget.dart';
import 'package:intl/intl.dart';

class ProjectsScreen extends StatefulWidget {
  const ProjectsScreen({super.key});

  @override
  ProjectsScreenState createState() => ProjectsScreenState();
}

class ProjectsScreenState extends State<ProjectsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedPhase;
  String? _selectedType;
  bool _showFilters = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final projectProvider = context.read<CustomerProjectProvider>();
    await projectProvider.refresh();
  }

  void _onSearch(String query) {
    final projectProvider = context.read<CustomerProjectProvider>();
    projectProvider.search(query);
  }

  void _clearSearch() {
    _searchController.clear();
    final projectProvider = context.read<CustomerProjectProvider>();
    projectProvider.clearSearch();
  }

  void _applyFilters() {
    final projectProvider = context.read<CustomerProjectProvider>();
    // Use search with filter keywords for phase/type
    final filterParts = <String>[];
    if (_selectedPhase != null && _selectedPhase!.isNotEmpty) {
      filterParts.add(_selectedPhase!);
    }
    if (_selectedType != null && _selectedType!.isNotEmpty) {
      filterParts.add(_selectedType!);
    }
    if (filterParts.isNotEmpty) {
      projectProvider.search(filterParts.join(' '));
    } else {
      projectProvider.clearSearch();
    }
  }

  void _showCreateDialog() {
    showDialog(
      context: context,
      builder: (context) => const ProjectFormDialog(),
    ).then((result) {
      if (result == true) {
        _loadData();
      }
    });
  }

  void _showEditDialog(int projectId) {
    showDialog(
      context: context,
      builder: (context) => ProjectFormDialog(projectId: projectId),
    ).then((result) {
      if (result == true) {
        _loadData();
      }
    });
  }

  Future<void> _deleteProject(int projectId, String projectName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Are you sure you want to delete "$projectName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.statusError,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final projectProvider = context.read<CustomerProjectProvider>();
      final success = await projectProvider.deleteProject(projectId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success
                ? 'Project deleted successfully'
                : 'Failed to delete project'),
            backgroundColor: success ? AppTheme.statusSuccess : AppTheme.statusError,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Container(
        padding: const EdgeInsets.all(defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            _buildHeader(),
            const SizedBox(height: defaultPadding),

            // Stats Cards
            Consumer<CustomerProjectProvider>(
              builder: (context, provider, child) {
                if (provider.stats != null) {
                  return Column(
                    children: [
                      ProjectStatsWidget(stats: provider.stats!),
                      const SizedBox(height: defaultPadding),
                    ],
                  );
                }
                return const SizedBox.shrink();
              },
            ),

            // Search and Filters
            _buildSearchAndFilters(),
            const SizedBox(height: defaultPadding),

            // Projects List/Table
            Expanded(
              child: _buildProjectsList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          "Projects Management",
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        ElevatedButton.icon(
          onPressed: _showCreateDialog,
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Create Project'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchAndFilters() {
    return Row(
      children: [
        // Search Bar
        Expanded(
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search projects by name, location, or code...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: _clearSearch,
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusSM),
              ),
              filled: true,
              fillColor: AppTheme.surface,
            ),
            onSubmitted: _onSearch,
            onChanged: (value) => setState(() {}),
          ),
        ),
        const SizedBox(width: AppTheme.spacingMD),

        // Filter Button
        IconButton.outlined(
          onPressed: () => setState(() => _showFilters = !_showFilters),
          icon: Icon(
            _showFilters ? Icons.filter_list_off : Icons.filter_list,
            color: _showFilters ? AppTheme.primaryColor : null,
          ),
          tooltip: 'Filters',
        ),

        const SizedBox(width: AppTheme.spacingSM),

        // Refresh Button
        IconButton.outlined(
          onPressed: _loadData,
          icon: const Icon(Icons.refresh),
          tooltip: 'Refresh',
        ),
      ],
    );
  }

  Widget _buildProjectsList() {
    return Consumer<CustomerProjectProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.projects.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.error != null) {
          return ErrorStateWidget(
            message: provider.error!,
            onRetry: _loadData,
          );
        }

        if (provider.projects.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.folder_open, size: 64, color: AppTheme.textSecondary),
                const SizedBox(height: AppTheme.spacingMD),
                Text(
                  'No projects found',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: AppTheme.spacingSM),
                Text(
                  'Create your first project to get started',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                ),
                const SizedBox(height: AppTheme.spacingLG),
                ElevatedButton.icon(
                  onPressed: _showCreateDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Create Project'),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            // Filters Panel (if shown)
            if (_showFilters) ...[
              ProjectFiltersWidget(
                selectedPhase: _selectedPhase,
                selectedType: _selectedType,
                onPhaseChanged: (value) {
                  setState(() => _selectedPhase = value);
                  _applyFilters();
                },
                onTypeChanged: (value) {
                  setState(() => _selectedType = value);
                  _applyFilters();
                },
                onClear: () {
                  setState(() {
                    _selectedPhase = null;
                    _selectedType = null;
                  });
                  _applyFilters();
                },
              ),
              const SizedBox(height: AppTheme.spacingMD),
            ],

            // Projects Data Table
            Expanded(
              child: ResponsiveUtils.isDesktop(context)
                  ? _buildDataTable(provider)
                  : _buildGridView(provider),
            ),

            // Pagination Controls
            if (provider.totalPages > 1) ...[
              const SizedBox(height: AppTheme.spacingMD),
              _buildPaginationControls(provider),
            ],
          ],
        );
      },
    );
  }

  Widget _buildDataTable(CustomerProjectProvider provider) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: SingleChildScrollView(
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(AppTheme.surfaceElevated),
          columns: const [
            DataColumn(label: Text('Code')),
            DataColumn(label: Text('Name')),
            DataColumn(label: Text('Location')),
            DataColumn(label: Text('Phase')),
            DataColumn(label: Text('Type')),
            DataColumn(label: Text('Start Date')),
            DataColumn(label: Text('Actions')),
          ],
          rows: provider.projects.map((project) {
            return DataRow(
              onSelectChanged: (_) {
                if (project.id != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProjectDetailScreen(projectId: project.id!),
                    ),
                  );
                }
              },
              cells: [
                DataCell(Text(project.code ?? '-')),
                DataCell(
                  Text(
                    project.name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                DataCell(Text(project.location)),
                DataCell(
                  project.projectPhase != null
                      ? ProjectPhaseBadge(phase: project.projectPhase!, compact: true)
                      : const Text('-'),
                ),
                DataCell(Text(project.projectType ?? '-')),
                DataCell(
                  Text(
                    project.startDate != null
                        ? DateFormat('MMM dd, yyyy').format(project.startDate!)
                        : '-',
                  ),
                ),
                DataCell(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, size: 18),
                        onPressed: () => project.id != null ? _showEditDialog(project.id!) : null,
                        tooltip: 'Edit',
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, size: 18, color: AppTheme.statusError),
                        onPressed: () => project.id != null
                            ? _deleteProject(project.id!, project.name)
                            : null,
                        tooltip: 'Delete',
                      ),
                    ],
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildGridView(CustomerProjectProvider provider) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: AppTheme.spacingMD,
        mainAxisSpacing: AppTheme.spacingMD,
        childAspectRatio: 1.2,
      ),
      itemCount: provider.projects.length,
      itemBuilder: (context, index) {
        final project = provider.projects[index];
        return ProjectCard(
          project: project,
          onTap: () {
            if (project.id != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProjectDetailScreen(projectId: project.id!),
                ),
              );
            }
          },
          onEdit: () => project.id != null ? _showEditDialog(project.id!) : null,
          onDelete: () =>
              project.id != null ? _deleteProject(project.id!, project.name) : null,
        );
      },
    );
  }

  Widget _buildPaginationControls(CustomerProjectProvider provider) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMD),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Showing ${provider.projects.length} of ${provider.totalElements} projects',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          Row(
            children: [
              IconButton(
                onPressed: provider.hasPrevious ? () => provider.previousPage() : null,
                icon: const Icon(Icons.chevron_left),
                tooltip: 'Previous',
              ),
              Text(
                'Page ${provider.currentPage + 1} of ${provider.totalPages}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              IconButton(
                onPressed: provider.hasNext ? () => provider.nextPage() : null,
                icon: const Icon(Icons.chevron_right),
                tooltip: 'Next',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

