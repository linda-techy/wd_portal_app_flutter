import 'package:flutter/material.dart';
import 'package:admin/constants.dart';
import 'package:admin/features/leads/data/models/lead_quotation.dart';
import 'package:admin/features/leads/data/services/lead_quotation_service.dart';
import 'package:intl/intl.dart';

class QuotationsScreen extends StatefulWidget {
  const QuotationsScreen({super.key});

  @override
  _QuotationsScreenState createState() => _QuotationsScreenState();
}

class _QuotationsScreenState extends State<QuotationsScreen> {
  final LeadQuotationService _quotationService = LeadQuotationService();
  List<LeadQuotation> _quotations = [];
  bool _isLoading = true;
  String? _error;
  String _searchQuery = '';
  String _statusFilter = 'All';
  int _currentPage = 0;
  int _totalPages = 1;
  int _totalElements = 0;
  final int _pageSize = 20;
  final TextEditingController _searchController = TextEditingController();
  final _currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '\u20B9');

  final List<String> _statuses = ['All', 'DRAFT', 'SENT', 'VIEWED', 'ACCEPTED', 'REJECTED', 'EXPIRED'];

  @override
  void initState() {
    super.initState();
    _loadQuotations();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadQuotations() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final filters = <String, dynamic>{};
      if (_statusFilter != 'All') filters['status'] = _statusFilter;

      final result = await _quotationService.searchLeadQuotations(
        page: _currentPage,
        size: _pageSize,
        sortBy: 'createdAt',
        sortDirection: 'desc',
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
        filters: filters.isNotEmpty ? filters : null,
      );
      setState(() {
        _quotations = result.content;
        _totalPages = result.totalPages;
        _totalElements = result.totalElements;
        _isLoading = false;
      });
    } catch (e) {
      setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'DRAFT': return Colors.grey;
      case 'SENT': return infoColor;
      case 'VIEWED': return warningColor;
      case 'ACCEPTED': return successColor;
      case 'REJECTED': return errorColor;
      case 'EXPIRED': return Colors.brown;
      default: return textSecondary;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toUpperCase()) {
      case 'DRAFT': return Icons.edit_note;
      case 'SENT': return Icons.send;
      case 'VIEWED': return Icons.visibility;
      case 'ACCEPTED': return Icons.check_circle;
      case 'REJECTED': return Icons.cancel;
      case 'EXPIRED': return Icons.timer_off;
      default: return Icons.description;
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
                Text("Quotations Management", style: Theme.of(context).textTheme.headlineMedium),
                IconButton(icon: const Icon(Icons.refresh), onPressed: _loadQuotations, tooltip: 'Refresh'),
              ],
            ),
            const SizedBox(height: defaultPadding),

            // Search & Filters
            Container(
              padding: const EdgeInsets.all(defaultPadding),
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
                        hintText: 'Search quotations...',
                        prefixIcon: const Icon(Icons.search, size: 20),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() { _searchQuery = ''; _currentPage = 0; });
                                  _loadQuotations();
                                },
                              )
                            : null,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        isDense: true,
                      ),
                      onSubmitted: (v) {
                        setState(() { _searchQuery = v; _currentPage = 0; });
                        _loadQuotations();
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _statusFilter,
                      decoration: InputDecoration(
                        labelText: 'Status',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        isDense: true,
                      ),
                      items: _statuses.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                      onChanged: (v) {
                        setState(() { _statusFilter = v ?? 'All'; _currentPage = 0; });
                        _loadQuotations();
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: defaultPadding),

            // Results count
            Text('$_totalElements quotation${_totalElements == 1 ? '' : 's'} found',
                style: const TextStyle(color: textSecondary, fontSize: 13)),
            const SizedBox(height: 8),

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
                              Text('Failed to load quotations', style: TextStyle(color: errorColor)),
                              const SizedBox(height: 16),
                              ElevatedButton(onPressed: _loadQuotations, child: const Text('Retry')),
                            ],
                          ),
                        )
                      : _quotations.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.description_outlined, size: 48, color: Colors.grey[400]),
                                  const SizedBox(height: 8),
                                  const Text('No quotations found', style: TextStyle(color: textSecondary)),
                                ],
                              ),
                            )
                          : Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: containerBorder),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: SingleChildScrollView(
                                  child: SizedBox(
                                    width: double.infinity,
                                    child: DataTable(
                                      headingRowColor: WidgetStateProperty.all(boxSecondary),
                                      columnSpacing: 16,
                                      horizontalMargin: 16,
                                      columns: const [
                                        DataColumn(label: Text('Quotation #', style: TextStyle(fontWeight: FontWeight.bold))),
                                        DataColumn(label: Text('Title', style: TextStyle(fontWeight: FontWeight.bold))),
                                        DataColumn(label: Text('Lead ID', style: TextStyle(fontWeight: FontWeight.bold))),
                                        DataColumn(label: Text('Amount', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
                                        DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                                        DataColumn(label: Text('Valid Days', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
                                        DataColumn(label: Text('Created', style: TextStyle(fontWeight: FontWeight.bold))),
                                        DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
                                      ],
                                      rows: _quotations.map((q) => DataRow(
                                        cells: [
                                          DataCell(Text(q.quotationNumber ?? 'Draft', style: const TextStyle(fontWeight: FontWeight.w500))),
                                          DataCell(
                                            ConstrainedBox(
                                              constraints: const BoxConstraints(maxWidth: 200),
                                              child: Text(q.title, overflow: TextOverflow.ellipsis),
                                            ),
                                          ),
                                          DataCell(Text('#${q.leadId}')),
                                          DataCell(Text(q.finalAmount != null ? _currencyFormat.format(q.finalAmount) : '-')),
                                          DataCell(
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                              decoration: BoxDecoration(
                                                color: _getStatusColor(q.status).withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(12),
                                                border: Border.all(color: _getStatusColor(q.status).withOpacity(0.3)),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(_getStatusIcon(q.status), size: 14, color: _getStatusColor(q.status)),
                                                  const SizedBox(width: 4),
                                                  Text(q.status, style: TextStyle(fontSize: 12, color: _getStatusColor(q.status))),
                                                ],
                                              ),
                                            ),
                                          ),
                                          DataCell(Text('${q.validityDays}d')),
                                          DataCell(Text(q.createdAt != null ? DateFormat('dd MMM yyyy').format(q.createdAt!) : '-', style: const TextStyle(fontSize: 12))),
                                          DataCell(Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              if (q.status == 'DRAFT')
                                                IconButton(
                                                  icon: const Icon(Icons.send, size: 18),
                                                  onPressed: () => _sendQuotation(q),
                                                  tooltip: 'Send',
                                                  color: infoColor,
                                                  splashRadius: 18,
                                                ),
                                              IconButton(
                                                icon: const Icon(Icons.delete_outline, size: 18),
                                                onPressed: () => _deleteQuotation(q),
                                                tooltip: 'Delete',
                                                color: errorColor,
                                                splashRadius: 18,
                                              ),
                                            ],
                                          )),
                                        ],
                                      )).toList(),
                                    ),
                                  ),
                                ),
                              ),
                            ),
            ),

            // Pagination
            if (!_isLoading && _totalPages > 1)
              Padding(
                padding: const EdgeInsets.only(top: defaultPadding),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: _currentPage > 0 ? () { setState(() => _currentPage--); _loadQuotations(); } : null,
                    ),
                    Text('Page ${_currentPage + 1} of $_totalPages', style: const TextStyle(fontSize: 13)),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: _currentPage < _totalPages - 1 ? () { setState(() => _currentPage++); _loadQuotations(); } : null,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendQuotation(LeadQuotation q) async {
    try {
      await _quotationService.sendQuotation(q.id!);
      _loadQuotations();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Quotation sent successfully'), backgroundColor: successColor),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: errorColor),
        );
      }
    }
  }

  Future<void> _deleteQuotation(LeadQuotation q) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Quotation'),
        content: Text('Delete quotation ${q.quotationNumber ?? q.title}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: errorColor, foregroundColor: Colors.white),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await _quotationService.deleteQuotation(q.id!);
        _loadQuotations();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Quotation deleted'), backgroundColor: successColor),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: errorColor),
          );
        }
      }
    }
  }
}
