import 'package:flutter/material.dart';
import 'dart:async';
import '../../theme/app_theme.dart';
import '../../theme/responsive_utils.dart';
import '../../models/customer_project.dart';
import '../../services/crm_service.dart';
import '../../widgets/components/status_indicator.dart';
import 'add_customer_project_screen.dart';
import 'edit_customer_project_screen.dart';
import 'project_details_screen.dart';
import 'design_package_selection_screen.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/permission_provider.dart';
import '../../widgets/animations/entrance_animation.dart';
import '../../widgets/animations/shimmer_loading.dart';
import '../../utils/motion_toast.dart';

class CustomerProjectsScreen extends StatefulWidget {
  const CustomerProjectsScreen({super.key});

  @override
  State<CustomerProjectsScreen> createState() => _CustomerProjectsScreenState();
}

class _CustomerProjectsScreenState extends State<CustomerProjectsScreen> {
  List<CustomerProject> projects = [];
  bool isLoading = true;
  bool isMoreLoading = false;
  bool hasMore = true;
  int currentPage = 0;
  final int pageSize = 20;
  String? errorMessage;
  String searchQuery = '';
  final CRMService _crmService = CRMService();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _loadData();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !isMoreLoading &&
        hasMore &&
        !isLoading) {
      _loadMoreData();
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          searchQuery = query;
          currentPage = 0;
          projects = [];
          hasMore = true;
        });
        _loadData();
      }
    });
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        if (currentPage == 0) isLoading = true;
        errorMessage = null;
      });

      final response = await _crmService.getCustomerProjectsPaginated(
        page: currentPage,
        size: pageSize,
        search: searchQuery.isEmpty ? null : searchQuery,
      );

      if (mounted) {
        setState(() {
          if (currentPage == 0) {
            projects = response.data;
          } else {
            projects.addAll(response.data);
          }
          hasMore = response.hasNextPage;
          isLoading = false;
          isMoreLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
          isMoreLoading = false;
          errorMessage = _getErrorMessage(e);
        });
      }
    }
  }

  Future<void> _loadMoreData() async {
    if (isMoreLoading || !hasMore) return;

    setState(() {
      isMoreLoading = true;
      currentPage++;
    });

    _loadData();
  }

  Future<void> _loadProjects() async {
    setState(() {
      currentPage = 0;
      projects = [];
      hasMore = true;
    });
    await _loadData();
  }



  String _getErrorMessage(dynamic error) {
    if (error.toString().contains('SocketException') ||
        error.toString().contains('HandshakeException')) {
      return 'Network error. Please check your internet connection.';
    } else if (error.toString().contains('TimeoutException')) {
      return 'Request timed out. Please try again.';
    } else if (error.toString().contains('FormatException')) {
      return 'Invalid data received from server.';
    } else if (error.toString().contains('500')) {
      return 'Server error. Please try again later.';
    } else if (error.toString().contains('404')) {
      return 'Service not found. Please contact support.';
    } else {
      return 'Failed to load projects. Please try again.';
    }
  }

  Future<void> _refreshProjects() async {
    await _loadProjects();
  }

  Future<void> _deleteProject(CustomerProject project) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Project'),
        content: Text('Are you sure you want to delete "${project.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.statusError),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true && project.id != null) {
      try {
        await _crmService.deleteCustomerProject(project.id!);
        if (mounted) {
          MotionToast.show(
            context,
            message: 'Project deleted successfully',
            isError: false,
          );
          _loadProjects();
        }
      } catch (e) {
        if (mounted) {
          MotionToast.show(
            context,
            message: 'Failed to delete project: ${e.toString()}',
            isError: true,
          );
        }
      }
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return DateFormat('MMM dd, yyyy').format(date);
  }

  String _formatProgress(double? progress) {
    if (progress == null) return 'N/A';
    return '${progress.toStringAsFixed(1)}%';
  }

  @override
  Widget build(BuildContext context) {
    final permissions = Provider.of<PermissionProvider>(context);
    
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: AdaptiveContainer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            ResponsiveLayout(
              mobile: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Customer Projects',
                        style: Theme.of(context).textTheme.displaySmall,
                      ),
                      if (permissions.canCreateProject)
                        IconButton(
                          onPressed: () => _navigateToAddProject(),
                          icon: const Icon(Icons.add_circle, color: AppTheme.coralRed),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacingMD),
                  _buildSearchBar(),
                ],
              ),
              desktop: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Customer Projects',
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                  const SizedBox(width: AppTheme.spacingXL),
                  Expanded(child: _buildSearchBar()),
                  const SizedBox(width: AppTheme.spacingXL),
                  if (permissions.canCreateProject)
                    ElevatedButton.icon(
                      onPressed: () => _navigateToAddProject(),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Add Project'),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.spacingLG),

            // Error Message
            if (errorMessage != null)
              Container(
                padding: const EdgeInsets.all(AppTheme.spacingMD),
                margin: const EdgeInsets.only(bottom: AppTheme.spacingMD),
                decoration: BoxDecoration(
                  color: AppTheme.statusErrorBg,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                  border:
                      Border.all(color: AppTheme.statusError.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: AppTheme.statusError),
                    const SizedBox(width: AppTheme.spacingMD),
                    Expanded(child: Text(errorMessage!)),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        setState(() {
                          errorMessage = null;
                        });
                      },
                    ),
                  ],
                ),
              ),

            Expanded(
              child: isLoading
                  ? _buildShimmerGrid()
                  : projects.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.folder_open,
                                size: 64,
                                color: AppTheme.textTertiary,
                              ),
                              const SizedBox(height: AppTheme.spacingMD),
                              Text(
                                'No projects found',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.copyWith(
                                      color: AppTheme.textSecondary,
                                    ),
                              ),
                              const SizedBox(height: AppTheme.spacingSM),
                              // Add First Project button - Only show if user has CREATE permission
                              if (permissions.canCreateProject)
                                ElevatedButton.icon(
                                  onPressed: () async {
                                    final result = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const AddCustomerProjectScreen(),
                                      ),
                                    );
                                    if (result == true) {
                                      _loadProjects();
                                    }
                                  },
                                  icon: const Icon(Icons.add),
                                  label: const Text('Add First Project'),
                                ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _refreshProjects,
                          child: _buildProjectsCards(),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 500),
      child: TextField(
        controller: _searchController,
        onChanged: _onSearchChanged,
        decoration: InputDecoration(
          hintText: 'Search projects by name, code, location...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () {
                    _searchController.clear();
                    _onSearchChanged('');
                  },
                )
              : null,
          filled: true,
          fillColor: AppTheme.surface,
          contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
        ),
      ),
    );
  }

  Future<void> _navigateToAddProject() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddCustomerProjectScreen(),
      ),
    );
    if (result == true) {
      _loadProjects();
    }
  }

  Widget _buildProjectsCards() {
    if (projects.isEmpty) {
      return const SizedBox.shrink();
    }

    return ResponsiveLayout(
      mobile: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(AppTheme.spacingMD),
        itemCount: projects.length + (hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == projects.length) {
            return _buildLoader();
          }
          return EntranceAnimation(
            delay: Duration(milliseconds: 50 * (index % pageSize)),
            child: _buildProjectCard(projects[index]),
          );
        },
      ),
      desktop: Column(
        children: [
          Expanded(
            child: GridView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(AppTheme.spacingMD),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: AppTheme.spacingMD,
                mainAxisSpacing: AppTheme.spacingMD,
                childAspectRatio: 1.2,
              ),
              itemCount: projects.length,
              itemBuilder: (context, index) {
                return EntranceAnimation(
                  delay: Duration(milliseconds: 50 * (index % pageSize)),
                  child: _buildProjectCard(projects[index]),
                );
              },
            ),
          ),
          if (isMoreLoading) _buildLoader(),
        ],
      ),
    );
  }

  Widget _buildLoader() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(AppTheme.spacingMD),
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildProjectCard(CustomerProject project) {
    final customerName = project.name;
    final progress = project.progress ?? 0.0;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        side: BorderSide(color: AppTheme.borderLight, width: 1),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProjectDetailsScreen(project: project),
            ),
          );
        },
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingMD),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
            // Customer Name
            Row(
              children: [
                Icon(
                  Icons.person_outline,
                  size: 20,
                  color: AppTheme.primaryBlue,
                ),
                const SizedBox(width: AppTheme.spacingSM),
                Expanded(
                  child: Text(
                    customerName,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingMD),

            // Location
            Row(
              children: [
                Icon(
                  Icons.location_on_outlined,
                  size: 18,
                  color: AppTheme.textSecondary,
                ),
                const SizedBox(width: AppTheme.spacingSM),
                Expanded(
                  child: Text(
                    project.location,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingLG),

            // Progress Bar or Design Package Selection
            if (project.isDesignAgreementSigned)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Progress',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                      ),
                      Text(
                        _formatProgress(project.progress),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: _getProgressColor(progress),
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacingXS),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                    child: LinearProgressIndicator(
                      value: (progress / 100).clamp(0.0, 1.0),
                      minHeight: 8,
                      backgroundColor: AppTheme.borderLight,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _getProgressColor(progress),
                      ),
                    ),
                  ),
                ],
              )
            else if (project.projectPhase?.toLowerCase() == 'design')
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DesignPackageSelectionScreen(
                          project: project,
                        ),
                      ),
                    );
                    if (result == true) {
                      _loadProjects();
                    }
                  },
                  icon: const Icon(Icons.design_services, size: 16),
                  label: const Text('Action Required: Select Package & Sign Agreement'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              )
            else
              const SizedBox(height: 48), // Spacer to maintain card height consistency
            
            const SizedBox(height: AppTheme.spacingMD),

            // Actions
            Consumer<PermissionProvider>(
              builder: (context, permissions, child) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Edit button - Only show if user has EDIT permission
                    if (permissions.canEditProject)
                      IconButton(
                        icon: const Icon(Icons.edit, size: 20),
                        color: AppTheme.primaryBlue,
                        onPressed: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EditCustomerProjectScreen(
                                project: project,
                              ),
                            ),
                          );
                          if (result == true) {
                            _loadProjects();
                          }
                        },
                        tooltip: 'Edit',
                      ),
                    // Delete button - Only show if user has DELETE permission
                    if (permissions.canDeleteProject)
                      IconButton(
                        icon: const Icon(Icons.delete, size: 20),
                        color: AppTheme.statusError,
                        onPressed: () => _deleteProject(project),
                        tooltip: 'Delete',
                      ),
                  ],
                );
              },
            ),
            ],
          ),
        ),
      ),
    );
  }

  StatusType _getPhaseType(String phase) {
    final lowerPhase = phase.toLowerCase();
    if (lowerPhase.contains('planning') || lowerPhase.contains('design')) {
      return StatusType.info;
    } else if (lowerPhase.contains('progress') ||
        lowerPhase.contains('ongoing')) {
      return StatusType.primary;
    } else if (lowerPhase.contains('complete') ||
        lowerPhase.contains('finished')) {
      return StatusType.success;
    } else if (lowerPhase.contains('hold') || lowerPhase.contains('pause')) {
      return StatusType.warning;
    }
    return StatusType.neutral;
  }

  Color _getProgressColor(double progress) {
    if (progress >= 80) return AppTheme.statusSuccess;
    if (progress >= 50) return AppTheme.safetyOrange;
    if (progress >= 25) return AppTheme.safetyYellow;
    return AppTheme.statusError;
  }

  Widget _buildShimmerGrid() {
    return ResponsiveLayout(
      mobile: ListView.builder(
        padding: const EdgeInsets.all(AppTheme.spacingMD),
        itemCount: 4,
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.only(bottom: AppTheme.spacingMD),
          child: const ShimmerLoading(width: double.infinity, height: 180),
        ),
      ),
      desktop: GridView.builder(
        padding: const EdgeInsets.all(AppTheme.spacingMD),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: AppTheme.spacingMD,
          mainAxisSpacing: AppTheme.spacingMD,
          childAspectRatio: 1.2,
        ),
        itemCount: 6,
        itemBuilder: (context, index) => const ShimmerLoading(width: double.infinity, height: double.infinity),
      ),
    );
  }
}
