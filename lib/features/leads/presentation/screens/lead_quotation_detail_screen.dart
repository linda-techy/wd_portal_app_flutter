import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:admin/features/leads/data/models/lead_quotation.dart';
import 'package:admin/features/leads/data/services/lead_quotation_service.dart';
import 'package:admin/features/quotation_catalog/data/models/quotation_catalog_item.dart';
import 'package:admin/features/quotation_catalog/presentation/screens/promote_to_catalog_dialog.dart';
import 'package:admin/theme/app_theme.dart';
import 'package:admin/providers/permission_provider.dart';
import 'package:admin/utils/motion_toast.dart';
import 'package:admin/utils/error_handler.dart';
import 'package:admin/utils/file_download_helper.dart';
import 'package:admin/features/leads/data/services/lead_service.dart';
import 'add_quotation_screen.dart';

class LeadQuotationDetailScreen extends StatefulWidget {
  final int quotationId;

  const LeadQuotationDetailScreen({super.key, required this.quotationId});

  @override
  State<LeadQuotationDetailScreen> createState() =>
      _LeadQuotationDetailScreenState();
}

class _LeadQuotationDetailScreenState extends State<LeadQuotationDetailScreen> {
  final LeadQuotationService _service = LeadQuotationService();
  LeadQuotation? _quotation;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadQuotation();
  }

  Future<void> _loadQuotation() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final quotation = await _service.getQuotationById(widget.quotationId);
      setState(() {
        _quotation = quotation;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
        await ErrorHandler.handleApiError(context, e,
            defaultMessage: 'Failed to load quotation');
      }
    }
  }

  Future<void> _sendQuotation() async {
    if (_quotation == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Send Quotation'),
        content: Text(
            'Are you sure you want to send "${_quotation!.quotationNumber}" to the lead?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Send'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await _service.sendQuotation(_quotation!.id!);
        if (mounted) {
          MotionToast.showSuccess(context,
              message: 'Quotation sent successfully');
          _loadQuotation();
        }
      } catch (e) {
        if (mounted) {
          await ErrorHandler.handleApiError(context, e,
              defaultMessage: 'Failed to send quotation');
        }
      }
    }
  }

  Future<void> _acceptQuotation() async {
    if (_quotation == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Accept Quotation'),
        content: Text('Mark "${_quotation!.quotationNumber}" as accepted?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Accept'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await _service.acceptQuotation(_quotation!.id!);
        if (mounted) {
          MotionToast.showSuccess(context, message: 'Quotation accepted');
          _loadQuotation();
        }
      } catch (e) {
        if (mounted) {
          await ErrorHandler.handleApiError(context, e,
              defaultMessage: 'Failed to accept quotation');
        }
      }
    }
  }

  Future<void> _rejectQuotation() async {
    if (_quotation == null) return;

    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject Quotation'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter rejection reason (optional):'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                hintText: 'Reason for rejection',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await _service.rejectQuotation(_quotation!.id!,
            reason: reasonController.text.isNotEmpty
                ? reasonController.text
                : null);
        if (mounted) {
          MotionToast.showSuccess(context, message: 'Quotation rejected');
          _loadQuotation();
        }
      } catch (e) {
        if (mounted) {
          await ErrorHandler.handleApiError(context, e,
              defaultMessage: 'Failed to reject quotation');
        }
      }
    }
  }

  Future<void> _deleteQuotation() async {
    if (_quotation == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Quotation'),
        content: Text(
            'Are you sure you want to delete "${_quotation!.quotationNumber}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await _service.deleteQuotation(_quotation!.id!);
        if (mounted) {
          MotionToast.showSuccess(context, message: 'Quotation deleted');
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          await ErrorHandler.handleApiError(context, e,
              defaultMessage: 'Failed to delete quotation');
        }
      }
    }
  }

  /// Show the rendered PDF inline in a fullscreen modal. Uses
  /// [LeadQuotationService.downloadQuotationPdf] which already returns
  /// raw bytes — `PdfPreview.build` renders them without re-fetching.
  Future<void> _previewPdf() async {
    if (_quotation == null) return;
    final id = _quotation!.id;
    if (id == null) return;
    final number = _quotation!.quotationNumber ?? 'Quotation';
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
            build: (_) async => await _service.downloadQuotationPdf(id),
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

  Future<void> _downloadPdf() async {
    if (_quotation == null) return;

    bool loaderOpen = false;
    if (mounted) {
      loaderOpen = true;
      // Fire-and-forget: dialog future resolves when popped.
      // ignore: unawaited_futures
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        useRootNavigator: true,
        builder: (ctx) => const Center(child: CircularProgressIndicator()),
      ).whenComplete(() => loaderOpen = false);
    }

    void closeLoader() {
      if (loaderOpen && mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        loaderOpen = false;
      }
    }

    try {
      final bytes = await _service.downloadQuotationPdf(_quotation!.id!);
      final filename =
          'Quotation_${_quotation!.quotationNumber?.replaceAll("/", "_") ?? _quotation!.id}.pdf';

      // Close loader before triggering the browser save dialog so the spinner
      // doesn't sit on top of the download UX.
      closeLoader();

      if (mounted) {
        await FileDownloadHelper.downloadAndShareFile(
          bytes: bytes,
          fileName: filename,
          mimeType: 'application/pdf',
          shareText: 'Quotation - ${_quotation!.quotationNumber}',
        );
      }
      if (mounted) {
        MotionToast.showSuccess(context,
            message: 'PDF downloaded successfully');
      }
    } catch (e) {
      closeLoader();
      if (mounted) {
        await ErrorHandler.handleApiError(context, e,
            defaultMessage: 'Failed to download PDF');
      }
    } finally {
      // Defensive: guarantee the loader is always closed even if the success
      // path threw between fetch and `closeLoader()`.
      closeLoader();
    }
  }

  Future<void> _editQuotation() async {
    if (_quotation == null) return;

    // Show loading indicator while fetching lead
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const Center(child: CircularProgressIndicator()),
      );
    }

    try {
      final leadService = LeadService();
      final lead = await leadService.getLeadById(_quotation!.leadId.toString());

      // Close loading dialog
      if (mounted) {
        Navigator.of(context).pop();
      }

      // Navigate to edit screen with fetched lead
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AddQuotationScreen(
              lead: lead,
              quotationToEdit: _quotation,
            ),
          ),
        ).then((result) {
          if (result == true) {
            _loadQuotation();
          }
        });
      }
    } catch (e) {
      // Close loading dialog if still open
      if (mounted) {
        Navigator.of(context).pop();
        await ErrorHandler.handleApiError(context, e,
            defaultMessage: 'Failed to load lead details');
      }
    }
  }

  /// Open the promote-to-catalog dialog for an ad-hoc line item.
  ///
  /// On success the dialog returns the freshly-created [QuotationCatalogItem];
  /// we then refresh the quotation so the row's `catalogItemId` updates and
  /// the "Promote to catalog" menu entry disappears.
  Future<void> _promoteItemToCatalog(LeadQuotationItem item) async {
    if (item.id == null) return;
    final result = await showDialog<QuotationCatalogItem?>(
      context: context,
      builder: (_) => PromoteToCatalogDialog(
        itemId: item.id!,
        sourceDescription: item.description,
        sourceUnitPrice: item.unitPrice,
      ),
    );
    if (!mounted) return;
    if (result != null) {
      MotionToast.showSuccess(
        context,
        message: 'Promoted to catalog (code: ${result.code})',
      );
      _loadQuotation();
    }
  }

  /// Delete a single line item from the quotation by re-saving the quotation
  /// with that row removed. Backend has no per-item delete endpoint, but
  /// `updateQuotation` rebuilds the items collection from the request body
  /// when items are provided.
  Future<void> _deleteLineItem(LeadQuotationItem item) async {
    if (_quotation == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Line Item'),
        content: Text('Remove "${item.description}" from this quotation?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      final remaining = _quotation!.items.where((i) => i.id != item.id).toList();
      // Re-number for tidy display, mirroring backend create flow.
      final renumbered = <LeadQuotationItem>[];
      for (var i = 0; i < remaining.length; i++) {
        final r = remaining[i];
        renumbered.add(LeadQuotationItem(
          id: r.id,
          quotationId: r.quotationId,
          itemNumber: i + 1,
          description: r.description,
          quantity: r.quantity,
          unitPrice: r.unitPrice,
          totalPrice: r.totalPrice,
          notes: r.notes,
          catalogItemId: r.catalogItemId,
        ));
      }
      final updated = _quotation!.copyWith(items: renumbered);
      await _service.updateQuotation(_quotation!.id!, updated);
      if (mounted) {
        MotionToast.showSuccess(context, message: 'Item removed');
        _loadQuotation();
      }
    } catch (e) {
      if (mounted) {
        await ErrorHandler.handleApiError(context, e,
            defaultMessage: 'Failed to remove item');
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'ACCEPTED':
        return AppTheme.statusSuccess;
      case 'SENT':
      case 'VIEWED':
        return Colors.blue;
      case 'DRAFT':
        return Colors.grey;
      case 'REJECTED':
        return AppTheme.statusError;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return DateFormat('dd MMM yyyy, hh:mm a').format(date);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null || _quotation == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Quotation Details')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(_errorMessage ?? 'Quotation not found'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadQuotation,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final quotation = _quotation!;
    final canEdit = quotation.status == 'DRAFT';
    final canSend = quotation.status == 'DRAFT';
    final canAcceptReject =
        quotation.status == 'SENT' || quotation.status == 'VIEWED';

    return Scaffold(
      appBar: AppBar(
        title: Text('Quotation: ${quotation.quotationNumber}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.visibility_outlined),
            tooltip: 'Preview PDF',
            onPressed: _previewPdf,
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Download PDF',
            onPressed: _downloadPdf,
          ),
          Consumer<PermissionProvider>(
            builder: (context, permissionProvider, _) {
              if (!permissionProvider.hasPermission('lead:edit')) {
                return const SizedBox.shrink();
              }
              return PopupMenuButton<String>(
                onSelected: (value) {
                  switch (value) {
                    case 'edit':
                      _editQuotation();
                      break;
                    case 'send':
                      _sendQuotation();
                      break;
                    case 'accept':
                      _acceptQuotation();
                      break;
                    case 'reject':
                      _rejectQuotation();
                      break;
                    case 'delete':
                      _deleteQuotation();
                      break;
                  }
                },
                itemBuilder: (context) => [
                  if (canEdit)
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(children: [
                        Icon(Icons.edit, size: 20),
                        SizedBox(width: 8),
                        Text('Edit')
                      ]),
                    ),
                  if (canSend)
                    const PopupMenuItem(
                      value: 'send',
                      child: Row(children: [
                        Icon(Icons.send, size: 20),
                        SizedBox(width: 8),
                        Text('Send')
                      ]),
                    ),
                  if (canAcceptReject) ...[
                    const PopupMenuItem(
                      value: 'accept',
                      child: Row(children: [
                        Icon(Icons.check_circle, size: 20, color: Colors.green),
                        SizedBox(width: 8),
                        Text('Accept')
                      ]),
                    ),
                    const PopupMenuItem(
                      value: 'reject',
                      child: Row(children: [
                        Icon(Icons.cancel, size: 20, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Reject')
                      ]),
                    ),
                  ],
                  if (canEdit)
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(children: [
                        Icon(Icons.delete, size: 20, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Delete')
                      ]),
                    ),
                ],
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                quotation.title,
                                style: const TextStyle(
                                    fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Quotation #${quotation.quotationNumber}',
                                style: TextStyle(
                                    fontSize: 14, color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _getStatusColor(quotation.status),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            quotation.status,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    if (quotation.description != null &&
                        quotation.description!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(quotation.description!),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Details Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Details',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    _buildDetailRow('Lead ID', quotation.leadId.toString()),
                    _buildDetailRow('Version', quotation.version.toString()),
                    _buildDetailRow(
                        'Validity', '${quotation.validityDays} days'),
                    _buildDetailRow(
                        'Created', _formatDate(quotation.createdAt)),
                    if (quotation.sentAt != null)
                      _buildDetailRow('Sent', _formatDate(quotation.sentAt)),
                    if (quotation.viewedAt != null)
                      _buildDetailRow(
                          'Viewed', _formatDate(quotation.viewedAt)),
                    if (quotation.respondedAt != null)
                      _buildDetailRow(
                          'Responded', _formatDate(quotation.respondedAt)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Line Items Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Line Items',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    if (quotation.items.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Center(
                            child: Text('No items',
                                style: TextStyle(color: Colors.grey))),
                      )
                    else
                      Table(
                        defaultVerticalAlignment:
                            TableCellVerticalAlignment.middle,
                        columnWidths: const {
                          0: FlexColumnWidth(1),
                          1: FlexColumnWidth(2),
                          2: FlexColumnWidth(1),
                          3: FlexColumnWidth(1),
                          4: FlexColumnWidth(1.5),
                          5: FixedColumnWidth(48),
                        },
                        children: [
                          const TableRow(
                            children: [
                              Padding(
                                  padding: EdgeInsets.all(8),
                                  child: Text('Item',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold))),
                              Padding(
                                  padding: EdgeInsets.all(8),
                                  child: Text('Description',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold))),
                              Padding(
                                  padding: EdgeInsets.all(8),
                                  child: Text('Qty',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold))),
                              Padding(
                                  padding: EdgeInsets.all(8),
                                  child: Text('Unit Price',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold))),
                              Padding(
                                  padding: EdgeInsets.all(8),
                                  child: Text('Total',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold))),
                              SizedBox.shrink(),
                            ],
                          ),
                          ...quotation.items.map((item) => TableRow(
                                children: [
                                  Padding(
                                      padding: const EdgeInsets.all(8),
                                      child: Text(item.itemNumber.toString())),
                                  Padding(
                                      padding: const EdgeInsets.all(8),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(item.description),
                                          const SizedBox(height: 4),
                                          _buildSourcePill(
                                              item.catalogItemId != null),
                                        ],
                                      )),
                                  Padding(
                                      padding: const EdgeInsets.all(8),
                                      child: Text(
                                          item.quantity.toStringAsFixed(2))),
                                  Padding(
                                      padding: const EdgeInsets.all(8),
                                      child: Text(_formatINR(item.unitPrice))),
                                  Padding(
                                      padding: const EdgeInsets.all(8),
                                      child: Text(
                                          _formatINR(item.totalPrice),
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold))),
                                  _buildItemActionsMenu(quotation, item),
                                ],
                              )),
                        ],
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Amounts Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Amounts',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    _buildAmountRow('Subtotal', quotation.totalAmount),
                    if (quotation.taxAmount != null && quotation.taxAmount! > 0)
                      _buildAmountRow('Tax', quotation.taxAmount),
                    if (quotation.discountAmount != null &&
                        quotation.discountAmount! > 0)
                      _buildAmountRow('Discount', quotation.discountAmount,
                          isDiscount: true),
                    const Divider(),
                    _buildAmountRow('Final Amount', quotation.finalAmount,
                        isTotal: true),
                  ],
                ),
              ),
            ),
            if (quotation.notes != null && quotation.notes!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Notes',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      Text(quotation.notes!),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Per-row action menu for a line item.
  ///
  /// - **Edit** / **Delete** — only when the quotation is still DRAFT.
  ///   Edit defers to the existing whole-quotation edit screen (no per-item
  ///   inline edit endpoint exists). Delete uses `updateQuotation` with the
  ///   row filtered out (backend has no per-item delete endpoint).
  /// - **Promote to catalog** — only when the row is ad-hoc
  ///   (`catalogItemId == null`) and the user has either `lead:edit` or
  ///   `QUOTATION_CATALOG_MANAGE` permission.
  Widget _buildItemActionsMenu(LeadQuotation quotation, LeadQuotationItem item) {
    return Consumer<PermissionProvider>(
      builder: (context, perms, _) {
        final isDraft = quotation.status == 'DRAFT';
        final canPromote = item.catalogItemId == null &&
            (perms.hasPermission('lead:edit') ||
                perms.hasPermission('QUOTATION_CATALOG_MANAGE'));

        final entries = <PopupMenuEntry<String>>[];
        if (isDraft) {
          entries.add(const PopupMenuItem<String>(
            value: 'edit',
            child: Row(children: [
              Icon(Icons.edit, size: 18),
              SizedBox(width: 8),
              Text('Edit'),
            ]),
          ));
        }
        if (canPromote) {
          entries.add(const PopupMenuItem<String>(
            value: 'promote',
            child: Row(children: [
              Icon(Icons.inventory_2_outlined,
                  size: 18, color: AppTheme.primaryColor),
              SizedBox(width: 8),
              Text('Promote to catalog'),
            ]),
          ));
        }
        if (isDraft) {
          entries.add(const PopupMenuItem<String>(
            value: 'delete',
            child: Row(children: [
              Icon(Icons.delete, size: 18, color: Colors.red),
              SizedBox(width: 8),
              Text('Delete'),
            ]),
          ));
        }

        if (entries.isEmpty) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, size: 18),
            tooltip: 'Actions',
            padding: EdgeInsets.zero,
            onSelected: (value) {
              switch (value) {
                case 'edit':
                  _editQuotation();
                  break;
                case 'promote':
                  _promoteItemToCatalog(item);
                  break;
                case 'delete':
                  _deleteLineItem(item);
                  break;
              }
            },
            itemBuilder: (_) => entries,
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildAmountRow(String label, double? amount,
      {bool isDiscount = false, bool isTotal = false}) {
    if (amount == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: isTotal ? 16 : 14,
                  fontWeight: isTotal ? FontWeight.bold : FontWeight.normal)),
          Text(
            '${isDiscount ? '-' : ''}${_formatINR(amount)}',
            style: TextStyle(
              fontSize: isTotal ? 18 : 14,
              fontWeight: FontWeight.bold,
              color: isTotal ? AppTheme.primaryColor : null,
            ),
          ),
        ],
      ),
    );
  }

  static final NumberFormat _inr =
      NumberFormat.currency(locale: 'en_IN', symbol: '\u20B9', decimalDigits: 2);

  String _formatINR(num? amount) =>
      amount == null ? '' : _inr.format(amount);

  Widget _buildSourcePill(bool fromCatalog) {
    final label = fromCatalog ? 'Catalog' : 'Custom';
    final bg = fromCatalog ? Colors.blue.shade50 : Colors.grey.shade200;
    final fg = fromCatalog ? Colors.blue.shade700 : Colors.grey.shade700;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
            fontSize: 11, color: fg, fontWeight: FontWeight.w600),
      ),
    );
  }
}
