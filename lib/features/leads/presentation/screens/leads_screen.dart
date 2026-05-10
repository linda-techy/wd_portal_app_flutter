import 'package:flutter/material.dart';
import 'package:admin/constants.dart';
import 'package:admin/features/leads/data/models/lead.dart';
import 'package:admin/models/portal_user.dart';
import 'package:admin/services/user_service.dart';
import 'package:admin/models/pagination_params.dart';
import 'package:admin/responsive.dart';
import 'package:admin/features/leads/data/services/lead_service.dart';
import 'package:admin/constants/lead_status_constants.dart';
import 'package:admin/constants/lead_source_constants.dart';
import 'package:admin/constants/priority_constants.dart';
import 'package:admin/constants/customer_type_constants.dart';
import 'package:admin/constants/project_type_constants.dart';
import 'package:admin/utils/container_styles.dart';
import 'package:admin/providers/permission_provider.dart';
import 'package:provider/provider.dart';
import 'package:admin/providers/portal_auth_provider.dart';
import 'package:admin/utils/error_handler.dart';
import 'package:admin/utils/motion_toast.dart';
import 'package:admin/features/scheduling/presentation/dialogs/wbs_template_picker_flow.dart';
import 'package:admin/utils/file_download_helper.dart';
import 'package:admin/config/app_config.dart';
import 'package:admin/utils/debouncer.dart';
import 'package:admin/widgets/error_state_widget.dart';
import 'add_lead_screen.dart';
import 'edit_lead_screen.dart';
import 'lead_quotations_screen.dart';
import 'lead_tasks_screen.dart';
import 'lead_activity_screen.dart';
import 'lead_documents_screen.dart';
import 'lead_interactions_screen.dart';
import 'lead_score_history_screen.dart';
// import 'lead_table.dart'; // Removed to avoid conflict with local LeadsTable class
import 'components/add_interaction_dialog.dart';
// import 'components/leads_summary_card.dart';

class LeadsScreen extends StatefulWidget {
  const LeadsScreen({super.key});

  @override
  State<LeadsScreen> createState() => _LeadsScreenState();
}

class _LeadsScreenState extends State<LeadsScreen> {
  String statusFilter = 'All';
  String? searchQuery;
  final TextEditingController _searchController = TextEditingController();
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
  bool _isPageLoading = true;
  bool isLoadingMore = false;
  String? errorMessage;
  final LeadService _leadService = LeadService();
  final ScrollController _scrollController = ScrollController();
  final Debouncer _debouncer = Debouncer();
  List<PortalUser> teamMembers = [];

  PaginationParams get _paginationParams {
    return PaginationParams(
      page: currentPage,
      limit: itemsPerPage,
      search: searchQuery?.isNotEmpty == true ? searchQuery : null,
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
    _verifyAuthAndLoadData();
    _loadTeamMembers();
    _scrollController.addListener(_onScroll);
  }

  Future<void> _verifyAuthAndLoadData() async {
    final authProvider =
        Provider.of<PortalAuthProvider>(context, listen: false);
    if (!authProvider.isAuthenticated) {
      if (mounted) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            Navigator.of(context).pushReplacementNamed('/login');
          }
        });
      }
      return;
    }
    await _loadLeads();
  }

  Future<void> _loadTeamMembers() async {
    try {
      final members = await UserService.getAllPortalUsers();
      if (mounted) {
        setState(() {
          teamMembers = members;
        });
      }
    } catch (e) {
      // Silent failure for filters is acceptable, or log it
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _debouncer.dispose();
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
        _isPageLoading = true;
        errorMessage = null;
        if (resetPage) {
          currentPage = 1;
          leads.clear();
        }
      });

      final response = await _leadService.getLeadsPaginated(_paginationParams);

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
          _isPageLoading = false;
          isLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isPageLoading = false;
          isLoadingMore = false;
          // Revert page increment on error if needed, but for load it's fine
        });
        await ErrorHandler.handleApiError(context, e,
            defaultMessage: 'Failed to load leads');
        setState(() => errorMessage = ErrorHandler.getErrorMessage(e));
      }
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
        final response =
            await _leadService.getLeadsPaginated(_paginationParams);

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
            // Revert page increment on error
            currentPage--;
          });
          await ErrorHandler.handleApiError(context, e,
              defaultMessage: 'Failed to load more leads', showToast: true);
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
      statusFilter = 'All';
      searchQuery = null;
      _searchController.clear();
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

  Future<void> _exportToExcel() async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const Center(child: CircularProgressIndicator()),
      );

      // Prepare filter parameters
      final bytes = await _leadService.exportLeadsToExcel(
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
      );

      // Close loading dialog
      if (mounted) {
        Navigator.of(context).pop();
      }

      // Download and share file using cross-platform helper
      final timestamp =
          DateTime.now().toIso8601String().replaceAll(':', '-').split('.')[0];
      final filename = 'Leads_Export_$timestamp.xlsx';

      if (mounted) {
        await FileDownloadHelper.downloadAndShareFile(
          bytes: bytes,
          fileName: filename,
          mimeType:
              'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
          shareText:
              'Leads Export - ${DateTime.now().toString().split('.')[0]}',
        );
      }
      if (mounted) {
        MotionToast.showSuccess(context,
            message: 'Excel file exported successfully');
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog if still open
        await ErrorHandler.handleApiError(
          context,
          e,
          defaultMessage: 'Failed to export leads to Excel',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final permissions = Provider.of<PermissionProvider>(context);

    return SafeArea(
      child: _isPageLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
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
                          // Export to Excel button
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: defaultPadding,
                                ),
                              ),
                              onPressed: _exportToExcel,
                              icon: const Icon(Icons.file_download,
                                  size: 18, color: Colors.green),
                              label: const Text("Export Excel",
                                  style: TextStyle(color: Colors.green)),
                            ),
                          ),
                          const SizedBox(width: defaultPadding / 2),
                          // Add Lead button - Only show if user has CREATE permission
                          if (permissions.canCreateLead)
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
                      // Export to Excel button
                      OutlinedButton.icon(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: defaultPadding * 1.5,
                            vertical: defaultPadding,
                          ),
                        ),
                        onPressed: _exportToExcel,
                        icon: const Icon(Icons.file_download,
                            color: Colors.green),
                        label: const Text("Export Excel",
                            style: TextStyle(color: Colors.green)),
                      ),
                      const SizedBox(width: defaultPadding),
                      // Add Lead button - Only show if user has CREATE permission
                      if (permissions.canCreateLead)
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
            // Search bar
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name, phone, email...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: searchQuery?.isNotEmpty == true
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            searchQuery = null;
                            _searchController.clear();
                          });
                          _onFilterChanged();
                        },
                      )
                    : null,
                border: const OutlineInputBorder(),
                contentPadding: const EdgeInsets.symmetric(
                    vertical: 8, horizontal: 12),
              ),
              onChanged: (value) {
                setState(() => searchQuery = value.isEmpty ? null : value);
                _debouncer.run(_onFilterChanged);
              },
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
            if (errorMessage != null)
              ErrorStateWidget(message: errorMessage!, onRetry: _loadLeads)
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
                                onConvert: _convertLead,
                                onViewQuotations: _viewQuotations,
                                onViewTasks: _viewTasks,
                                onViewActivity: _viewActivity,
                                onViewInteractions: _viewInteractions,
                                onViewScoreHistory: _viewScoreHistory,
                                onLogActivity: _logActivity,
                                onViewDocuments: _viewDocuments,
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
                                  onConvert: _convertLead,
                                  onViewQuotations: _viewQuotations,
                                  onViewTasks: _viewTasks,
                                  onViewActivity: _viewActivity,
                                  onViewInteractions: _viewInteractions,
                                  onViewScoreHistory: _viewScoreHistory,
                                  onLogActivity: _logActivity,
                                  onViewDocuments: _viewDocuments,
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
                                  onConvert: _convertLead,
                                  onViewQuotations: _viewQuotations,
                                  onViewTasks: _viewTasks,
                                  onViewActivity: _viewActivity,
                                  onViewInteractions: _viewInteractions,
                                  onViewScoreHistory: _viewScoreHistory,
                                  onLogActivity: _logActivity,
                                  onViewDocuments: _viewDocuments,
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

  void _logActivity(Lead lead) {
    showDialog(
      context: context,
      builder: (context) => AddInteractionDialog(
        leadId: int.tryParse(lead.leadId) ?? 0,
        onSave: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Activity logged successfully')),
          );
          // Optional: Refresh leads or timeline
        },
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
          child: DropdownButton<String?>(
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
                      firstDate: AppConfig.datePickerFirstDate,
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
      DropdownButton<String?>(
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
        items: const [
          DropdownMenuItem(value: null, child: Text('All Types')),
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
            firstDate: AppConfig.datePickerFirstDate,
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
        _isPageLoading = true;
        errorMessage = null;
      });

      final response = await _leadService.getLeadsPaginated(_paginationParams);

      if (mounted) {
        setState(() {
          leads.clear();
          leads.addAll(response.data);
          totalPages = response.totalPages;
          totalItems = response.totalItems;
          itemsPerPage = response.itemsPerPage;
          hasNextPage = response.hasNextPage;
          hasPreviousPage = response.hasPreviousPage;
          _isPageLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isPageLoading = false;
          errorMessage = ErrorHandler.getErrorMessage(e);
        });
      }
    }
  }

  Future<void> _deleteLead(Lead lead) async {
    // Confirmation dialog is already shown in LeadsTable._showDeleteConfirmation
    // This method is called after user confirms deletion
    try {
      await _leadService.deleteLead(lead.leadId);
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
        ErrorHandler.showErrorSnackBar(context, e);
      }
    }
  }

  Future<void> _convertLead(Lead lead) async {
    final GlobalKey<FormState> conversionFormKey = GlobalKey<FormState>();
    final TextEditingController projectNameController =
        TextEditingController(text: '${lead.name} Project');
    final TextEditingController startDateController =
        TextEditingController(text: DateTime.now().toString().substring(0, 10));
    final TextEditingController locationController = TextEditingController(
        text: lead.location.isNotEmpty
            ? lead.location
            : (lead.district.isNotEmpty ? lead.district : lead.state));

    // Coerce to a known dropdown value — the lead's stored projectType may be
    // legacy/uppercase (e.g. "RESIDENTIAL") which has no matching DropdownMenuItem.
    String projectType = lead.projectType.isNotEmpty
        ? ProjectType.fromValue(lead.projectType).value
        : ProjectTypeConstants.defaultValue;
    DateTime selectedDate = DateTime.now();

    // Show Dialog
    final shouldConvert = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Convert into Customer'),
          content: SizedBox(
            width: 500,
            child: Form(
              key: conversionFormKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                      'Convert "${lead.name}" into a Customer? This will create a Customer account and a Project.',
                      style: TextStyle(color: Colors.grey[700])),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: projectNameController,
                    decoration: const InputDecoration(
                        labelText: 'Project Name *',
                        border: OutlineInputBorder()),
                    validator: (v) => v?.isNotEmpty == true ? null : 'Required',
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: projectType,
                    decoration: const InputDecoration(
                        labelText: 'Project Type',
                        border: OutlineInputBorder()),
                    items: ProjectTypeConstants.formDropdownItems,
                    onChanged: (v) => projectType = v!,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: locationController,
                    decoration: const InputDecoration(
                        labelText: 'Location / Site Address',
                        border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: startDateController,
                    decoration: const InputDecoration(
                      labelText: 'Start Date',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    readOnly: true,
                    onTap: () async {
                      final date = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100));
                      if (date != null) {
                        selectedDate = date;
                        startDateController.text =
                            date.toString().substring(0, 10);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Convert'),
            ),
          ],
        );
      },
    );

    if (shouldConvert == true) {
      if (mounted) setState(() => _isPageLoading = true);
      try {
        final requestData = {
          "projectName": projectNameController.text,
          "projectType": projectType,
          "startDate": startDateController.text,
          "location": locationController.text,
          // "projectManagerId": ... (Optional, can be assigned later)
        };

        // Call Service
        final newProject =
            await _leadService.convertLead(lead.leadId, requestData);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Lead converted successfully!')));
          _loadLeads(resetPage: false); // Refresh list to show updated status
        }

        // B9 — offer to materialize a WBS from a template. Permission-gated
        // and a no-op if the project type doesn't map to any WBS template.
        if (mounted) {
          await runWbsTemplatePickerFlow(
            context: context,
            project: newProject,
            perms: context.read<PermissionProvider>(),
          );
        }
      } catch (e) {
        if (mounted) {
          ErrorHandler.showErrorSnackBar(context, e);
        }
      } finally {
        if (mounted) setState(() => _isPageLoading = false);
      }
    }
  }

  Future<void> _viewTasks(Lead lead) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LeadTasksScreen(lead: lead),
      ),
    );
  }

  void _viewActivity(Lead lead) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => LeadActivityScreen(lead: lead),
      ),
    );
  }

  void _viewInteractions(Lead lead) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => LeadInteractionsScreen(leadId: lead.leadId),
      ),
    );
  }

  void _viewScoreHistory(Lead lead) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => LeadScoreHistoryScreen(lead: lead),
      ),
    );
  }

  void _viewDocuments(Lead lead) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => LeadDocumentsScreen(lead: lead),
      ),
    );
  }

  Future<void> _viewQuotations(Lead lead) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            LeadQuotationsScreen(lead: lead, leadId: int.tryParse(lead.leadId)),
      ),
    );
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
                    _loadLeads(resetPage: false);
                  },
                  icon: const Icon(Icons.chevron_left),
                ),
              Text('Page ${totalPages == 0 ? 0 : currentPage + 1} of $totalPages'),
              if (hasNextPage)
                IconButton(
                  onPressed: () {
                    setState(() => currentPage++);
                    _loadLeads(resetPage: false);
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

class LeadsTable extends StatefulWidget {
  final List<Lead> leads;
  final Function(Lead) onEdit;
  final Function(Lead) onDelete;
  final Function(Lead) onConvert;
  final Function(Lead) onViewQuotations;
  final Function(Lead) onViewTasks;
  final Function(Lead) onViewActivity;
  final Function(Lead) onViewInteractions;
  final Function(Lead) onViewScoreHistory;
  final Function(Lead) onViewDocuments;
  final Function(Lead) onLogActivity;

  const LeadsTable({
    super.key,
    required this.leads,
    required this.onEdit,
    required this.onDelete,
    required this.onConvert,
    required this.onViewQuotations,
    required this.onViewTasks,
    required this.onViewActivity,
    required this.onViewInteractions,
    required this.onViewScoreHistory,
    required this.onViewDocuments,
    required this.onLogActivity,
  });

  @override
  State<LeadsTable> createState() => _LeadsTableState();
}

class _LeadsTableState extends State<LeadsTable> {
  final ScrollController _horizontalScrollController = ScrollController();

  @override
  void dispose() {
    _horizontalScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(defaultPadding),
      decoration: ContainerStyles.secondaryBox,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Scrollable table columns
              Expanded(
                child: Scrollbar(
                  controller: _horizontalScrollController,
                  thumbVisibility: true,
                  trackVisibility: true,
                  child: SingleChildScrollView(
                    controller: _horizontalScrollController,
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columnSpacing: defaultPadding,
                      dataRowMinHeight: 52,
                      dataRowMaxHeight: 52,
                      headingRowHeight: 56,
                      columns: const [
                        DataColumn(label: Text("Name")),
                        DataColumn(label: Text("Contact")),
                        DataColumn(label: Text("Status")),
                        DataColumn(label: Text("Score")),
                        DataColumn(label: Text("Priority")),
                        DataColumn(label: Text("Project")),
                        DataColumn(label: Text("Budget")),
                        DataColumn(label: Text("Sales Rep")),
                        DataColumn(label: Text("Next Follow-up")),
                      ],
                      rows: widget.leads.map((lead) {
                        return DataRow(
                          cells: [
                            // Name Column
                            DataCell(
                              ConstrainedBox(
                                constraints:
                                    const BoxConstraints(maxWidth: 160),
                                child: Tooltip(
                                  message: lead.source == LeadSource.referralClient
                                      ? '${lead.name} (Referred by client)'
                                      : lead.source == LeadSource.referralArchitect
                                          ? '${lead.name} (Referred by architect/designer)'
                                          : lead.name,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        lead.name,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (lead.source == LeadSource.referralClient ||
                                          lead.source == LeadSource.referralArchitect)
                                        Container(
                                          margin: const EdgeInsets.only(top: 2),
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 5, vertical: 1),
                                          decoration: BoxDecoration(
                                            color: lead.source == LeadSource.referralArchitect
                                                ? Colors.purple.withOpacity(0.12)
                                                : Colors.green.withOpacity(0.12),
                                            borderRadius: BorderRadius.circular(4),
                                            border: Border.all(
                                              color: lead.source == LeadSource.referralArchitect
                                                  ? Colors.purple.withOpacity(0.4)
                                                  : Colors.green.withOpacity(0.4),
                                              width: 0.5,
                                            ),
                                          ),
                                          child: Text(
                                            lead.source == LeadSource.referralArchitect
                                                ? 'Referred'
                                                : 'Referred',
                                            style: TextStyle(
                                              fontSize: 9,
                                              fontWeight: FontWeight.w600,
                                              color: lead.source == LeadSource.referralArchitect
                                                  ? Colors.purple
                                                  : Colors.green,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                              onTap: () => widget.onEdit(lead),
                            ),

                            // Contact Column
                            DataCell(
                              ConstrainedBox(
                                constraints:
                                    const BoxConstraints(maxWidth: 180),
                                child: Tooltip(
                                  message: '${lead.phone}\n${lead.email}',
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(lead.status),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  _humanize(lead.status),
                                  style: const TextStyle(
                                    color: textPrimary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),

                            // Score Column
                            DataCell(
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _getScoreColor(lead.score)
                                      .withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: _getScoreColor(lead.score),
                                      width: 1),
                                ),
                                child: Text(
                                  '${lead.score}',
                                  style: TextStyle(
                                    color: _getScoreColor(lead.score),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                            // Priority Column
                            DataCell(
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
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
                                constraints:
                                    const BoxConstraints(maxWidth: 120),
                                child: Tooltip(
                                  message:
                                      '${lead.projectType}\n${lead.customerType}',
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        _projectTypeLabel(lead.projectType),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            // Budget Column
                            DataCell(
                              ConstrainedBox(
                                constraints:
                                    const BoxConstraints(maxWidth: 100),
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
                                      color: lead.budget != null
                                          ? Colors.green
                                          : Colors.grey,
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
                                constraints:
                                    const BoxConstraints(maxWidth: 100),
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
                                            lead.nextFollowUp!
                                                .isBefore(DateTime.now())
                                        ? Colors.red
                                        : null,
                                    fontWeight: lead.nextFollowUp != null &&
                                            lead.nextFollowUp!
                                                .isBefore(DateTime.now())
                                        ? FontWeight.bold
                                        : null,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),

              // Fixed Actions Column
              Container(
                width: 120,
                decoration: BoxDecoration(
                  border: Border(
                    left: BorderSide(
                      color: Colors.grey.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header
                    Container(
                      height: 56,
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: const Text(
                        "Actions",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                    // Rows
                    ...widget.leads.asMap().entries.map((entry) {
                      final lead = entry.value;
                      return Consumer<PermissionProvider>(
                        builder: (context, permissions, child) {
                          return Container(
                            height: 52,
                            alignment: Alignment.center,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Edit button - Primary action
                                if (permissions.canEditLead)
                                  SizedBox(
                                    width: 32,
                                    height: 32,
                                    child: IconButton(
                                      icon: const Icon(Icons.edit,
                                          color: Colors.blue, size: 18),
                                      tooltip: 'Edit Lead',
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      onPressed: () => widget.onEdit(lead),
                                    ),
                                  ),

                                // More Actions Menu
                                SizedBox(
                                  width: 32,
                                  height: 32,
                                  child: PopupMenuButton<String>(
                                    icon: const Icon(Icons.more_vert, size: 20),
                                    padding: EdgeInsets.zero,
                                    tooltip: 'More Actions',
                                    onSelected: (value) {
                                      switch (value) {
                                        case 'convert':
                                          widget.onConvert(lead);
                                          break;
                                        case 'log':
                                          widget.onLogActivity(lead);
                                          break;
                                        case 'quotes':
                                          widget.onViewQuotations(lead);
                                          break;
                                        case 'tasks':
                                          widget.onViewTasks(lead);
                                          break;
                                        case 'activity':
                                          widget.onViewActivity(lead);
                                          break;
                                        case 'interactions':
                                          widget.onViewInteractions(lead);
                                          break;
                                        case 'score_history':
                                          widget.onViewScoreHistory(lead);
                                          break;
                                        case 'docs':
                                          widget.onViewDocuments(lead);
                                          break;
                                        case 'delete':
                                          _showDeleteConfirmation(
                                              context, lead);
                                          break;
                                      }
                                    },
                                    itemBuilder: (context) => [
                                      if (permissions.canCreateLead &&
                                          lead.status.toLowerCase() !=
                                              'converted')
                                        const PopupMenuItem(
                                          value: 'convert',
                                          child: ListTile(
                                            leading: Icon(Icons.transform,
                                                color: Colors.green, size: 20),
                                            title:
                                                Text('Convert into Customer'),
                                            contentPadding: EdgeInsets.zero,
                                            dense: true,
                                          ),
                                        ),
                                      const PopupMenuItem(
                                        value: 'log',
                                        child: ListTile(
                                          leading: Icon(Icons.note_add,
                                              color: Colors.teal, size: 20),
                                          title: Text('Log Activity'),
                                          contentPadding: EdgeInsets.zero,
                                          dense: true,
                                        ),
                                      ),
                                      const PopupMenuItem(
                                        value: 'quotes',
                                        child: ListTile(
                                          leading: Icon(Icons.request_quote,
                                              color: Colors.amber, size: 20),
                                          title: Text('View Quotations'),
                                          contentPadding: EdgeInsets.zero,
                                          dense: true,
                                        ),
                                      ),
                                      const PopupMenuItem(
                                        value: 'tasks',
                                        child: ListTile(
                                          leading: Icon(Icons.assignment,
                                              color: Colors.blue, size: 20),
                                          title: Text('View Tasks'),
                                          contentPadding: EdgeInsets.zero,
                                          dense: true,
                                        ),
                                      ),
                                      const PopupMenuItem(
                                        value: 'activity',
                                        child: ListTile(
                                          leading: Icon(Icons.history,
                                              color: Colors.purple, size: 20),
                                          title: Text('View Activity'),
                                          contentPadding: EdgeInsets.zero,
                                          dense: true,
                                        ),
                                      ),
                                      const PopupMenuItem(
                                        value: 'interactions',
                                        child: ListTile(
                                          leading: Icon(Icons.chat_bubble,
                                              color: Colors.indigo, size: 20),
                                          title: Text('View Interactions'),
                                          contentPadding: EdgeInsets.zero,
                                          dense: true,
                                        ),
                                      ),
                                      const PopupMenuItem(
                                        value: 'score_history',
                                        child: ListTile(
                                          leading: Icon(Icons.trending_up,
                                              color: Colors.amber, size: 20),
                                          title: Text('View Score History'),
                                          contentPadding: EdgeInsets.zero,
                                          dense: true,
                                        ),
                                      ),
                                      const PopupMenuItem(
                                        value: 'docs',
                                        child: ListTile(
                                          leading: Icon(Icons.folder,
                                              color: Colors.brown, size: 20),
                                          title: Text('View Documents'),
                                          contentPadding: EdgeInsets.zero,
                                          dense: true,
                                        ),
                                      ),
                                      if (permissions.canDeleteLead)
                                        const PopupMenuItem(
                                          value: 'delete',
                                          child: ListTile(
                                            leading: Icon(Icons.delete,
                                                color: Colors.red, size: 20),
                                            title: Text('Delete'),
                                            contentPadding: EdgeInsets.zero,
                                            dense: true,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    }),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'new_inquiry':
        return Colors.blue;
      case 'contacted':
        return Colors.orange;
      case 'qualified':
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

  String _humanize(String raw) {
    if (raw.isEmpty) return raw;
    return raw
        .replaceAll('_', ' ')
        .split(' ')
        .where((w) => w.isNotEmpty)
        .map((w) => w[0].toUpperCase() + w.substring(1).toLowerCase())
        .join(' ');
  }

  String _projectTypeLabel(String raw) {
    if (raw.isEmpty) return 'N/A';
    final match = ProjectType.values.where((t) => t.value == raw.toLowerCase());
    return match.isNotEmpty ? match.first.label : _humanize(raw);
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

  Color _getScoreColor(int score) {
    if (score > 60) return Colors.red;
    if (score >= 30) return Colors.orange;
    return Colors.grey;
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
                widget.onDelete(lead);
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
          }),
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
        ],
      ),
    );
  }
}
