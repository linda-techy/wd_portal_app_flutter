import 'package:flutter/foundation.dart';
import 'package:admin/services/customer_project_service.dart';
import 'package:admin/models/customer_project.dart';
import 'package:admin/models/project_stats.dart';
import 'package:admin/models/paginated_response.dart';

class CustomerProjectProvider with ChangeNotifier {
  final CustomerProjectService _service = CustomerProjectService();

  // State
  List<CustomerProject> _projects = [];
  PaginatedResponse<CustomerProject>? _paginatedProjects;
  CustomerProject? _selectedProject;
  ProjectStats? _stats;
  
  bool _isLoading = false;
  bool _isLoadingStats = false;
  String? _error;

  // Search and filter state
  String _searchQuery = '';
  int _currentPage = 0;
  int _pageSize = 20;
  String _sortBy = 'id';
  String _sortDirection = 'desc';

  // Getters
  List<CustomerProject> get projects => _projects;
  PaginatedResponse<CustomerProject>? get paginatedProjects => _paginatedProjects;
  CustomerProject? get selectedProject => _selectedProject;
  ProjectStats? get stats => _stats;
  bool get isLoading => _isLoading;
  bool get isLoadingStats => _isLoadingStats;
  String? get error => _error;
  String get searchQuery => _searchQuery;
  int get currentPage => _currentPage;
  int get pageSize => _pageSize;
  int get totalPages => _paginatedProjects?.totalPages ?? 0;
  int get totalElements => _paginatedProjects?.totalElements ?? 0;
  bool get hasNext => _paginatedProjects?.hasNext ?? false;
  bool get hasPrevious => _paginatedProjects?.hasPrevious ?? false;

  /// Fetch projects with pagination
  Future<void> fetchProjects({
    String? search,
    int? page,
    int? size,
    String? sortBy,
    String? sortDirection,
    bool refresh = false,
  }) async {
    if (refresh) {
      _currentPage = 0;
    }

    if (search != null) _searchQuery = search;
    if (page != null) _currentPage = page;
    if (size != null) _pageSize = size;
    if (sortBy != null) _sortBy = sortBy;
    if (sortDirection != null) _sortDirection = sortDirection;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _service.getProjects(
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
        page: _currentPage,
        size: _pageSize,
        sortBy: _sortBy,
        sortDirection: _sortDirection,
      );

      _paginatedProjects = response;
      _projects = response.content;
      _error = null;
    } catch (e) {
      _error = e.toString();
      _projects = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Go to next page
  Future<void> nextPage() async {
    if (hasNext) {
      await fetchProjects(page: _currentPage + 1);
    }
  }

  /// Go to previous page
  Future<void> previousPage() async {
    if (hasPrevious) {
      await fetchProjects(page: _currentPage - 1);
    }
  }

  /// Go to specific page
  Future<void> goToPage(int page) async {
    if (page >= 0 && page < totalPages) {
      await fetchProjects(page: page);
    }
  }

  /// Set search query and fetch
  Future<void> search(String query) async {
    _searchQuery = query;
    await fetchProjects(page: 0, refresh: true);
  }

  /// Clear search
  Future<void> clearSearch() async {
    _searchQuery = '';
    await fetchProjects(page: 0, refresh: true);
  }

  /// Fetch project by ID
  Future<void> fetchProjectById(int id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final project = await _service.getProjectById(id);
      _selectedProject = project;
      _error = null;
    } catch (e) {
      _error = e.toString();
      _selectedProject = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Create new project
  Future<bool> createProject(CustomerProject project) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final createdProject = await _service.createProject(project);
      _selectedProject = createdProject;
      
      // Refresh list to include new project
      await fetchProjects(refresh: true);
      
      _error = null;
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Update existing project
  Future<bool> updateProject(int id, CustomerProject project) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final updatedProject = await _service.updateProject(id, project);
      _selectedProject = updatedProject;
      
      // Update in local list if present
      final index = _projects.indexWhere((p) => p.id == id);
      if (index != -1) {
        _projects[index] = updatedProject;
      }
      
      _error = null;
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Delete project
  Future<bool> deleteProject(int id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _service.deleteProject(id);
      
      // Remove from local list
      _projects.removeWhere((p) => p.id == id);
      
      // Clear selected if it was deleted
      if (_selectedProject?.id == id) {
        _selectedProject = null;
      }
      
      // Refresh to update pagination
      await fetchProjects();
      
      _error = null;
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Fetch project statistics
  Future<void> fetchStats() async {
    _isLoadingStats = true;
    notifyListeners();

    try {
      final stats = await _service.getProjectStats();
      _stats = stats;
    } catch (e) {
      // Stats are optional, don't set error for this
      _stats = ProjectStats.empty();
    } finally {
      _isLoadingStats = false;
      notifyListeners();
    }
  }

  /// Clear selected project
  void clearSelectedProject() {
    _selectedProject = null;
    notifyListeners();
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Refresh all data
  Future<void> refresh() async {
    await Future.wait([
      fetchProjects(refresh: true),
      fetchStats(),
    ]);
  }
}

