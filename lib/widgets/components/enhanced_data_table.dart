import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// Enhanced Data Table with Filtering, Sorting, and Responsive Design
class EnhancedDataTable<T> extends StatefulWidget {
  final List<DataColumn> columns;
  final List<DataRow> rows;
  final String? title;
  final bool showSearch;
  final bool showFilters;
  final List<FilterOption>? filterOptions;
  final Function(String)? onSearch;
  final Function(String, dynamic)? onFilter;
  final bool sortable;
  final Function(int, bool)? onSort;
  final Widget? headerActions;
  final bool paginated;
  final int currentPage;
  final int totalPages;
  final Function(int)? onPageChanged;
  final bool loading;
  final String? emptyMessage;
  
  const EnhancedDataTable({
    super.key,
    required this.columns,
    required this.rows,
    this.title,
    this.showSearch = true,
    this.showFilters = true,
    this.filterOptions,
    this.onSearch,
    this.onFilter,
    this.sortable = true,
    this.onSort,
    this.headerActions,
    this.paginated = false,
    this.currentPage = 1,
    this.totalPages = 1,
    this.onPageChanged,
    this.loading = false,
    this.emptyMessage,
  });
  
  @override
  State<EnhancedDataTable<T>> createState() => _EnhancedDataTableState<T>();
}

class _EnhancedDataTableState<T> extends State<EnhancedDataTable<T>> {
  final TextEditingController _searchController = TextEditingController();
  final Map<String, dynamic> _activeFilters = {};
  int? _sortColumnIndex;
  bool _sortAscending = true;
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header Section
        if (widget.title != null || widget.showSearch || widget.showFilters)
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingLG),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              border: Border(
                bottom: BorderSide(color: AppTheme.borderLight, width: 1),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title and Actions
                if (widget.title != null || widget.headerActions != null)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (widget.title != null)
                        Text(
                          widget.title!,
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                      if (widget.headerActions != null) widget.headerActions!,
                    ],
                  ),
                
                // Search and Filters
                if (widget.showSearch || widget.showFilters) ...[
                  if (widget.title != null || widget.headerActions != null)
                    const SizedBox(height: AppTheme.spacingMD),
                  Row(
                    children: [
                      // Search Bar
                      if (widget.showSearch)
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: 'Search...',
                              prefixIcon: const Icon(Icons.search, size: 20),
                              suffixIcon: _searchController.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear, size: 20),
                                      onPressed: () {
                                        _searchController.clear();
                                        widget.onSearch?.call('');
                                        setState(() {});
                                      },
                                    )
                                  : null,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: AppTheme.spacingMD,
                                vertical: AppTheme.spacingSM,
                              ),
                            ),
                            onChanged: (value) {
                              widget.onSearch?.call(value);
                              setState(() {});
                            },
                          ),
                        ),
                      
                      // Filter Chips
                      if (widget.showFilters && widget.filterOptions != null) ...[
                        const SizedBox(width: AppTheme.spacingMD),
                        Expanded(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: widget.filterOptions!.map((filter) {
                                final isActive = _activeFilters.containsKey(filter.key);
                                return Padding(
                                  padding: const EdgeInsets.only(right: AppTheme.spacingSM),
                                  child: FilterChip(
                                    label: Text(filter.label),
                                    selected: isActive,
                                    onSelected: (selected) {
                                      setState(() {
                                        if (selected) {
                                          _activeFilters[filter.key] = filter.defaultValue;
                                        } else {
                                          _activeFilters.remove(filter.key);
                                        }
                                        widget.onFilter?.call(filter.key, _activeFilters[filter.key]);
                                      });
                                    },
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
        
        // Table Section
        Expanded(
          child: widget.loading
              ? const Center(child: CircularProgressIndicator())
              : widget.rows.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(AppTheme.spacingXXL),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.inbox_outlined,
                              size: 64,
                              color: AppTheme.textTertiary,
                            ),
                            const SizedBox(height: AppTheme.spacingMD),
                            Text(
                              widget.emptyMessage ?? 'No data available',
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: AppTheme.textSecondary,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : _buildTable(context),
        ),
        
        // Pagination
        if (widget.paginated && widget.totalPages > 1)
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingMD),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              border: Border(
                top: BorderSide(color: AppTheme.borderLight, width: 1),
              ),
            ),
            child: _buildPagination(),
          ),
      ],
    );
  }
  
  Widget _buildTable(BuildContext context) {
    // Create sortable columns if sorting is enabled
    final columns = widget.sortable
        ? widget.columns.asMap().entries.map((entry) {
            final index = entry.key;
            final column = entry.value;
            return DataColumn(
              label: column.label,
              numeric: column.numeric,
              tooltip: column.tooltip,
              onSort: (columnIndex, ascending) {
                setState(() {
                  _sortColumnIndex = index;
                  _sortAscending = ascending;
                });
                widget.onSort?.call(index, ascending);
              },
            );
          }).toList()
        : widget.columns;
    
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: DataTable(
          columns: columns,
          rows: widget.rows,
          sortColumnIndex: widget.sortable ? _sortColumnIndex : null,
          sortAscending: widget.sortable ? _sortAscending : true,
          headingRowHeight: 56,
          dataRowMinHeight: 52,
          dataRowMaxHeight: 72,
          headingRowColor: WidgetStateProperty.all(AppTheme.surfaceElevated),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            border: Border.all(color: AppTheme.borderLight, width: 1),
            borderRadius: BorderRadius.circular(AppTheme.radiusMD),
          ),
          onSelectAll: (value) {},
        ),
      ),
    );
  }
  
  Widget _buildPagination() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: widget.currentPage > 1
              ? () => widget.onPageChanged?.call(widget.currentPage - 1)
              : null,
        ),
        const SizedBox(width: AppTheme.spacingSM),
        Text(
          'Page ${widget.currentPage} of ${widget.totalPages}',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(width: AppTheme.spacingSM),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: widget.currentPage < widget.totalPages
              ? () => widget.onPageChanged?.call(widget.currentPage + 1)
              : null,
        ),
      ],
    );
  }
}

class FilterOption {
  final String key;
  final String label;
  final dynamic defaultValue;
  
  FilterOption({
    required this.key,
    required this.label,
    this.defaultValue,
  });
}

