import 'package:flutter/material.dart';
import 'package:admin/constants.dart';
import 'package:admin/features/leads/data/models/lead.dart';
import 'package:admin/features/leads/data/models/lead_interaction.dart';
import 'package:admin/features/leads/data/services/lead_service.dart';
import 'package:admin/features/leads/presentation/screens/components/add_interaction_dialog.dart';
import 'package:intl/intl.dart';

class FollowUpsScreen extends StatefulWidget {
  const FollowUpsScreen({super.key});

  @override
  State<FollowUpsScreen> createState() => FollowUpsScreenState();
}

class FollowUpsScreenState extends State<FollowUpsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final LeadService _leadService = LeadService();

  // Overdue tab
  List<Lead> _overdueLeads = [];
  bool _isLoadingOverdue = true;
  String? _overdueError;

  // All interactions tab
  List<LeadInteraction> _interactions = [];
  bool _isLoadingInteractions = true;
  String? _interactionsError;
  int _currentPage = 0;
  int _totalPages = 1;
  int _totalElements = 0;
  final int _pageSize = 20;
  String _typeFilter = 'All';
  final TextEditingController _searchController = TextEditingController();

  final List<String> _interactionTypes = [
    'All', 'CALL', 'EMAIL', 'MEETING', 'SITE_VISIT', 'WHATSAPP', 'OTHER'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadOverdueFollowUps();
    _loadInteractions();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadOverdueFollowUps() async {
    setState(() { _isLoadingOverdue = true; _overdueError = null; });
    try {
      final leads = await _leadService.getOverdueFollowUps();
      setState(() { _overdueLeads = leads; _isLoadingOverdue = false; });
    } catch (e) {
      setState(() { _overdueError = e.toString(); _isLoadingOverdue = false; });
    }
  }

  Future<void> _loadInteractions() async {
    setState(() { _isLoadingInteractions = true; _interactionsError = null; });
    try {
      final filters = <String, dynamic>{};
      if (_typeFilter != 'All') filters['interactionType'] = _typeFilter;

      final result = await _leadService.searchLeadInteractions(
        page: _currentPage,
        size: _pageSize,
        sortBy: 'interactionDate',
        sortDirection: 'desc',
        search: _searchController.text.isNotEmpty ? _searchController.text : null,
        filters: filters.isNotEmpty ? filters : null,
      );
      setState(() {
        _interactions = result.content;
        _totalPages = result.totalPages;
        _totalElements = result.totalElements;
        _isLoadingInteractions = false;
      });
    } catch (e) {
      setState(() { _interactionsError = e.toString(); _isLoadingInteractions = false; });
    }
  }

  Color _getTypeColor(String type) {
    switch (type.toUpperCase()) {
      case 'CALL': return Colors.blue;
      case 'EMAIL': return Colors.teal;
      case 'MEETING': return Colors.purple;
      case 'SITE_VISIT': return Colors.orange;
      case 'WHATSAPP': return Colors.green;
      default: return Colors.grey;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type.toUpperCase()) {
      case 'CALL': return Icons.phone;
      case 'EMAIL': return Icons.email;
      case 'MEETING': return Icons.groups;
      case 'SITE_VISIT': return Icons.location_on;
      case 'WHATSAPP': return Icons.chat;
      default: return Icons.note;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: const EdgeInsets.all(defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Follow-ups & Interactions", style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: defaultPadding),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: containerBorder),
              ),
              child: TabBar(
                controller: _tabController,
                labelColor: primaryColor,
                unselectedLabelColor: textSecondary,
                indicatorColor: primaryColor,
                tabs: [
                  Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.warning_amber, size: 18),
                        const SizedBox(width: 6),
                        const Text('Overdue Follow-ups'),
                        if (_overdueLeads.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: errorColor, borderRadius: BorderRadius.circular(10)),
                            child: Text('${_overdueLeads.length}', style: const TextStyle(color: Colors.white, fontSize: 11)),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.history, size: 18),
                        const SizedBox(width: 6),
                        const Text('All Interactions'),
                        if (_totalElements > 0) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: infoColor, borderRadius: BorderRadius.circular(10)),
                            child: Text('$_totalElements', style: const TextStyle(color: Colors.white, fontSize: 11)),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: defaultPadding),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildOverdueTab(),
                  _buildInteractionsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverdueTab() {
    if (_isLoadingOverdue) return const Center(child: CircularProgressIndicator());
    if (_overdueError != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: errorColor),
            const SizedBox(height: 8),
            const Text('Failed to load overdue follow-ups', style: TextStyle(color: errorColor)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _loadOverdueFollowUps, child: const Text('Retry')),
          ],
        ),
      );
    }
    if (_overdueLeads.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_outline, size: 48, color: successColor),
            SizedBox(height: 8),
            Text('No overdue follow-ups!', style: TextStyle(color: textSecondary, fontSize: 16)),
            SizedBox(height: 4),
            Text('All follow-ups are on track.', style: TextStyle(color: textMuted, fontSize: 13)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadOverdueFollowUps,
      child: ListView.builder(
        itemCount: _overdueLeads.length,
        itemBuilder: (ctx, i) {
          final lead = _overdueLeads[i];
          final daysOverdue = lead.nextFollowUp != null
              ? DateTime.now().difference(lead.nextFollowUp!).inDays
              : 0;

          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            child: ListTile(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => AddInteractionDialog(
                    leadId: int.tryParse(lead.leadId) ?? 0,
                    onSave: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Interaction logged successfully')),
                      );
                      _loadOverdueFollowUps();
                    },
                  ),
                );
              },
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: CircleAvatar(
                backgroundColor: errorColor.withOpacity(0.1),
                child: const Icon(Icons.warning, color: errorColor),
              ),
              title: Row(
                children: [
                  Text(lead.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: errorColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: errorColor.withOpacity(0.3)),
                    ),
                    child: Text('$daysOverdue day${daysOverdue == 1 ? '' : 's'} overdue',
                        style: const TextStyle(fontSize: 11, color: errorColor, fontWeight: FontWeight.w500)),
                  ),
                ],
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text('Status: ${lead.status} | Source: ${lead.source.name}',
                      style: const TextStyle(fontSize: 12, color: textSecondary)),
                  if (lead.nextFollowUp != null)
                    Text('Follow-up was: ${DateFormat('dd MMM yyyy').format(lead.nextFollowUp!)}',
                        style: const TextStyle(fontSize: 12, color: textSecondary)),
                ],
              ),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _getPriorityColor(lead.priority.name).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(lead.priority.name, style: TextStyle(fontSize: 12, color: _getPriorityColor(lead.priority.name))),
              ),
            ),
          );
        },
      ),
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toUpperCase()) {
      case 'HIGH': case 'URGENT': return errorColor;
      case 'MEDIUM': return warningColor;
      case 'LOW': return successColor;
      default: return textSecondary;
    }
  }

  Widget _buildInteractionsTab() {
    return Column(
      children: [
        // Filters
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: containerBorder),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search interactions...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    isDense: true,
                  ),
                  onSubmitted: (_) { setState(() => _currentPage = 0); _loadInteractions(); },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _typeFilter,
                  decoration: InputDecoration(
                    labelText: 'Type',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    isDense: true,
                  ),
                  items: _interactionTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                  onChanged: (v) {
                    setState(() { _typeFilter = v ?? 'All'; _currentPage = 0; });
                    _loadInteractions();
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _isLoadingInteractions
              ? const Center(child: CircularProgressIndicator())
              : _interactionsError != null
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error_outline, size: 48, color: errorColor),
                          const SizedBox(height: 16),
                          ElevatedButton(onPressed: _loadInteractions, child: const Text('Retry')),
                        ],
                      ),
                    )
                  : _interactions.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.history, size: 48, color: Colors.grey[400]),
                              const SizedBox(height: 8),
                              const Text('No interactions found', style: TextStyle(color: textSecondary)),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: _interactions.length,
                          itemBuilder: (ctx, i) {
                            final interaction = _interactions[i];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 6),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                leading: CircleAvatar(
                                  backgroundColor: _getTypeColor(interaction.interactionType).withOpacity(0.1),
                                  child: Icon(_getTypeIcon(interaction.interactionType),
                                      color: _getTypeColor(interaction.interactionType), size: 20),
                                ),
                                title: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: _getTypeColor(interaction.interactionType).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(interaction.interactionType.replaceAll('_', ' '),
                                          style: TextStyle(fontSize: 11, color: _getTypeColor(interaction.interactionType), fontWeight: FontWeight.w500)),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(interaction.subject ?? 'No subject',
                                          style: const TextStyle(fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis),
                                    ),
                                  ],
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (interaction.notes != null && interaction.notes!.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: Text(interaction.notes!, maxLines: 2, overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(fontSize: 12, color: textSecondary)),
                                      ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Text('Lead #${interaction.leadId}', style: const TextStyle(fontSize: 11, color: textMuted)),
                                        if (interaction.durationMinutes != null) ...[
                                          const SizedBox(width: 12),
                                          const Icon(Icons.timer, size: 12, color: textMuted),
                                          Text(' ${interaction.durationMinutes}min', style: const TextStyle(fontSize: 11, color: textMuted)),
                                        ],
                                        if (interaction.outcome != null) ...[
                                          const SizedBox(width: 12),
                                          Text(interaction.outcome!.replaceAll('_', ' '),
                                              style: const TextStyle(fontSize: 11, color: infoColor)),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                                trailing: Text(
                                  DateFormat('dd MMM\nyyyy').format(interaction.interactionDate),
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(fontSize: 11, color: textSecondary),
                                ),
                              ),
                            );
                          },
                        ),
        ),
        // Pagination
        if (!_isLoadingInteractions && _totalPages > 1)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: _currentPage > 0 ? () { setState(() => _currentPage--); _loadInteractions(); } : null,
                ),
                Text('Page ${_currentPage + 1} of $_totalPages', style: const TextStyle(fontSize: 13)),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: _currentPage < _totalPages - 1 ? () { setState(() => _currentPage++); _loadInteractions(); } : null,
                ),
              ],
            ),
          ),
      ],
    );
  }
}
