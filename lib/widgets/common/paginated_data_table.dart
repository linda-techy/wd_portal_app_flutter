import 'package:flutter/material.dart';
import 'package:admin/providers/base_paginated_provider.dart';

/// Reusable paginated data table widget
/// Works with any BasePaginatedProvider
/// Provides consistent table UI with pagination controls
class PaginatedDataTable<T> extends StatelessWidget {
  final BasePaginatedProvider<T> provider;
  final List<DataColumn> columns;
  final DataRow Function(T item) rowBuilder;
  final Widget Function()? emptyBuilder;
  final Widget Function()? errorBuilder;
  final bool showSearch;
  final String? searchHint;
  final Widget? filterPanel;
  final Widget? header;
  final List<Widget>? actions;
  final bool showPagination;
  final bool showPageSizeSelector;
  final List<int> pageSizeOptions;

  const PaginatedDataTable({
    super.key,
    required this.provider,
    required this.columns,
    required this.rowBuilder,
    this.emptyBuilder,
    this.errorBuilder,
    this.showSearch = true,
    this.searchHint,
    this.filterPanel,
    this.header,
    this.actions,
    this.showPagination = true,
    this.showPageSizeSelector = true,
    this.pageSizeOptions = const [10, 20, 50, 100],
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header with actions
        if (header != null || actions != null) _buildHeader(),

        // Search and filters
        if (showSearch || filterPanel != null) _buildSearchAndFilters(),

        const SizedBox(height: 16),

        // Table
        Expanded(
          child: _buildTable(),
        ),

        // Pagination controls
        if (showPagination) _buildPagination(),
      ],
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (header != null) Expanded(child: header!),
          if (actions != null) ...actions!,
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          if (showSearch)
            Expanded(
              child: TextField(
                decoration: InputDecoration(
                  hintText: searchHint ?? 'Search...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: provider.searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () => provider.clearSearch(),
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onChanged: (value) => provider.search(value),
              ),
            ),
          if (showSearch && filterPanel != null) const SizedBox(width: 16),
          if (filterPanel != null) filterPanel!,
        ],
      ),
    );
  }

  Widget _buildTable() {
    if (provider.isLoading && !provider.hasData) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.error != null) {
      return errorBuilder?.call() ??
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Error: ${provider.error}',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => provider.refresh(),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          );
    }

    if (provider.isEmpty) {
      return emptyBuilder?.call() ??
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox_outlined, size: 48, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  provider.hasActiveFilters
                      ? 'No results found'
                      : 'No data available',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                if (provider.hasActiveFilters) ...[
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => provider.clearAll(),
                    icon: const Icon(Icons.clear_all),
                    label: const Text('Clear Filters'),
                  ),
                ],
              ],
            ),
          );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: DataTable(
          columns: columns,
          rows: provider.items.map(rowBuilder).toList(),
          sortColumnIndex: _getSortColumnIndex(),
          sortAscending: provider.sortDirection == 'asc',
        ),
      ),
    );
  }

  int? _getSortColumnIndex() {
    // Try to find column index by matching sortBy field
    // This is a simple implementation; you might need to enhance it
    return null;
  }

  Widget _buildPagination() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Page size selector
          if (showPageSizeSelector)
            Row(
              children: [
                const Text('Rows per page:'),
                const SizedBox(width: 8),
                DropdownButton<int>(
                  value: provider.pageSize,
                  items: pageSizeOptions.map((size) {
                    return DropdownMenuItem(
                      value: size,
                      child: Text(size.toString()),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      provider.changePageSize(value);
                    }
                  },
                ),
              ],
            ),

          // Page info
          Text(
            'Page ${provider.currentPage + 1} of ${provider.totalPages} '
            '(${provider.totalElements} total)',
            style: const TextStyle(fontSize: 14),
          ),

          // Navigation buttons
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.first_page),
                onPressed: provider.hasPrevious && !provider.isLoading
                    ? () => provider.firstPage()
                    : null,
                tooltip: 'First page',
              ),
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: provider.hasPrevious && !provider.isLoading
                    ? () => provider.previousPage()
                    : null,
                tooltip: 'Previous page',
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: provider.hasNext && !provider.isLoading
                    ? () => provider.nextPage()
                    : null,
                tooltip: 'Next page',
              ),
              IconButton(
                icon: const Icon(Icons.last_page),
                onPressed: provider.hasNext && !provider.isLoading
                    ? () => provider.lastPage()
                    : null,
                tooltip: 'Last page',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Sortable column helper
class SortableColumn extends DataColumn {
  SortableColumn({
    required String label,
    required String field,
    required BasePaginatedProvider provider,
    super.numeric,
  }) : super(
          label: Text(label),
          onSort: (columnIndex, ascending) {
            provider.changeSort(field);
          },
        );
}
