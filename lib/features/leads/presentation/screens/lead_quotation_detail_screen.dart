import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:admin/features/leads/data/models/lead_quotation.dart';
import 'package:admin/features/leads/data/services/lead_quotation_service.dart';
import 'package:admin/features/leads/data/models/lead.dart';
import 'package:admin/theme/app_theme.dart';
import 'package:admin/providers/permission_provider.dart';
import 'package:admin/utils/motion_toast.dart';
import 'package:admin/core/errors/error_handler.dart';
import 'add_quotation_screen.dart';

class LeadQuotationDetailScreen extends StatefulWidget {
  final int quotationId;

  const LeadQuotationDetailScreen({super.key, required this.quotationId});

  @override
  State<LeadQuotationDetailScreen> createState() => _LeadQuotationDetailScreenState();
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
        await ErrorHandler.handleApiError(context, e, defaultMessage: 'Failed to load quotation');
      }
    }
  }

  Future<void> _sendQuotation() async {
    if (_quotation == null) return;
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Send Quotation'),
        content: Text('Are you sure you want to send "${_quotation!.quotationNumber}" to the lead?'),
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
          MotionToast.showSuccess(context, message: 'Quotation sent successfully');
          _loadQuotation();
        }
      } catch (e) {
        if (mounted) {
          await ErrorHandler.handleApiError(context, e, defaultMessage: 'Failed to send quotation');
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
          await ErrorHandler.handleApiError(context, e, defaultMessage: 'Failed to accept quotation');
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
        await _service.rejectQuotation(_quotation!.id!, reason: reasonController.text.isNotEmpty ? reasonController.text : null);
        if (mounted) {
          MotionToast.showSuccess(context, message: 'Quotation rejected');
          _loadQuotation();
        }
      } catch (e) {
        if (mounted) {
          await ErrorHandler.handleApiError(context, e, defaultMessage: 'Failed to reject quotation');
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
        content: Text('Are you sure you want to delete "${_quotation!.quotationNumber}"? This action cannot be undone.'),
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
          await ErrorHandler.handleApiError(context, e, defaultMessage: 'Failed to delete quotation');
        }
      }
    }
  }

  void _editQuotation() {
    if (_quotation == null) return;
    
    // Create a minimal Lead object from quotation data
    // In a real scenario, you might want to fetch the full lead
    final lead = Lead(
      leadId: _quotation!.leadId.toString(),
      name: 'Lead ${_quotation!.leadId}', // Placeholder - ideally fetch from API
      email: '',
      phone: '',
      source: LeadSource.website,
      createdAt: DateTime.now(),
      status: '',
      priority: LeadPriority.medium,
      customerType: '',
      projectType: '',
      assignedTeam: '',
      state: '',
      district: '',
      location: '',
      address: '',
      projectDescription: '',
      requirements: '',
    );
    
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
    final canAcceptReject = quotation.status == 'SENT' || quotation.status == 'VIEWED';

    return Scaffold(
      appBar: AppBar(
        title: Text('Quotation: ${quotation.quotationNumber}'),
        actions: [
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
                      child: Row(children: [Icon(Icons.edit, size: 20), SizedBox(width: 8), Text('Edit')]),
                    ),
                  if (canSend)
                    const PopupMenuItem(
                      value: 'send',
                      child: Row(children: [Icon(Icons.send, size: 20), SizedBox(width: 8), Text('Send')]),
                    ),
                  if (canAcceptReject) ...[
                    const PopupMenuItem(
                      value: 'accept',
                      child: Row(children: [Icon(Icons.check_circle, size: 20, color: Colors.green), SizedBox(width: 8), Text('Accept')]),
                    ),
                    const PopupMenuItem(
                      value: 'reject',
                      child: Row(children: [Icon(Icons.cancel, size: 20, color: Colors.red), SizedBox(width: 8), Text('Reject')]),
                    ),
                  ],
                  if (canEdit)
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(children: [Icon(Icons.delete, size: 20, color: Colors.red), SizedBox(width: 8), Text('Delete')]),
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
                                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Quotation #${quotation.quotationNumber}',
                                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _getStatusColor(quotation.status),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            quotation.status,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    if (quotation.description != null && quotation.description!.isNotEmpty) ...[
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
                    const Text('Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    _buildDetailRow('Lead ID', quotation.leadId.toString()),
                    _buildDetailRow('Version', quotation.version.toString()),
                    _buildDetailRow('Validity', '${quotation.validityDays} days'),
                    _buildDetailRow('Created', _formatDate(quotation.createdAt)),
                    if (quotation.sentAt != null)
                      _buildDetailRow('Sent', _formatDate(quotation.sentAt)),
                    if (quotation.viewedAt != null)
                      _buildDetailRow('Viewed', _formatDate(quotation.viewedAt)),
                    if (quotation.respondedAt != null)
                      _buildDetailRow('Responded', _formatDate(quotation.respondedAt)),
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
                    const Text('Line Items', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    if (quotation.items.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Center(child: Text('No items', style: TextStyle(color: Colors.grey))),
                      )
                    else
                      Table(
                        columnWidths: const {
                          0: FlexColumnWidth(1),
                          1: FlexColumnWidth(2),
                          2: FlexColumnWidth(1),
                          3: FlexColumnWidth(1),
                          4: FlexColumnWidth(1.5),
                        },
                        children: [
                          const TableRow(
                            children: [
                              Padding(padding: EdgeInsets.all(8), child: Text('Item', style: TextStyle(fontWeight: FontWeight.bold))),
                              Padding(padding: EdgeInsets.all(8), child: Text('Description', style: TextStyle(fontWeight: FontWeight.bold))),
                              Padding(padding: EdgeInsets.all(8), child: Text('Qty', style: TextStyle(fontWeight: FontWeight.bold))),
                              Padding(padding: EdgeInsets.all(8), child: Text('Unit Price', style: TextStyle(fontWeight: FontWeight.bold))),
                              Padding(padding: EdgeInsets.all(8), child: Text('Total', style: TextStyle(fontWeight: FontWeight.bold))),
                            ],
                          ),
                          ...quotation.items.map((item) => TableRow(
                            children: [
                              Padding(padding: const EdgeInsets.all(8), child: Text(item.itemNumber.toString())),
                              Padding(padding: const EdgeInsets.all(8), child: Text(item.description)),
                              Padding(padding: const EdgeInsets.all(8), child: Text(item.quantity.toStringAsFixed(2))),
                              Padding(padding: const EdgeInsets.all(8), child: Text('₹${item.unitPrice.toStringAsFixed(2)}')),
                              Padding(padding: const EdgeInsets.all(8), child: Text('₹${item.totalPrice.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold))),
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
                    const Text('Amounts', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    _buildAmountRow('Subtotal', quotation.totalAmount),
                    if (quotation.taxAmount != null && quotation.taxAmount! > 0)
                      _buildAmountRow('Tax', quotation.taxAmount),
                    if (quotation.discountAmount != null && quotation.discountAmount! > 0)
                      _buildAmountRow('Discount', quotation.discountAmount, isDiscount: true),
                    const Divider(),
                    _buildAmountRow('Final Amount', quotation.finalAmount, isTotal: true),
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
                      const Text('Notes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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

  Widget _buildAmountRow(String label, double? amount, {bool isDiscount = false, bool isTotal = false}) {
    if (amount == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: isTotal ? 16 : 14, fontWeight: isTotal ? FontWeight.bold : FontWeight.normal)),
          Text(
            '${isDiscount ? '-' : ''}₹${amount.toStringAsFixed(2)}',
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
}
