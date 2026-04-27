import 'package:flutter/material.dart';

import 'package:admin/features/leads/data/models/lead_quotation.dart';

/// Status-aware popup-menu of per-row actions for a quotation.
///
/// Both `quotations_screen.dart` (global) and `lead_quotations_screen.dart`
/// (per-lead) share this widget so that the action set, order, and gating
/// stay aligned. Each callback may be `null`; null callbacks hide the entry
/// (rather than disabling it). All actions defined here:
///
/// * **View** — always visible (when `onView` provided).
/// * **Edit** — DRAFT only.
/// * **Add from catalog** — DRAFT only.
/// * **Send** — DRAFT only.
/// * **Accept** — SENT only.
/// * **Reject** — SENT only.
/// * **PDF Preview** — always.
/// * **PDF Download** — always.
/// * **Delete** — DRAFT only.
class QuotationRowActions extends StatelessWidget {
  final LeadQuotation quotation;

  final VoidCallback? onView;
  final VoidCallback? onEdit;
  final VoidCallback? onAddFromCatalog;
  final VoidCallback? onSend;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;
  final VoidCallback? onPreviewPdf;
  final VoidCallback? onDownloadPdf;
  final VoidCallback? onDelete;

  const QuotationRowActions({
    super.key,
    required this.quotation,
    this.onView,
    this.onEdit,
    this.onAddFromCatalog,
    this.onSend,
    this.onAccept,
    this.onReject,
    this.onPreviewPdf,
    this.onDownloadPdf,
    this.onDelete,
  });

  bool get _isDraft => quotation.status.toUpperCase() == 'DRAFT';
  bool get _isSent => quotation.status.toUpperCase() == 'SENT';

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert),
      tooltip: 'Actions',
      onSelected: (value) {
        switch (value) {
          case 'view':
            onView?.call();
            break;
          case 'edit':
            onEdit?.call();
            break;
          case 'catalog':
            onAddFromCatalog?.call();
            break;
          case 'send':
            onSend?.call();
            break;
          case 'accept':
            onAccept?.call();
            break;
          case 'reject':
            onReject?.call();
            break;
          case 'preview':
            onPreviewPdf?.call();
            break;
          case 'download':
            onDownloadPdf?.call();
            break;
          case 'delete':
            onDelete?.call();
            break;
        }
      },
      itemBuilder: (context) => <PopupMenuEntry<String>>[
        if (onView != null)
          const PopupMenuItem(
            value: 'view',
            child: Row(children: [
              Icon(Icons.visibility, size: 18),
              SizedBox(width: 8),
              Text('View'),
            ]),
          ),
        if (_isDraft && onEdit != null)
          const PopupMenuItem(
            value: 'edit',
            child: Row(children: [
              Icon(Icons.edit, size: 18),
              SizedBox(width: 8),
              Text('Edit'),
            ]),
          ),
        if (_isDraft && onAddFromCatalog != null)
          const PopupMenuItem(
            value: 'catalog',
            child: Row(children: [
              Icon(Icons.add_shopping_cart, size: 18),
              SizedBox(width: 8),
              Text('Add from catalog'),
            ]),
          ),
        if (_isDraft && onSend != null)
          const PopupMenuItem(
            value: 'send',
            child: Row(children: [
              Icon(Icons.send, size: 18, color: Colors.blue),
              SizedBox(width: 8),
              Text('Send', style: TextStyle(color: Colors.blue)),
            ]),
          ),
        if (_isSent && onAccept != null)
          const PopupMenuItem(
            value: 'accept',
            child: Row(children: [
              Icon(Icons.check_circle, size: 18, color: Colors.green),
              SizedBox(width: 8),
              Text('Accept', style: TextStyle(color: Colors.green)),
            ]),
          ),
        if (_isSent && onReject != null)
          const PopupMenuItem(
            value: 'reject',
            child: Row(children: [
              Icon(Icons.cancel, size: 18, color: Colors.red),
              SizedBox(width: 8),
              Text('Reject', style: TextStyle(color: Colors.red)),
            ]),
          ),
        if (onPreviewPdf != null)
          const PopupMenuItem(
            value: 'preview',
            child: Row(children: [
              Icon(Icons.preview, size: 18),
              SizedBox(width: 8),
              Text('PDF Preview'),
            ]),
          ),
        if (onDownloadPdf != null)
          const PopupMenuItem(
            value: 'download',
            child: Row(children: [
              Icon(Icons.picture_as_pdf, size: 18, color: Colors.red),
              SizedBox(width: 8),
              Text('PDF Download'),
            ]),
          ),
        if (_isDraft && onDelete != null)
          const PopupMenuItem(
            value: 'delete',
            child: Row(children: [
              Icon(Icons.delete_outline, size: 18, color: Colors.red),
              SizedBox(width: 8),
              Text('Delete', style: TextStyle(color: Colors.red)),
            ]),
          ),
      ],
    );
  }
}
