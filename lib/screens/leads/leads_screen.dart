import 'package:flutter/material.dart';
import '../../../constants.dart';
import '../../../models/lead.dart';
import '../../../models/team_member_simple.dart';
import '../../../models/pagination_params.dart';
import '../../../responsive.dart';
import '../../../services/crm_service.dart';
import '../../../constants/lead_status_constants.dart';
import '../../../constants/lead_source_constants.dart';
import '../../../constants/priority_constants.dart';
import '../../../constants/customer_type_constants.dart';
import '../../../constants/project_type_constants.dart';
import '../../../utils/container_styles.dart';
import 'add_lead_screen.dart';
import 'edit_lead_screen.dart';

class LeadsScreen extends StatefulWidget {
  const LeadsScreen({super.key});

  @override
  State<LeadsScreen> createState() => _LeadsScreenState();
}

class _LeadsScreenState extends State<LeadsScreen> {
  String statusFilter = LeadStatusConstants.defaultValue;
  LeadSource? sourceFilter;
  DateTimeRange? dateRangeFilter;
  String? projectTypeFilter;
  String? salesRepFilter;
  String? priorityFilter;
  String? customerTypeFilter;
  String? stateFilter;
  String? districtFilter;
  double? minBudgetFilter;
  double? maxBudgetFilter;

  // Pagination state
  List<Lead> leads = [];
  int currentPage = 1;
  int totalPages = 1;
  int totalItems = 0;
  int itemsPerPage = 10;
  bool hasNextPage = false;
  bool hasPreviousPage = false;
  bool isLoading = true;
  bool isLoadingMore = false;
  String? errorMessage;
  final CRMService _crmService = CRMService();
  final ScrollController _scrollController = ScrollController();
  List<TeamMemberSimple> teamMembers = [];

  PaginationParams get _paginationParams {
    return PaginationParams(
      page: currentPage,
      limit: itemsPerPage,
      status: statusFilter == 'All' ? null : statusFilter,
      source:
          sourceFilter != null ? Lead.getSourceApiValue(sourceFilter!) : null,
      priority: priorityFilter,
      customerType: customerTypeFilter,
      projectType: projectTypeFilter,
      assignedTeam: salesRepFilter,
      state: stateFilter,
      district: districtFilter,
      minBudget: minBudgetFilter,
      maxBudget: maxBudgetFilter,
      startDate: dateRangeFilter?.start,
      endDate: dateRangeFilter?.end,
      sortBy: 'created_at',
      sortOrder: 'desc',
    );
  }

  @override
  void initState() {
    super.initState();
    _loadLeads();
    _loadTeamMembers();
    _scrollController.addListener(_onScroll);
  }

  Future<void> _loadTeamMembers() async {
    try {
      final members = await _crmService.getTeamMembersForAssignment();
      if (mounted) {
        setState(() {
          teamMembers = members;
        });
      }
    } catch (e) {
      print('Error loading team members for filter: $e');
      // Continue without team members - dropdown will still work with existing logic
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (hasNextPage && !isLoadingMore) {
        _loadMoreLeads();
      }
    }
  }

  Future<void> _loadLeads({bool resetPage = true}) async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
        if (resetPage) {
          currentPage = 1;
          leads.clear();
        }
      });

      final response = await _crmService.getLeadsPaginated(_paginationParams);

      if (mounted) {
        setState(() {
          if (resetPage) {
            leads = response.data;
          } else {
            // For refresh (resetPage: false), replace the current page data
            leads.clear();
            leads.addAll(response.data);
          }
          currentPage = response.currentPage;
          totalPages = response.totalPages;
          totalItems = response.totalItems;
          itemsPerPage = response.itemsPerPage;
          hasNextPage = response.hasNextPage;
          hasPreviousPage = response.hasPreviousPage;
          isLoading = false;
          isLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
          isLoadingMore = false;
          errorMessage = _getErrorMessage(e);
          // Revert page increment on error
          if (!resetPage) {
            currentPage--;
          }
        });
      }
    }
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
      return 'Failed to load leads. Please try again.';
    }
  }

  Future<void> _loadMoreLeads() async {
    if (hasNextPage && !isLoadingMore) {
      setState(() {
        isLoadingMore = true;
      });

      // Load next page
      setState(() {
        currentPage++;
      });

      try {
        final response = await _crmService.getLeadsPaginated(_paginationParams);

        if (mounted) {
          setState(() {
            leads.addAll(response.data);
            totalPages = response.totalPages;
            totalItems = response.totalItems;
            itemsPerPage = response.itemsPerPage;
            hasNextPage = response.hasNextPage;
            hasPreviousPage = response.hasPreviousPage;
            isLoadingMore = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            isLoadingMore = false;
            errorMessage = _getErrorMessage(e);
            // Revert page increment on error
            currentPage--;
          });
        }
      }
    }
  }

  Future<void> _refreshLeads() async {
    await _loadLeads(resetPage: true);
  }

  void _onFilterChanged() {
    _loadLeads(resetPage: true);
  }

  void _clearAllFilters() {
    setState(() {
      statusFilter = LeadStatusConstants.defaultValue;
      sourceFilter = null;
      projectTypeFilter = null;
      salesRepFilter = null;
      priorityFilter = null;
      customerTypeFilter = null;
      stateFilter = null;
      districtFilter = null;
      minBudgetFilter = null;
      maxBudgetFilter = null;
      dateRangeFilter = null;
    });
    _loadLeads(resetPage: true);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(defaultPadding),
        child: Column(
          children: [
            Responsive.isMobile(context)
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            "Leads",
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ],
                      ),
                      const SizedBox(height: defaultPadding),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: defaultPadding,
                                ),
                              ),
                              onPressed: _clearAllFilters,
                              icon: const Icon(Icons.clear_all, size: 18),
                              label: const Text("Clear"),
                            ),
                          ),
                          const SizedBox(width: defaultPadding / 2),
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: defaultPadding,
                                ),
                              ),
                              onPressed: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          const AddLeadScreen()),
                                );
                                if (result == true) {
                                  _loadLeads();
                                }
                              },
                              icon: const Icon(Icons.add, size: 18),
                              label: const Text("Add Lead"),
                            ),
                          ),
                        ],
                      ),
                    ],
                  )
                : Row(
                    children: [
                      if (!Responsive.isDesktop(context))
                        IconButton(
                          icon: const Icon(Icons.menu),
                          onPressed: () {},
                        ),
                      Text(
                        "Leads",
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const Spacer(),
                      OutlinedButton.icon(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: defaultPadding * 1.5,
                            vertical: defaultPadding,
                          ),
                        ),
                        onPressed: _clearAllFilters,
                        icon: const Icon(Icons.clear_all),
                        label: const Text("Clear Filters"),
                      ),
                      const SizedBox(width: defaultPadding),
                      ElevatedButton.icon(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: defaultPadding * 1.5,
                            vertical: defaultPadding,
                          ),
                        ),
                        onPressed: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const AddLeadScreen()),
                          );

                          // Refresh the list if a new lead was added
                          if (result == true) {
                            _loadLeads();
                          }
                        },
                        icon: const Icon(Icons.add),
                        label: const Text("Add New Lead"),
                      ),
                    ],
                  ),
            const SizedBox(height: defaultPadding),
            // Responsive filter section
            Responsive(
              mobile: Column(
                children: [
                  _buildFilterRow1(context),
                  const SizedBox(height: 8),
                  _buildFilterRow2(context),
                  const SizedBox(height: 8),
                  _buildFilterRow3(context),
                ],
              ),
              tablet: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _buildAllFilters(context),
              ),
              desktop: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _buildAllFilters(context),
              ),
            ),
            const SizedBox(height: defaultPadding),
            if (isLoading)
              const Center(child: CircularProgressIndicator())
            else if (errorMessage != null)
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red.withOpacity(0.7),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      errorMessage!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.red.shade700,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _loadLeads,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 16),
                        OutlinedButton.icon(
                          onPressed: _clearAllFilters,
                          icon: const Icon(Icons.clear_all),
                          label: const Text('Clear Filters'),
                        ),
                      ],
                    ),
                  ],
                ),
              )
            else
              Column(
                children: [
                  // Lead Summary Cards
                  Responsive(
                    mobile: Column(
                      children: [
                        LeadsSummaryCard(
                          totalLeads: totalItems,
                          leadsBySource: _getLeadsBySource(),
                        ),
                        const SizedBox(height: defaultPadding),
                        RefreshIndicator(
                          onRefresh: _refreshLeads,
                          child: Column(
                            children: [
                              LeadsTable(
                                leads: leads,
                                onEdit: _editLead,
                                onDelete: _deleteLead,
                              ),
                              if (isLoadingMore)
                                const Padding(
                                  padding: EdgeInsets.all(defaultPadding),
                                  child: CircularProgressIndicator(),
                                ),
                              _buildPaginationIndicator(),
                            ],
                          ),
                        ),
                      ],
                    ),
                    tablet: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 1,
                          child: LeadsSummaryCard(
                            totalLeads: totalItems,
                            leadsBySource: _getLeadsBySource(),
                          ),
                        ),
                        const SizedBox(width: defaultPadding),
                        Expanded(
                          flex: 2,
                          child: RefreshIndicator(
                            onRefresh: _refreshLeads,
                            child: Column(
                              children: [
                                LeadsTable(
                                  leads: leads,
                                  onEdit: _editLead,
                                  onDelete: _deleteLead,
                                ),
                                if (isLoadingMore)
                                  const Padding(
                                    padding: EdgeInsets.all(defaultPadding),
                                    child: CircularProgressIndicator(),
                                  ),
                                _buildPaginationIndicator(),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    desktop: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 1,
                          child: LeadsSummaryCard(
                            totalLeads: totalItems,
                            leadsBySource: _getLeadsBySource(),
                          ),
                        ),
                        const SizedBox(width: defaultPadding),
                        Expanded(
                          flex: 3,
                          child: RefreshIndicator(
                            onRefresh: _refreshLeads,
                            child: Column(
                              children: [
                                LeadsTable(
                                  leads: leads,
                                  onEdit: _editLead,
                                  onDelete: _deleteLead,
                                ),
                                if (isLoadingMore)
                                  const Padding(
                                    padding: EdgeInsets.all(defaultPadding),
                                    child: CircularProgressIndicator(),
                                  ),
                                _buildPaginationIndicator(),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterRow1(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: DropdownButton<String>(
            value: statusFilter,
            isExpanded: true,
            items: LeadStatusConstants.searchDropdownItems,
            onChanged: (val) {
              setState(
                  () => statusFilter = val ?? LeadStatusConstants.defaultValue);
              _onFilterChanged();
            },
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: DropdownButton<LeadSource?>(
            value: sourceFilter,
            isExpanded: true,
            hint: const Text('Source'),
            items: LeadSourceConstants.searchDropdownItems,
            onChanged: (val) {
              setState(() => sourceFilter = val);
              _onFilterChanged();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFilterRow2(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: DropdownButton<String>(
            value: projectTypeFilter,
            isExpanded: true,
            hint: const Text('Project Type'),
            items: ProjectTypeConstants.searchDropdownItems,
            onChanged: (val) {
              setState(() => projectTypeFilter = val);
              _onFilterChanged();
            },
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: DropdownButton<String>(
            value: salesRepFilter,
            isExpanded: true,
            hint: const Text('Team Member'),
            items: [
              const DropdownMenuItem(
                  value: null, child: Text('All Team Members')),
              ...teamMembers.map((member) => DropdownMenuItem<String>(
                    value: member.id.toString(),
                    child: Text(member.fullName),
                  ))
            ],
            onChanged: (val) {
              setState(() => salesRepFilter = val);
              _onFilterChanged();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFilterRow3(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: DropdownButton<String>(
            value: priorityFilter,
            isExpanded: true,
            hint: const Text('Priority'),
            items: [
              const DropdownMenuItem(
                  value: null, child: Text('All Priorities')),
              ...LeadPriority.values.map((p) => DropdownMenuItem<String>(
                    value: p.toString().split('.').last,
                    child: Text(PriorityConstants.getLabel(p)),
                  ))
            ],
            onChanged: (val) {
              setState(() => priorityFilter = val);
              _onFilterChanged();
            },
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    final picked = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      setState(() => dateRangeFilter = picked);
                      _onFilterChanged();
                    }
                  },
                  child: Text(
                    dateRangeFilter == null
                        ? 'Select Date Range'
                        : '${dateRangeFilter!.start.toString().substring(0, 10)} - ${dateRangeFilter!.end.toString().substring(0, 10)}',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              if (dateRangeFilter != null)
                IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    setState(() => dateRangeFilter = null);
                    _onFilterChanged();
                  },
                ),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _buildAllFilters(BuildContext context) {
    return [
      DropdownButton<String>(
        value: statusFilter,
        items: LeadStatusConstants.searchDropdownItems,
        onChanged: (val) {
          setState(
              () => statusFilter = val ?? LeadStatusConstants.defaultValue);
          _onFilterChanged();
        },
      ),
      DropdownButton<LeadSource?>(
        value: sourceFilter,
        hint: const Text('Source'),
        items: LeadSourceConstants.searchDropdownItems,
        onChanged: (val) {
          setState(() => sourceFilter = val);
          _onFilterChanged();
        },
      ),
      DropdownButton<String>(
        value: projectTypeFilter,
        hint: const Text('Project Type'),
        items: ProjectTypeConstants.searchDropdownItems,
        onChanged: (val) {
          setState(() => projectTypeFilter = val);
          _onFilterChanged();
        },
      ),
      DropdownButton<String>(
        value: salesRepFilter,
        hint: const Text('Team Member'),
        items: [
          const DropdownMenuItem(value: null, child: Text('All Team Members')),
          ...teamMembers.map((member) => DropdownMenuItem<String>(
                value: member.id.toString(),
                child: Text(member.fullName),
              ))
        ],
        onChanged: (val) {
          setState(() => salesRepFilter = val);
          _onFilterChanged();
        },
      ),
      DropdownButton<String>(
        value: priorityFilter,
        hint: const Text('Priority'),
        items: [
          const DropdownMenuItem(value: null, child: Text('All Priorities')),
          ...LeadPriority.values.map((p) => DropdownMenuItem<String>(
                value: p.toString().split('.').last,
                child: Text(PriorityConstants.getLabel(p)),
              ))
        ],
        onChanged: (val) {
          setState(() => priorityFilter = val);
          _onFilterChanged();
        },
      ),
      DropdownButton<String>(
        value: customerTypeFilter,
        hint: const Text('Customer Type'),
        items: [
          const DropdownMenuItem(value: null, child: Text('All Types')),
          ...CustomerTypeConstants.dropdownItems
        ],
        onChanged: (val) {
          setState(() => customerTypeFilter = val);
          _onFilterChanged();
        },
      ),
      ElevatedButton(
        onPressed: () async {
          final picked = await showDateRangePicker(
            context: context,
            firstDate: DateTime(2020),
            lastDate: DateTime.now().add(const Duration(days: 365)),
          );
          if (picked != null) {
            setState(() => dateRangeFilter = picked);
            _onFilterChanged();
          }
        },
        child: Text(dateRangeFilter == null
            ? 'Select Date Range'
            : '${dateRangeFilter!.start.toString().substring(0, 10)} - ${dateRangeFilter!.end.toString().substring(0, 10)}'),
      ),
      if (dateRangeFilter != null)
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () {
            setState(() => dateRangeFilter = null);
            _onFilterChanged();
          },
        ),
    ];
  }

  Future<void> _editLead(Lead lead) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditLeadScreen(lead: lead),
      ),
    );

    // Refresh the current page if the lead was updated
    if (result == true) {
      await _refreshCurrentPage();
    }
  }

  Future<void> _refreshCurrentPage() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      final response = await _crmService.getLeadsPaginated(_paginationParams);

      if (mounted) {
        setState(() {
          leads.clear();
          leads.addAll(response.data);
          totalPages = response.totalPages;
          totalItems = response.totalItems;
          itemsPerPage = response.itemsPerPage;
          hasNextPage = response.hasNextPage;
          hasPreviousPage = response.hasPreviousPage;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
          errorMessage = _getErrorMessage(e);
        });
      }
    }
  }

  Future<void> _deleteLead(Lead lead) async {
    // Confirmation dialog is already shown in LeadsTable._showDeleteConfirmation
    // This method is called after user confirms deletion
    try {
      await _crmService.deleteLead(lead.leadId);
      setState(() {
        leads.removeWhere((item) => item.leadId == lead.leadId);
        // Update total count
        if (totalItems > 0) {
          totalItems--;
        }
        // Recalculate total pages
        if (totalItems > 0) {
          totalPages = ((totalItems - 1) / itemsPerPage).ceil();
        } else {
          totalPages = 0;
        }
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lead deleted successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting lead: $e')),
        );
      }
    }
  }

  Map<String, int> _getLeadsBySource() {
    final sourceCounts = <String, int>{};
    for (final lead in leads) {
      final sourceName = LeadSourceConstants.getSourceName(lead.source);
      sourceCounts.update(sourceName, (value) => value + 1, ifAbsent: () => 1);
    }
    return sourceCounts;
  }

  Widget _buildPaginationIndicator() {
    return Container(
      padding: const EdgeInsets.all(defaultPadding),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Showing ${leads.length} of $totalItems leads',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          Row(
            children: [
              if (hasPreviousPage)
                IconButton(
                  onPressed: () {
                    setState(() => currentPage--);
                    _loadLeads(resetPage: true);
                  },
                  icon: const Icon(Icons.chevron_left),
                ),
              Text('Page $currentPage of $totalPages'),
              if (hasNextPage)
                IconButton(
                  onPressed: () {
                    setState(() => currentPage++);
                    _loadLeads(resetPage: true);
                  },
                  icon: const Icon(Icons.chevron_right),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class LeadsTable extends StatelessWidget {
  final List<Lead> leads;
  final Function(Lead) onEdit;
  final Function(Lead) onDelete;

  const LeadsTable({
    super.key,
    required this.leads,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(defaultPadding),
      decoration: ContainerStyles.secondaryBox,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: defaultPadding,
          columns: const [
            DataColumn(label: Text("Name")),
            DataColumn(label: Text("Contact")),
            DataColumn(label: Text("Status")),
            DataColumn(label: Text("Priority")),
            DataColumn(label: Text("Project")),
            DataColumn(label: Text("Budget")),
            DataColumn(label: Text("Sales Rep")),
            DataColumn(label: Text("Next Follow-up")),
            DataColumn(label: Text("Actions")),
          ],
          rows: leads.map((lead) {
            return DataRow(
              cells: [
                // Name Column
                DataCell(
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 150),
                    child: Tooltip(
                      message: lead.name,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            lead.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          // company field removed
                        ],
                      ),
                    ),
                  ),
                  onTap: () => onEdit(lead),
                ),

                // Contact Column
                DataCell(
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 180),
                    child: Tooltip(
                      message: '${lead.phone}\n${lead.email}',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            lead.phone,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (lead.email.isNotEmpty)
                            Text(
                              lead.email,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[400],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Status Column
                DataCell(
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(lead.status),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      lead.status,
                      style: const TextStyle(
                        color: textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                // Priority Column
                DataCell(
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getPriorityColor(lead.priority),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      lead.priorityString,
                      style: const TextStyle(
                        color: textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                // Project Column
                DataCell(
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 120),
                    child: Tooltip(
                      message: '${lead.projectType}\n${lead.customerType}',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            lead.projectType.isNotEmpty
                                ? lead.projectType
                                : 'N/A',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          // projectStage field removed
                        ],
                      ),
                    ),
                  ),
                ),

                // Budget Column
                DataCell(
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 100),
                    child: Tooltip(
                      message: lead.budget != null
                          ? '₹${lead.budget!.toStringAsFixed(0)}'
                          : 'N/A',
                      child: Text(
                        lead.budget != null
                            ? '₹${lead.budget!.toStringAsFixed(0)}'
                            : 'N/A',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color:
                              lead.budget != null ? Colors.green : Colors.grey,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),

                // Sales Rep Column
                DataCell(
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 100),
                    child: Tooltip(
                      message: lead.assignedTeam.isNotEmpty
                          ? lead.assignedTeam
                          : 'Unassigned',
                      child: Text(
                        lead.assignedTeam.isNotEmpty
                            ? lead.assignedTeam
                            : 'Unassigned',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),

                // Next Follow-up Column
                DataCell(
                  Tooltip(
                    message: lead.nextFollowUp?.toString() ??
                        'No follow-up scheduled',
                    child: Text(
                      lead.nextFollowUp != null
                          ? _formatDate(lead.nextFollowUp!)
                          : 'N/A',
                      style: TextStyle(
                        color: lead.nextFollowUp != null &&
                                lead.nextFollowUp!.isBefore(DateTime.now())
                            ? Colors.red
                            : null,
                        fontWeight: lead.nextFollowUp != null &&
                                lead.nextFollowUp!.isBefore(DateTime.now())
                            ? FontWeight.bold
                            : null,
                      ),
                    ),
                  ),
                ),

                // Actions Column
                DataCell(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit,
                            color: Colors.blue, size: 20),
                        tooltip: 'Edit Lead',
                        onPressed: () => onEdit(lead),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete,
                            color: Colors.red, size: 20),
                        tooltip: 'Delete Lead',
                        onPressed: () => _showDeleteConfirmation(context, lead),
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

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'new_inquiry':
        return Colors.blue;
      case 'contacted':
        return Colors.orange;
      case 'qualified_lead':
        return Colors.purple;
      case 'proposal_sent':
        return Colors.indigo;
      case 'negotiation':
        return Colors.deepOrange;
      case 'project_won':
        return Colors.green;
      case 'lost':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _getPriorityColor(LeadPriority priority) {
    switch (priority) {
      case LeadPriority.high:
        return Colors.red;
      case LeadPriority.medium:
        return Colors.orange;
      case LeadPriority.low:
        return Colors.green;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now).inDays;

    if (difference < 0) {
      return 'Overdue';
    } else if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Tomorrow';
    } else if (difference < 7) {
      return '${difference}d';
    } else {
      return '${date.day}/${date.month}';
    }
  }

  void _showDeleteConfirmation(BuildContext context, Lead lead) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Lead'),
          content: Text(
              'Are you sure you want to delete "${lead.name}"? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onDelete(lead);
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }
}

class LeadsSummaryCard extends StatelessWidget {
  final int totalLeads;
  final Map<String, int> leadsBySource;

  const LeadsSummaryCard({
    super.key,
    required this.totalLeads,
    required this.leadsBySource,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(defaultPadding),
      decoration: ContainerStyles.successBox,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Leads Summary",
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: defaultPadding),
          Chart(totalLeads: totalLeads),
          const SizedBox(height: defaultPadding),
          ...leadsBySource.entries.map((entry) {
            Color color;
            switch (entry.key) {
              case 'Website':
                color = Colors.blue;
                break;
              case 'Google Business Profile':
                color = Colors.red;
                break;
              case 'Referral (Client)':
                color = Colors.green;
                break;
              case 'Referral (Architect/Designer/Other)':
                color = Colors.purple;
                break;
              case 'Social Media (Facebook/Instagram)':
                color = Colors.pink;
                break;
              case 'WhatsApp Business':
                color = Colors.teal;
                break;
              case 'Online Ads (PPC)':
                color = Colors.orange;
                break;
              case 'Direct Walk-in':
                color = Colors.brown;
                break;
              case 'Event/Trade Show':
                color = Colors.indigo;
                break;
              case 'Print Advertising':
                color = Colors.amber;
                break;
              default:
                color = Colors.grey;
            }
            return LeadSourceInfo(
              title: entry.key,
              numOfLeads: entry.value,
              color: color,
            );
          }).toList(),
        ],
      ),
    );
  }
}

class LeadSourceInfo extends StatelessWidget {
  const LeadSourceInfo({
    super.key,
    required this.title,
    required this.numOfLeads,
    required this.color,
  });

  final String title;
  final int numOfLeads;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: defaultPadding / 2),
      padding: const EdgeInsets.all(defaultPadding / 2),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: defaultPadding),
          Expanded(child: Text(title)),
          Text("$numOfLeads"),
        ],
      ),
    );
  }
}

class Chart extends StatelessWidget {
  final int totalLeads;

  const Chart({super.key, required this.totalLeads});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: Stack(
        children: [
          Center(
            child: Text(
              "$totalLeads\nTotal Leads",
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          // TODO: Add a proper chart widget here (e.g., using fl_chart package)
        ],
      ),
    );
  }
}
