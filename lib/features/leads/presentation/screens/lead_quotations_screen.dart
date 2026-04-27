import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:admin/features/leads/data/models/lead_quotation.dart';
import 'package:admin/features/leads/data/models/lead.dart';
import 'package:admin/features/leads/data/services/lead_quotation_service.dart';
import 'package:admin/features/leads/presentation/providers/lead_quotation_provider.dart';
import 'package:admin/widgets/common/search_bar_widget.dart';
import 'package:admin/screens/quotations/widgets/quotation_row_actions.dart';
import 'package:admin/theme/app_theme.dart';
import 'package:admin/providers/permission_provider.dart';
import 'package:admin/utils/motion_toast.dart';
import 'package:admin/utils/error_handler.dart';
import 'package:admin/utils/file_download_helper.dart';
import 'add_quotation_screen.dart';
import 'lead_quotation_detail_screen.dart';

class LeadQuotationsScreen extends StatelessWidget {
  final Lead? lead;
  final int? leadId;

  /// When true, suppress the screen's own AppBar — used when this widget
  /// is hosted inside a parent's TabBarView (e.g. EditLeadScreen tabs).
  final bool embedded;

  const LeadQuotationsScreen(
      {super.key, this.lead, this.leadId, this.embedded = false});

  Future<void> _downloadPdf(
      BuildContext context, LeadQuotation quotation) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const Center(child: CircularProgressIndicator()),
      );

      final quotationService = LeadQuotationService();
      final bytes = await quotationService.downloadQuotationPdf(quotation.id!);
      final filename =
          'Quotation_${quotation.quotationNumber?.replaceAll("/", "_") ?? quotation.id}.pdf';

      // Close loading dialog
      if (context.mounted) {
        Navigator.of(context).pop(); // Close loading dialog
      }

      // Download and share PDF using cross-platform helper
      if (context.mounted) {
        await FileDownloadHelper.downloadAndShareFile(
          bytes: bytes,
          fileName: filename,
          mimeType: 'application/pdf',
          shareText: 'Quotation - ${quotation.quotationNumber}',
        );
        if (context.mounted) {
          MotionToast.showSuccess(context,
              message: 'PDF downloaded successfully');
        }
      }
    } catch (e) {
      // Close loading dialog if still open
      if (context.mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        await ErrorHandler.handleApiError(context, e,
            defaultMessage: 'Failed to download PDF');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) {
        final provider = LeadQuotationProvider();
        // If leadId is provided, filter by that lead
        if (leadId != null) {
          provider.filterByLeadId(leadId);
        }
        provider.fetch();
        return provider;
      },
      child: Consumer<LeadQuotationProvider>(
        builder: (context, provider, _) {
          final body = Column(
            children: [
              if (embedded && lead != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Quotations for ${lead!.name}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      Consumer<PermissionProvider>(
                        builder: (context, permissionProvider, _) {
                          if (permissionProvider.hasPermission('lead:edit')) {
                            return ElevatedButton.icon(
                              icon: const Icon(Icons.add, size: 18),
                              label: const Text('New Quotation'),
                              onPressed: () => _navigateToCreate(context),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ],
                  ),
                ),
              _buildSearchAndFilters(context, provider),
              Expanded(child: _buildQuotationList(context, provider)),
              if (provider.totalPages > 1)
                _buildPagination(context, provider),
            ],
          );

          if (embedded) {
            return body;
          }
          return Scaffold(
            appBar: AppBar(
              title: Text(lead != null
                  ? 'Quotations: ${lead!.name}'
                  : 'Lead Quotations'),
              actions: [
                Consumer<PermissionProvider>(
                  builder: (context, permissionProvider, _) {
                    if (permissionProvider.hasPermission('lead:edit') &&
                        lead != null) {
                      return IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () => _navigateToCreate(context),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ],
            ),
            body: body,
          );
        },
      ),
    );
  }

  Widget _buildSearchAndFilters(
      BuildContext context, LeadQuotationProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[100],
      child: Column(
        children: [
          SearchBarWidget(
            onSearch: (query) => provider.search(query),
            hintText: 'Search lead quotations...',
          ),
          const SizedBox(height: 12),
          _buildFilterChips(context, provider),
        ],
      ),
    );
  }

  Widget _buildFilterChips(
      BuildContext context, LeadQuotationProvider provider) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildFilterChip(
          context,
          label: 'All',
          isSelected: provider.filters['status'] == null,
          onTap: () => provider.clearFilters(),
        ),
        _buildFilterChip(
          context,
          label: 'Draft',
          isSelected: provider.filters['status'] == 'DRAFT',
          onTap: () => provider.updateFilter('status', 'DRAFT'),
          color: Colors.grey,
        ),
        _buildFilterChip(
          context,
          label: 'Sent',
          isSelected: provider.filters['status'] == 'SENT',
          onTap: () => provider.updateFilter('status', 'SENT'),
          color: Colors.blue,
        ),
        _buildFilterChip(
          context,
          label: 'Accepted',
          isSelected: provider.filters['status'] == 'ACCEPTED',
          onTap: () => provider.updateFilter('status', 'ACCEPTED'),
          color: AppTheme.statusSuccess,
        ),
        _buildFilterChip(
          context,
          label: 'Rejected',
          isSelected: provider.filters['status'] == 'REJECTED',
          onTap: () => provider.updateFilter('status', 'REJECTED'),
          color: AppTheme.statusError,
        ),
      ],
    );
  }

  Widget _buildFilterChip(
    BuildContext context, {
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    Color? color,
  }) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
      backgroundColor: color?.withOpacity(0.1),
      selectedColor: color ?? Theme.of(context).primaryColor,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : (color ?? Colors.black87),
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildQuotationList(
      BuildContext context, LeadQuotationProvider provider) {
    if (provider.isLoading && provider.items.isEmpty) {
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
              onPressed: () => provider.fetch(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (provider.items.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.description, size: 48, color: Colors.grey),
            SizedBox(height: 16),
            Text('No lead quotations found', style: TextStyle(fontSize: 16)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => provider.fetch(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: provider.items.length,
        itemBuilder: (context, index) {
          final quotation = provider.items[index];
          return _buildQuotationCard(context, quotation);
        },
      ),
    );
  }

  Widget _buildQuotationCard(BuildContext context, LeadQuotation quotation) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: () => _navigateToDetail(context, quotation),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          quotation.quotationNumber ?? 'N/A',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Lead ID: ${quotation.leadId}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusBadge(quotation.status),
                  QuotationRowActions(
                    quotation: quotation,
                    onView: () => _navigateToDetail(context, quotation),
                    onEdit: lead != null
                        ? () => _editQuotation(context, quotation)
                        : null,
                    // Add-from-catalog requires a quotation detail context;
                    // surface a hint pointing the user to the detail screen.
                    onAddFromCatalog: () => _hintOpenDetail(context),
                    onSend: () => _sendQuotation(context, quotation),
                    onAccept: () => _acceptQuotation(context, quotation),
                    onReject: () => _rejectQuotation(context, quotation),
                    onPreviewPdf: () => _previewPdf(context, quotation),
                    onDownloadPdf: () => _downloadPdf(context, quotation),
                    onDelete: () => _deleteQuotation(context, quotation),
                  ),
                ],
              ),
              if (quotation.description != null &&
                  quotation.description!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  quotation.description!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  if (quotation.createdAt != null)
                    _buildInfoChip(
                      icon: Icons.calendar_today,
                      label: _formatDate(quotation.createdAt!),
                    ),
                  if (quotation.totalAmount != null)
                    _buildInfoChip(
                      icon: Icons.currency_rupee,
                      label: '₹${quotation.totalAmount!.toStringAsFixed(2)}',
                      color: AppTheme.statusSuccess,
                    ),
                  if (quotation.items.isNotEmpty)
                    _buildInfoChip(
                      icon: Icons.list,
                      label: '${quotation.items.length} item(s)',
                      color: Colors.blue,
                    ),
                  if (quotation.createdAt != null)
                    _buildInfoChip(
                      icon: Icons.event_available,
                      label: 'Valid: ${quotation.validityDays} days',
                      color: _getValidityColor(quotation.createdAt!
                          .add(Duration(days: quotation.validityDays))),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getStatusColor(status),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    Color? color,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color ?? Colors.grey[600]),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: color ?? Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildPagination(
      BuildContext context, LeadQuotationProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Page ${provider.currentPage + 1} of ${provider.totalPages}',
            style: const TextStyle(fontSize: 14),
          ),
          Row(
            children: [
              IconButton(
                onPressed: provider.currentPage > 0
                    ? () => provider.goToPage(provider.currentPage - 1)
                    : null,
                icon: const Icon(Icons.chevron_left),
              ),
              IconButton(
                onPressed: provider.currentPage < provider.totalPages - 1
                    ? () => provider.goToPage(provider.currentPage + 1)
                    : null,
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'ACCEPTED':
        return AppTheme.statusSuccess;
      case 'SENT':
        return Colors.blue;
      case 'DRAFT':
        return Colors.grey;
      case 'REJECTED':
        return AppTheme.statusError;
      default:
        return Colors.grey;
    }
  }

  Color _getValidityColor(DateTime date) {
    final now = DateTime.now();
    final diff = date.difference(now).inDays;
    if (diff < 0) return AppTheme.statusError;
    if (diff <= 7) return AppTheme.safetyOrange;
    return Colors.grey;
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _editQuotation(BuildContext context, LeadQuotation quotation) {
    if (lead == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddQuotationScreen(
          lead: lead!,
          quotationToEdit: quotation,
        ),
      ),
    ).then((result) {
      if (result == true && context.mounted) {
        Provider.of<LeadQuotationProvider>(context, listen: false).fetch();
      }
    });
  }

  void _hintOpenDetail(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Open the quotation detail to add items from catalog'),
      ),
    );
  }

  Future<void> _sendQuotation(
      BuildContext context, LeadQuotation quotation) async {
    if (quotation.id == null) return;
    try {
      await LeadQuotationService().sendQuotation(quotation.id!);
      if (context.mounted) {
        Provider.of<LeadQuotationProvider>(context, listen: false).fetch();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Quotation sent'),
              backgroundColor: AppTheme.statusSuccess),
        );
      }
    } catch (e) {
      if (context.mounted) {
        await ErrorHandler.handleApiError(context, e,
            defaultMessage: 'Failed to send quotation');
      }
    }
  }

  Future<void> _acceptQuotation(
      BuildContext context, LeadQuotation quotation) async {
    if (quotation.id == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Accept Quotation'),
        content: Text(
            'Mark quotation ${quotation.quotationNumber ?? quotation.title} as accepted?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.statusSuccess,
                foregroundColor: Colors.white),
            child: const Text('Accept'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await LeadQuotationService().acceptQuotation(quotation.id!);
      if (context.mounted) {
        Provider.of<LeadQuotationProvider>(context, listen: false).fetch();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Quotation accepted'),
              backgroundColor: AppTheme.statusSuccess),
        );
      }
    } catch (e) {
      if (context.mounted) {
        await ErrorHandler.handleApiError(context, e,
            defaultMessage: 'Failed to accept quotation');
      }
    }
  }

  Future<void> _rejectQuotation(
      BuildContext context, LeadQuotation quotation) async {
    if (quotation.id == null) return;
    final reasonCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject Quotation'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
                'Reject quotation ${quotation.quotationNumber ?? quotation.title}?'),
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
                backgroundColor: AppTheme.statusError,
                foregroundColor: Colors.white),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await LeadQuotationService().rejectQuotation(
        quotation.id!,
        reason:
            reasonCtrl.text.trim().isEmpty ? null : reasonCtrl.text.trim(),
      );
      if (context.mounted) {
        Provider.of<LeadQuotationProvider>(context, listen: false).fetch();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Quotation rejected')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        await ErrorHandler.handleApiError(context, e,
            defaultMessage: 'Failed to reject quotation');
      }
    }
  }

  Future<void> _previewPdf(
      BuildContext context, LeadQuotation quotation) async {
    if (quotation.id == null) return;
    final id = quotation.id!;
    final number = quotation.quotationNumber ?? 'Quotation';
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
            build: (_) async =>
                await LeadQuotationService().downloadQuotationPdf(id),
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

  Future<void> _deleteQuotation(
      BuildContext context, LeadQuotation quotation) async {
    if (quotation.id == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Quotation'),
        content: Text(
            'Delete quotation ${quotation.quotationNumber ?? quotation.title}?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.statusError,
                foregroundColor: Colors.white),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await LeadQuotationService().deleteQuotation(quotation.id!);
      if (context.mounted) {
        Provider.of<LeadQuotationProvider>(context, listen: false).fetch();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Quotation deleted')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        await ErrorHandler.handleApiError(context, e,
            defaultMessage: 'Failed to delete quotation');
      }
    }
  }

  void _navigateToDetail(BuildContext context, LeadQuotation quotation) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            LeadQuotationDetailScreen(quotationId: quotation.id!),
      ),
    ).then((_) {
      // Refresh the list when returning from detail screen
      if (context.mounted) {
        final provider =
            Provider.of<LeadQuotationProvider>(context, listen: false);
        provider.fetch();
      }
    });
  }

  void _navigateToCreate(BuildContext context) {
    if (lead == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a lead first')),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddQuotationScreen(lead: lead!),
      ),
    ).then((result) {
      // Refresh the list when returning from create screen
      if (result == true && context.mounted) {
        final provider =
            Provider.of<LeadQuotationProvider>(context, listen: false);
        provider.fetch();
      }
    });
  }
}
