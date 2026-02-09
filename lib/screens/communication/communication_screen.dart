import 'package:flutter/material.dart';
import 'package:admin/constants.dart';
import 'package:admin/features/leads/data/models/lead_interaction.dart';
import 'package:admin/features/leads/data/services/lead_service.dart';
import 'package:intl/intl.dart';

class CommunicationScreen extends StatefulWidget {
  const CommunicationScreen({super.key});

  @override
  CommunicationScreenState createState() => CommunicationScreenState();
}

class CommunicationScreenState extends State<CommunicationScreen> {
  final LeadService _leadService = LeadService();

  List<LeadInteraction> _interactions = [];
  bool _isLoading = true;
  String? _error;
  int _currentPage = 0;
  int _totalPages = 1;
  int _totalElements = 0;
  final int _pageSize = 20;
  String _typeFilter = 'All';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  final List<String> _types = ['All', 'CALL', 'EMAIL', 'MEETING', 'SITE_VISIT', 'WHATSAPP', 'OTHER'];

  // Stats
  Map<String, int> _typeCounts = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final filters = <String, dynamic>{};
      if (_typeFilter != 'All') filters['interactionType'] = _typeFilter;

      final result = await _leadService.searchLeadInteractions(
        page: _currentPage,
        size: _pageSize,
        sortBy: 'interactionDate',
        sortDirection: 'desc',
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
        filters: filters.isNotEmpty ? filters : null,
      );

      // Count types from current page
      final counts = <String, int>{};
      for (final i in result.content) {
        counts[i.interactionType] = (counts[i.interactionType] ?? 0) + 1;
      }

      setState(() {
        _interactions = result.content;
        _totalPages = result.totalPages;
        _totalElements = result.totalElements;
        _typeCounts = counts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  Color _getTypeColor(String type) {
    switch (type.toUpperCase()) {
      case 'CALL': return Colors.blue;
      case 'EMAIL': return Colors.teal;
      case 'MEETING': return Colors.purple;
      case 'SITE_VISIT': return Colors.orange;
      case 'WHATSAPP': return const Color(0xFF25D366);
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
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Communication Log", style: Theme.of(context).textTheme.headlineMedium),
                IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData, tooltip: 'Refresh'),
              ],
            ),
            const SizedBox(height: defaultPadding),

            // Type summary chips
            if (!_isLoading && _interactions.isNotEmpty)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _types.where((t) => t != 'All').map((type) {
                  final count = _typeCounts[type] ?? 0;
                  final isSelected = _typeFilter == type;
                  return InkWell(
                    onTap: () {
                      setState(() {
                        _typeFilter = isSelected ? 'All' : type;
                        _currentPage = 0;
                      });
                      _loadData();
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected ? _getTypeColor(type).withOpacity(0.2) : _getTypeColor(type).withOpacity(0.05),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? _getTypeColor(type) : _getTypeColor(type).withOpacity(0.3),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(_getTypeIcon(type), size: 16, color: _getTypeColor(type)),
                          const SizedBox(width: 4),
                          Text(type.replaceAll('_', ' '),
                              style: TextStyle(fontSize: 12, color: _getTypeColor(type), fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                          if (count > 0) ...[
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: _getTypeColor(type),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text('$count', style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            if (!_isLoading && _interactions.isNotEmpty) const SizedBox(height: defaultPadding),

            // Search bar
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
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search communications by subject, notes...',
                        prefixIcon: const Icon(Icons.search, size: 20),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() { _searchQuery = ''; _currentPage = 0; });
                                  _loadData();
                                },
                              )
                            : null,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        isDense: true,
                      ),
                      onSubmitted: (v) {
                        setState(() { _searchQuery = v; _currentPage = 0; });
                        _loadData();
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text('$_totalElements total', style: const TextStyle(color: textSecondary, fontSize: 13)),
                ],
              ),
            ),
            const SizedBox(height: defaultPadding),

            // Content
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.error_outline, size: 48, color: errorColor),
                              const SizedBox(height: 8),
                              Text('Failed to load communications', style: TextStyle(color: errorColor)),
                              const SizedBox(height: 16),
                              ElevatedButton(onPressed: _loadData, child: const Text('Retry')),
                            ],
                          ),
                        )
                      : _interactions.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.forum_outlined, size: 48, color: Colors.grey[400]),
                                  const SizedBox(height: 8),
                                  const Text('No communications found', style: TextStyle(color: textSecondary)),
                                ],
                              ),
                            )
                          : ListView.builder(
                              itemCount: _interactions.length,
                              itemBuilder: (ctx, i) => _buildInteractionCard(_interactions[i]),
                            ),
            ),

            // Pagination
            if (!_isLoading && _totalPages > 1)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: _currentPage > 0 ? () { setState(() => _currentPage--); _loadData(); } : null,
                    ),
                    Text('Page ${_currentPage + 1} of $_totalPages', style: const TextStyle(fontSize: 13)),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: _currentPage < _totalPages - 1 ? () { setState(() => _currentPage++); _loadData(); } : null,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInteractionCard(LeadInteraction interaction) {
    final typeColor = _getTypeColor(interaction.interactionType);
    final dateStr = DateFormat('dd MMM yyyy, hh:mm a').format(interaction.interactionDate);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: IntrinsicHeight(
        child: Row(
          children: [
            // Left color bar
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: typeColor,
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(10), bottomLeft: Radius.circular(10)),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: typeColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(_getTypeIcon(interaction.interactionType), size: 18, color: typeColor),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: typeColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      interaction.interactionType.replaceAll('_', ' '),
                                      style: TextStyle(fontSize: 11, color: typeColor, fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text('Lead #${interaction.leadId}', style: const TextStyle(fontSize: 11, color: textMuted)),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                interaction.subject ?? 'No subject',
                                style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(dateStr, style: const TextStyle(fontSize: 11, color: textSecondary)),
                            if (interaction.durationMinutes != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.timer, size: 12, color: textMuted),
                                    const SizedBox(width: 2),
                                    Text('${interaction.durationMinutes} min', style: const TextStyle(fontSize: 11, color: textMuted)),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                    if (interaction.notes != null && interaction.notes!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(interaction.notes!, style: const TextStyle(fontSize: 13, color: textSecondary), maxLines: 2, overflow: TextOverflow.ellipsis),
                    ],
                    if (interaction.outcome != null || interaction.nextAction != null) ...[
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        children: [
                          if (interaction.outcome != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: boxSuccess,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: boxBorderSuccess),
                              ),
                              child: Text('Outcome: ${interaction.outcome!.replaceAll('_', ' ')}',
                                  style: const TextStyle(fontSize: 11, color: successColor)),
                            ),
                          if (interaction.nextAction != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: boxWarning,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: boxBorderWarning),
                              ),
                              child: Text('Next: ${interaction.nextAction!}',
                                  style: const TextStyle(fontSize: 11, color: warningColor)),
                            ),
                          if (interaction.nextActionDate != null)
                            Text('Due: ${DateFormat('dd MMM').format(interaction.nextActionDate!)}',
                                style: const TextStyle(fontSize: 11, color: textMuted)),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
