import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:admin/features/leads/data/models/lead.dart';
import 'package:admin/features/leads/presentation/providers/lead_provider.dart';
import 'package:admin/constants/lead_status_constants.dart';
import 'package:admin/constants/lead_source_constants.dart';
import 'package:admin/constants/priority_constants.dart';
import 'package:admin/constants/customer_type_constants.dart';
import 'package:admin/constants/project_type_constants.dart';
import 'package:admin/theme/app_theme.dart';
import 'package:admin/responsive.dart';
import 'add_lead_screen.dart';
import 'edit_lead_screen.dart';

/// New LeadsScreen using standardized LeadProvider
/// This demonstrates the pattern for all 22 modules
class LeadsScreenNew extends StatelessWidget {
  const LeadsScreenNew({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => LeadProvider()..fetch(),
      child: const _LeadsScreenContent(),
    );
  }
}

class _LeadsScreenContent extends StatefulWidget {
  const _LeadsScreenContent();

  @override
  State<_LeadsScreenContent> createState() => _LeadsScreenContentState();
}

class _LeadsScreenContentState extends State<_LeadsScreenContent> {
  final TextEditingController _searchController = TextEditingController();
  bool _showFilters = false;

  // Filter controllers
  String? _statusFilter;
  String? _sourceFilter;
  String? _priorityFilter;
  String? _customerTypeFilter;
  String? _projectTypeFilter;
  DateTimeRange? _dateRange;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Leads'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => setState(() => _showFilters = !_showFilters),
            tooltip: 'Toggle Filters',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<LeadProvider>().refresh(),
            tooltip: 'Refresh',
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Add Lead'),
              onPressed: () => _navigateToAddLead(context),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(context),
          if (_showFilters) _buildFilterPanel(context),
          _buildActiveFiltersChips(context),
          Expanded(child: _buildLeadsList(context)),
          _buildPaginationControls(context),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      color: Theme.of(context).cardColor,
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search leads by name, email, phone, company...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    context.read<LeadProvider>().clearSearch();
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
        ),
        onSubmitted: (value) {
          context.read<LeadProvider>().search(value);
        },
      ),
    );
  }

  Widget _buildFilterPanel(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      color: Theme.of(context).cardColor.withOpacity(0.5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filters',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _buildStatusFilter(),
              _buildSourceFilter(),
              _buildPriorityFilter(),
              _buildCustomerTypeFilter(),
              _buildProjectTypeFilter(),
              _buildDateRangeFilter(context),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => _clearAllFilters(context),
                child: const Text('Clear All'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () => _applyFilters(context),
                child: const Text('Apply Filters'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusFilter() {
    return SizedBox(
      width: 200,
      child: DropdownButtonFormField<String>(
        value: _statusFilter,
        decoration: const InputDecoration(
          labelText: 'Status',
          border: OutlineInputBorder(),
        ),
        items: [
          const DropdownMenuItem(value: null, child: Text('All')),
          ...LeadStatusConstants.statusList
              .map((s) => DropdownMenuItem(value: s, child: Text(s))),
        ],
        onChanged: (value) => setState(() => _statusFilter = value),
      ),
    );
  }

  Widget _buildSourceFilter() {
    return SizedBox(
      width: 200,
      child: DropdownButtonFormField<String>(
        value: _sourceFilter,
        decoration: const InputDecoration(
          labelText: 'Source',
          border: OutlineInputBorder(),
        ),
        items: [
          const DropdownMenuItem(value: null, child: Text('All')),
          ...LeadSource.values.map(
            (s) => DropdownMenuItem(
              value: s.name,
              child: Text(s.displayName),
            ),
          ),
        ],
        onChanged: (value) => setState(() => _sourceFilter = value),
      ),
    );
  }

  Widget _buildPriorityFilter() {
    return SizedBox(
      width: 200,
      child: DropdownButtonFormField<String>(
        value: _priorityFilter,
        decoration: const InputDecoration(
          labelText: 'Priority',
          border: OutlineInputBorder(),
        ),
        items: [
          const DropdownMenuItem(value: null, child: Text('All')),
          ...PriorityConstants.priorities
              .map((p) => DropdownMenuItem(value: p, child: Text(p))),
        ],
        onChanged: (value) => setState(() => _priorityFilter = value),
      ),
    );
  }

  Widget _buildCustomerTypeFilter() {
    return SizedBox(
      width: 200,
      child: DropdownButtonFormField<String>(
        value: _customerTypeFilter,
        decoration: const InputDecoration(
          labelText: 'Customer Type',
          border: OutlineInputBorder(),
        ),
        items: [
          const DropdownMenuItem(value: null, child: Text('All')),
          ...CustomerTypeConstants.types
              .map((t) => DropdownMenuItem(value: t, child: Text(t))),
        ],
        onChanged: (value) => setState(() => _customerTypeFilter = value),
      ),
    );
  }

  Widget _buildProjectTypeFilter() {
    return SizedBox(
      width: 200,
      child: DropdownButtonFormField<String>(
        value: _projectTypeFilter,
        decoration: const InputDecoration(
          labelText: 'Project Type',
          border: OutlineInputBorder(),
        ),
        items: [
          const DropdownMenuItem(value: null, child: Text('All')),
          ...ProjectTypeConstants.types
              .map((t) => DropdownMenuItem(value: t, child: Text(t))),
        ],
        onChanged: (value) => setState(() => _projectTypeFilter = value),
      ),
    );
  }

  Widget _buildDateRangeFilter(BuildContext context) {
    return SizedBox(
      width: 250,
      child: OutlinedButton.icon(
        icon: const Icon(Icons.date_range),
        label: Text(
          _dateRange != null
              ? '${_dateRange!.start.toString().split(' ')[0]} - ${_dateRange!.end.toString().split(' ')[0]}'
              : 'Select Date Range',
        ),
        onPressed: () async {
          final picked = await showDateRangePicker(
            context: context,
            firstDate: DateTime(2020),
            lastDate: DateTime.now(),
            initialDateRange: _dateRange,
          );
          if (picked != null) {
            setState(() => _dateRange = picked);
          }
        },
      ),
    );
  }

  Widget _buildActiveFiltersChips(BuildContext context) {
    final provider = context.watch<LeadProvider>();

    if (!provider.hasActiveFilters) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Wrap(
        spacing: 8,
        children: [
          if (provider.searchQuery.isNotEmpty)
            Chip(
              label: Text('Search: ${provider.searchQuery}'),
              onDeleted: () => context.read<LeadProvider>().clearSearch(),
            ),
          if (provider.hasFilter('status'))
            Chip(
              label: Text('Status: ${provider.getFilter('status')}'),
              onDeleted: () =>
                  context.read<LeadProvider>().filterByStatus(null),
            ),
          if (provider.hasFilter('source'))
            Chip(
              label: Text('Source: ${provider.getFilter('source')}'),
              onDeleted: () =>
                  context.read<LeadProvider>().filterBySource(null),
            ),
          if (provider.hasFilter('priority'))
            Chip(
              label: Text('Priority: ${provider.getFilter('priority')}'),
              onDeleted: () =>
                  context.read<LeadProvider>().filterByPriority(null),
            ),
          if (provider.activeFiltersCount > 1)
            TextButton(
              onPressed: () => context.read<LeadProvider>().clearAll(),
              child: const Text('Clear All'),
            ),
        ],
      ),
    );
  }

  Widget _buildLeadsList(BuildContext context) {
    return Consumer<LeadProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading && !provider.hasData) {
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
                  onPressed: () => provider.refresh(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (provider.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.inbox_outlined, size: 48, color: Colors.grey),
                const SizedBox(height: 16),
                const Text('No leads found'),
                if (provider.hasActiveFilters) ...[
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => provider.clearAll(),
                    child: const Text('Clear filters'),
                  ),
                ],
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: provider.items.length + (provider.isLoading ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == provider.items.length) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                ),
              );
            }

            final lead = provider.items[index];
            return _buildLeadCard(context, lead);
          },
        );
      },
    );
  }

  Widget _buildLeadCard(BuildContext context, Lead lead) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () => _navigateToEditLead(context, lead),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      lead.firstName ?? 'Unnamed Lead',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  _buildStatusChip(lead.status),
                ],
              ),
              const SizedBox(height: 8),
              if (lead.companyName != null)
                Text('Company: ${lead.companyName}'),
              if (lead.email != null) Text('Email: ${lead.email}'),
              if (lead.phone != null) Text('Phone: ${lead.phone}'),
              const SizedBox(height: 8),
              Row(
                children: [
                  if (lead.source != null) ...[
                    Icon(Icons.source, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(lead.source!,
                        style: TextStyle(color: Colors.grey[600])),
                    const SizedBox(width: 16),
                  ],
                  if (lead.priority != null) ...[
                    Icon(Icons.priority_high,
                        size: 16, color: _getPriorityColor(lead.priority)),
                    const SizedBox(width: 4),
                    Text(lead.priority!,
                        style:
                            TextStyle(color: _getPriorityColor(lead.priority))),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String? status) {
    if (status == null) return const SizedBox.shrink();

    return Chip(
      label: Text(
        status,
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
      backgroundColor: _getStatusColor(status),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'NEW':
        return Colors.blue;
      case 'CONTACTED':
        return Colors.orange;
      case 'QUALIFIED':
        return Colors.purple;
      case 'PROPOSAL_SENT':
        return Colors.teal;
      case 'NEGOTIATION':
        return Colors.amber;
      case 'WON':
        return Colors.green;
      case 'LOST':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _getPriorityColor(String? priority) {
    switch (priority?.toUpperCase()) {
      case 'HIGH':
        return Colors.red;
      case 'MEDIUM':
        return Colors.orange;
      case 'LOW':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Widget _buildPaginationControls(BuildContext context) {
    return Consumer<LeadProvider>(
      builder: (context, provider, _) {
        return Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Showing ${provider.items.length} of ${provider.totalElements} leads',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.first_page),
                    onPressed: provider.hasPrevious && !provider.isLoading
                        ? () => provider.firstPage()
                        : null,
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: provider.hasPrevious && !provider.isLoading
                        ? () => provider.previousPage()
                        : null,
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Page ${provider.currentPage + 1} of ${provider.totalPages}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: provider.hasNext && !provider.isLoading
                        ? () => provider.nextPage()
                        : null,
                  ),
                  IconButton(
                    icon: const Icon(Icons.last_page),
                    onPressed: provider.hasNext && !provider.isLoading
                        ? () => provider.lastPage()
                        : null,
                  ),
                  const SizedBox(width: 16),
                  DropdownButton<int>(
                    value: provider.pageSize,
                    items: [10, 20, 50, 100].map((size) {
                      return DropdownMenuItem(
                        value: size,
                        child: Text('$size per page'),
                      );
                    }).toList(),
                    onChanged: provider.isLoading
                        ? null
                        : (value) {
                            if (value != null) {
                              provider.changePageSize(value);
                            }
                          },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _applyFilters(BuildContext context) {
    final provider = context.read<LeadProvider>();

    provider.applyAllFilters(
      status: _statusFilter,
      source: _sourceFilter,
      priority: _priorityFilter,
      customerType: _customerTypeFilter,
      projectType: _projectTypeFilter,
      startDate: _dateRange?.start,
      endDate: _dateRange?.end,
    );

    setState(() => _showFilters = false);
  }

  void _clearAllFilters(BuildContext context) {
    setState(() {
      _statusFilter = null;
      _sourceFilter = null;
      _priorityFilter = null;
      _customerTypeFilter = null;
      _projectTypeFilter = null;
      _dateRange = null;
    });
    context.read<LeadProvider>().clearAll();
  }

  void _navigateToAddLead(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddLeadScreen()),
    ).then((_) => context.read<LeadProvider>().refresh());
  }

  void _navigateToEditLead(BuildContext context, Lead lead) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditLeadScreen(leadId: lead.id.toString()),
      ),
    ).then((_) => context.read<LeadProvider>().refresh());
  }
}
