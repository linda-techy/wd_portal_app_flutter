import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:admin/features/leads/data/models/lead_quotation.dart';
import 'package:admin/features/leads/data/models/lead.dart';
import 'package:admin/features/leads/data/services/lead_quotation_service.dart';
import 'package:admin/features/leads/presentation/providers/lead_quotation_provider.dart';
import 'package:admin/widgets/common/search_bar_widget.dart';
import 'package:admin/theme/app_theme.dart';
import 'package:admin/providers/permission_provider.dart';
import 'package:admin/utils/motion_toast.dart';
import 'package:admin/utils/error_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'add_quotation_screen.dart';
import 'lead_quotation_detail_screen.dart';

class LeadQuotationsScreen extends StatelessWidget {
  final Lead? lead;
  final int? leadId;

  const LeadQuotationsScreen({super.key, this.lead, this.leadId});

  Future<void> _downloadPdf(BuildContext context, LeadQuotation quotation) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const Center(child: CircularProgressIndicator()),
      );

      final quotationService = LeadQuotationService();
      final bytes = await quotationService.downloadQuotationPdf(quotation.id!);
      final dir = await getTemporaryDirectory();
      final filename = 'Quotation_${quotation.quotationNumber?.replaceAll("/", "_") ?? quotation.id}.pdf';
      final file = File('${dir.path}/$filename');
      await file.writeAsBytes(bytes);

      // Close loading dialog
      if (context.mounted) {
        Navigator.of(context).pop(); // Close loading dialog
      }

      // Share/download PDF
      if (context.mounted) {
        await Share.shareXFiles(
          [XFile(file.path)],
          text: 'Quotation - ${quotation.quotationNumber}',
        );
        MotionToast.showSuccess(context, message: 'PDF downloaded successfully');
      }
    } catch (e) {
      // Close loading dialog if still open
      if (context.mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        await ErrorHandler.handleApiError(context, e, defaultMessage: 'Failed to download PDF');
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
          return Scaffold(
            appBar: AppBar(
              title: Text(lead != null ? 'Quotations: ${lead!.name}' : 'Lead Quotations'),
              actions: [
                Consumer<PermissionProvider>(
                  builder: (context, permissionProvider, _) {
                    if (permissionProvider.hasPermission('lead:edit') && lead != null) {
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
            body: Column(
              children: [
                _buildSearchAndFilters(context, provider),
                Expanded(child: _buildQuotationList(context, provider)),
                if (provider.totalPages > 1)
                  _buildPagination(context, provider),
              ],
            ),
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
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert),
                    onSelected: (value) {
                      if (value == 'view') {
                        _navigateToDetail(context, quotation);
                      } else if (value == 'edit' && quotation.status == 'DRAFT') {
                        if (lead != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AddQuotationScreen(
                                lead: lead!,
                                quotationToEdit: quotation,
                              ),
                            ),
                          ).then((result) {
                            if (result == true) {
                              final provider = Provider.of<LeadQuotationProvider>(context, listen: false);
                              provider.fetch();
                            }
                          });
                        }
                      } else if (value == 'pdf') {
                        _downloadPdf(context, quotation);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'view',
                        child: Row(children: [Icon(Icons.visibility, size: 20), SizedBox(width: 8), Text('View Details')]),
                      ),
                      const PopupMenuItem(
                        value: 'pdf',
                        child: Row(children: [Icon(Icons.picture_as_pdf, size: 20, color: Colors.red), SizedBox(width: 8), Text('Export PDF', style: TextStyle(color: Colors.red))]),
                      ),
                      if (quotation.status == 'DRAFT' && lead != null)
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(children: [Icon(Icons.edit, size: 20), SizedBox(width: 8), Text('Edit')]),
                        ),
                    ],
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

  void _navigateToDetail(BuildContext context, LeadQuotation quotation) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LeadQuotationDetailScreen(quotationId: quotation.id!),
      ),
    ).then((_) {
      // Refresh the list when returning from detail screen
      final provider = Provider.of<LeadQuotationProvider>(context, listen: false);
      provider.fetch();
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
      if (result == true) {
        final provider = Provider.of<LeadQuotationProvider>(context, listen: false);
        provider.fetch();
      }
    });
  }
}
