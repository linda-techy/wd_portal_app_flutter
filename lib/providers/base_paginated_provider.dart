import 'package:flutter/foundation.dart';
import 'package:admin/models/paginated_response.dart';

///
/// Base provider class for paginated data across all modules
/// Provides standardized pagination, search, filter, and sorting logic
///
/// Enterprise-grade pattern for consistent state management
/// All module-specific providers should extend this class
///
abstract class BasePaginatedProvider<T> extends ChangeNotifier {
  // =====================================================
  // State
  // =====================================================
  PaginatedResponse<T>? _paginatedData;
  bool _isLoading = false;
  String? _error;

  // =====================================================
  // Pagination
  // =====================================================
  int _currentPage = 0; // 0-based indexing for backend compatibility
  int _pageSize = 20;

  // =====================================================
  // Search & Filters
  // =====================================================
  String _searchQuery = '';
  Map<String, dynamic> _filters = {};

  // =====================================================
  // Sorting
  // =====================================================
  String _sortBy = 'id';
  String _sortDirection = 'desc'; // 'asc' or 'desc'

  // =====================================================
  // Getters
  // =====================================================

  /// Get list of items from current page
  List<T> get items => _paginatedData?.content ?? [];

  /// Loading state
  bool get isLoading => _isLoading;

  /// Error message
  String? get error => _error;

  /// Current search query
  String get searchQuery => _searchQuery;

  /// Current filters
  Map<String, dynamic> get filters => Map.unmodifiable(_filters);

  /// Pagination state
  int get currentPage => _currentPage;
  int get pageSize => _pageSize;
  int get totalPages => _paginatedData?.totalPages ?? 0;
  int get totalElements => _paginatedData?.totalElements ?? 0;
  bool get hasNext => _paginatedData?.hasNext ?? false;
  bool get hasPrevious => _paginatedData?.hasPrevious ?? false;
  bool get isEmpty => items.isEmpty && !_isLoading;
  bool get hasData => items.isNotEmpty;

  /// Sorting state
  String get sortBy => _sortBy;
  String get sortDirection => _sortDirection;

  // =====================================================
  // Abstract Methods (Must implement in child classes)
  // =====================================================

  /// Fetch data from API
  /// Child classes must implement this to call their specific service
  Future<PaginatedResponse<T>> fetchFromApi({
    required int page,
    required int size,
    required String sortBy,
    required String sortDirection,
    String? search,
    Map<String, dynamic>? filters,
  });

  // =====================================================
  // Common Methods
  // =====================================================

  /// Fetch data with current state
  Future<void> fetch({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 0;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _paginatedData = await fetchFromApi(
        page: _currentPage,
        size: _pageSize,
        sortBy: _sortBy,
        sortDirection: _sortDirection,
        search: _searchQuery.isEmpty ? null : _searchQuery,
        filters: _filters,
      );
      _error = null;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error fetching data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Search with query
  Future<void> search(String query) async {
    _searchQuery = query.trim();
    _currentPage = 0; // Reset to first page
    await fetch();
  }

  /// Clear search
  Future<void> clearSearch() async {
    _searchQuery = '';
    _currentPage = 0;
    await fetch();
  }

  /// Apply filters
  Future<void> applyFilters(Map<String, dynamic> filters) async {
    _filters = Map<String, dynamic>.from(filters);
    _currentPage = 0; // Reset to first page
    await fetch();
  }

  /// Update a single filter
  Future<void> updateFilter(String key, dynamic value) async {
    if (value == null || (value is String && value.isEmpty)) {
      _filters.remove(key);
    } else {
      _filters[key] = value;
    }
    _currentPage = 0;
    await fetch();
  }

  /// Clear all filters
  Future<void> clearFilters() async {
    _filters = {};
    _currentPage = 0;
    await fetch();
  }

  /// Clear search and filters
  Future<void> clearAll() async {
    _searchQuery = '';
    _filters = {};
    _currentPage = 0;
    await fetch();
  }

  /// Go to next page
  Future<void> nextPage() async {
    if (hasNext && !_isLoading) {
      _currentPage++;
      await fetch();
    }
  }

  /// Go to previous page
  Future<void> previousPage() async {
    if (hasPrevious && !_isLoading) {
      _currentPage--;
      await fetch();
    }
  }

  /// Go to specific page (0-based)
  Future<void> goToPage(int page) async {
    if (page >= 0 && page < totalPages && page != _currentPage && !_isLoading) {
      _currentPage = page;
      await fetch();
    }
  }

  /// Go to first page
  Future<void> firstPage() async {
    if (_currentPage != 0 && !_isLoading) {
      _currentPage = 0;
      await fetch();
    }
  }

  /// Go to last page
  Future<void> lastPage() async {
    if (totalPages > 0) {
      final lastPageIndex = totalPages - 1;
      if (_currentPage != lastPageIndex && !_isLoading) {
        _currentPage = lastPageIndex;
        await fetch();
      }
    }
  }

  /// Change page size
  Future<void> changePageSize(int newSize) async {
    if (newSize > 0 && newSize <= 100 && newSize != _pageSize) {
      _pageSize = newSize;
      _currentPage = 0; // Reset to first page
      await fetch();
    }
  }

  /// Change sorting
  /// If clicking same field, toggle direction
  /// If clicking different field, use descending by default
  Future<void> changeSort(String field) async {
    if (_sortBy == field) {
      // Toggle direction
      _sortDirection = _sortDirection == 'asc' ? 'desc' : 'asc';
    } else {
      // New field, default to descending
      _sortBy = field;
      _sortDirection = 'desc';
    }
    _currentPage = 0; // Reset to first page
    await fetch();
  }

  /// Refresh data (keep current page)
  Future<void> refresh() async {
    await fetch(refresh: false);
  }

  /// Reset to initial state and fetch
  Future<void> reset() async {
    _searchQuery = '';
    _filters = {};
    _currentPage = 0;
    _pageSize = 20;
    _sortBy = 'id';
    _sortDirection = 'desc';
    await fetch();
  }

  /// Check if a filter is active
  bool hasFilter(String key) {
    return _filters.containsKey(key) && _filters[key] != null;
  }

  /// Get filter value
  dynamic getFilter(String key) {
    return _filters[key];
  }

  /// Check if any filters are active
  bool get hasActiveFilters => _filters.isNotEmpty || _searchQuery.isNotEmpty;

  /// Get active filters count
  int get activeFiltersCount {
    int count = _filters.length;
    if (_searchQuery.isNotEmpty) count++;
    return count;
  }
}
