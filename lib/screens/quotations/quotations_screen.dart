import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:printing/printing.dart';
import 'package:admin/constants.dart';
import 'package:admin/utils/error_handler.dart';
import 'package:admin/utils/file_download_helper.dart';
import 'package:admin/features/leads/data/models/lead.dart';
import 'package:admin/features/leads/data/models/lead_quotation.dart';
import 'package:admin/features/leads/data/services/lead_quotation_service.dart';
import 'package:admin/features/leads/data/services/lead_service.dart';
import 'package:admin/features/leads/presentation/screens/add_quotation_screen.dart';
import 'package:admin/features/quotation_catalog/presentation/screens/quotation_catalog_picker_dialog.dart';
import 'package:admin/screens/quotations/widgets/quotation_row_actions.dart';
import 'package:intl/intl.dart';

class QuotationsScreen extends StatefulWidget {
  const QuotationsScreen({super.key});

  @override
  State<QuotationsScreen> createState() => QuotationsScreenState();
}

class QuotationsScreenState extends State<QuotationsScreen> {
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
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('New Quotation'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: _openLeadPickerForNewQuotation,
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.inventory_2_outlined, size: 16),
                      label: const Text('Manage Catalog'),
                      onPressed: () => context.go('/quotation-catalog'),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: _loadQuotations,
                      tooltip: 'Refresh',
                    ),
                  ],
                ),
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
                              const Icon(Icons.error_outline, size: 48, color: errorColor),
                              const SizedBox(height: 8),
                              const Text('Failed to load quotations', style: TextStyle(color: errorColor)),
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
                          : RefreshIndicator(
                              onRefresh: _loadQuotations,
                              child: SingleChildScrollView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: containerBorder),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
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
                                            onSelectChanged: q.id == null
                                                ? null
                                                : (_) => context
                                                    .go('/quotations/${q.id}'),
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
                                              DataCell(QuotationRowActions(
                                                quotation: q,
                                                onView: q.id == null
                                                    ? null
                                                    : () => context
                                                        .go('/quotations/${q.id}'),
                                                onEdit: q.id == null
                                                    ? null
                                                    : () => _editQuotation(q),
                                                onAddFromCatalog: q.id == null
                                                    ? null
                                                    : () =>
                                                        _openCatalogPicker(q),
                                                onSend: () => _sendQuotation(q),
                                                onAccept: () =>
                                                    _acceptQuotation(q),
                                                onReject: () =>
                                                    _rejectQuotation(q),
                                                onPreviewPdf: q.id == null
                                                    ? null
                                                    : () => _previewPdf(q),
                                                onDownloadPdf: q.id == null
                                                    ? null
                                                    : () => _downloadPdf(q),
                                                onDelete: () =>
                                                    _deleteQuotation(q),
                                              )),
                                            ],
                                          )).toList(),
                                        ),
                                      ),
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

  Future<void> _openCatalogPicker(LeadQuotation q) async {
    if (q.id == null) return;
    await showDialog<void>(
      context: context,
      builder: (_) => QuotationCatalogPickerDialog(
        quotationId: q.id!,
        onItemAdded: (_) {
          // No detail screen on this list — give the user a hint to open the
          // quotation to see updated totals (acceptance criterion in the spec).
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Item added — open quotation to view'),
                backgroundColor: successColor,
              ),
            );
          }
        },
        onAddCustomRequested: () {
          // No existing custom-item form on this screen; surface a hint.
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                    'Open the quotation in the lead detail to add a custom item'),
              ),
            );
          }
        },
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
        ErrorHandler.showErrorSnackBar(context, e);
      }
    }
  }

  /// Show a lead picker — when a lead is chosen, push the existing
  /// AddQuotationScreen so the user can fill title / validity / items.
  /// On return, refresh the quotations list.
  Future<void> _openLeadPickerForNewQuotation() async {
    final leadService = LeadService();
    List<Lead> leads = const [];
    String? loadError;
    try {
      leads = await leadService.getAllLeads();
    } catch (e) {
      loadError = e.toString();
    }
    if (!mounted) return;

    final picked = await showDialog<Lead>(
      context: context,
      builder: (ctx) {
        final searchCtrl = TextEditingController();
        String query = '';
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            final filtered = query.isEmpty
                ? leads
                : leads.where((l) {
                    final hay = '${l.name} ${l.email} ${l.phone}'.toLowerCase();
                    return hay.contains(query.toLowerCase());
                  }).toList();
            return Dialog(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600, maxHeight: 600),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.request_quote_outlined,
                              color: primaryColor, size: 26),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text('New Quotation',
                                style: Theme.of(ctx)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(fontWeight: FontWeight.bold)),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Pick the lead this quotation is for. The next screen '
                        'lets you fill title, validity and line items.',
                        style: TextStyle(color: Colors.black54, fontSize: 13),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: searchCtrl,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.search, size: 20),
                          hintText: 'Search by name, email or phone',
                          border: OutlineInputBorder(),
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                        ),
                        onChanged: (v) => setLocal(() => query = v),
                      ),
                      const Divider(height: 24),
                      Expanded(
                        child: loadError != null
                            ? Center(
                                child: Text('Failed to load leads: $loadError',
                                    style: const TextStyle(color: Colors.red)))
                            : filtered.isEmpty
                                ? const Center(
                                    child: Text('No matching leads.',
                                        style:
                                            TextStyle(color: Colors.black54)))
                                : ListView.separated(
                                    itemCount: filtered.length,
                                    separatorBuilder: (_, __) =>
                                        const Divider(height: 1),
                                    itemBuilder: (_, i) {
                                      final l = filtered[i];
                                      return ListTile(
                                        leading: CircleAvatar(
                                          backgroundColor: primaryColor
                                              .withOpacity(0.1),
                                          child: const Icon(Icons.person,
                                              color: primaryColor),
                                        ),
                                        title: Text(
                                          l.name.isNotEmpty
                                              ? l.name
                                              : 'Lead #${l.leadId}',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w600),
                                        ),
                                        subtitle: Text(
                                          [
                                            if (l.email.isNotEmpty) l.email,
                                            if (l.phone.isNotEmpty) l.phone,
                                          ].join('  ·  '),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        trailing: const Icon(
                                            Icons.arrow_forward_ios,
                                            size: 16),
                                        onTap: () => Navigator.pop(ctx, l),
                                      );
                                    },
                                  ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    if (picked != null && mounted) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => AddQuotationScreen(lead: picked),
        ),
      );
      _loadQuotations();
    }
  }

  Future<void> _editQuotation(LeadQuotation q) async {
    if (q.id == null) return;
    // Need the parent lead to push the AddQuotationScreen edit flow.
    Lead lead;
    try {
      lead = await LeadService().getLeadById(q.leadId.toString());
    } catch (e) {
      if (mounted) {
        ErrorHandler.showErrorSnackBar(context, e);
      }
      return;
    }
    if (!mounted) return;
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) =>
            AddQuotationScreen(lead: lead, quotationToEdit: q),
      ),
    );
    if (saved == true) {
      _loadQuotations();
    }
  }

  Future<void> _acceptQuotation(LeadQuotation q) async {
    if (q.id == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Accept Quotation'),
        content: Text(
            'Mark quotation ${q.quotationNumber ?? q.title} as accepted?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: successColor, foregroundColor: Colors.white),
            child: const Text('Accept'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _quotationService.acceptQuotation(q.id!);
      _loadQuotations();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Quotation accepted'),
              backgroundColor: successColor),
        );
      }
    } catch (e) {
      if (mounted) ErrorHandler.showErrorSnackBar(context, e);
    }
  }

  Future<void> _rejectQuotation(LeadQuotation q) async {
    if (q.id == null) return;
    final reasonCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject Quotation'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Reject quotation ${q.quotationNumber ?? q.title}?'),
            const SizedBox(height: 12),
            TextField(
              controller: reasonCtrl,
              decoration: const InputDecoration(
                labelText: 'Reason (optional)',
                border: OutlineInputBorder(),
              ),
              minLines: 2,
              maxLines: 4,
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: errorColor, foregroundColor: Colors.white),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _quotationService.rejectQuotation(
        q.id!,
        reason: reasonCtrl.text.trim().isEmpty ? null : reasonCtrl.text.trim(),
      );
      _loadQuotations();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Quotation rejected'),
              backgroundColor: warningColor),
        );
      }
    } catch (e) {
      if (mounted) ErrorHandler.showErrorSnackBar(context, e);
    }
  }

  /// Open a fullscreen PDF preview for [q] using the printing package.
  /// `PdfPreview.build` lazily fetches the bytes when first rendered.
  Future<void> _previewPdf(LeadQuotation q) async {
    if (q.id == null) return;
    final id = q.id!;
    final number = q.quotationNumber ?? 'Quotation';
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (ctx) => Scaffold(
          appBar: AppBar(
            title: Text('Preview - $number'),
            leading: IconButton(
              icon: const Icon(Icons.close),
              tooltip: 'Close',
              onPressed: () => Navigator.of(ctx).pop(),
            ),
          ),
          body: PdfPreview(
            build: (_) async => await _quotationService.downloadQuotationPdf(id),
            allowPrinting: true,
            allowSharing: true,
            canChangePageFormat: false,
            canChangeOrientation: false,
            canDebug: false,
          ),
        ),
      ),
    );
  }

  Future<void> _downloadPdf(LeadQuotation q) async {
    if (q.id == null) return;
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const Center(child: CircularProgressIndicator()),
      );
      final bytes = await _quotationService.downloadQuotationPdf(q.id!);
      final filename =
          'Quotation_${q.quotationNumber?.replaceAll("/", "_") ?? q.id}.pdf';
      if (mounted) {
        Navigator.of(context).pop();
      }
      if (mounted) {
        await FileDownloadHelper.downloadAndShareFile(
          bytes: bytes,
          fileName: filename,
          mimeType: 'application/pdf',
          shareText: 'Quotation - ${q.quotationNumber}',
        );
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('PDF downloaded'),
              backgroundColor: successColor),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        ErrorHandler.showErrorSnackBar(context, e);
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
          ErrorHandler.showErrorSnackBar(context, e);
        }
      }
    }
  }
}
