import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:admin/constants.dart';
import 'package:admin/models/dpc/dpc_document.dart';
import 'package:admin/providers/permission_provider.dart';
import 'package:admin/services/dpc_service.dart';
import 'package:admin/utils/error_handler.dart';
import 'package:admin/utils/file_download_helper.dart';

/// Lists every DPC revision belonging to [projectId].
///
/// Each row links back to the live builder (DRAFT) or downloads the
/// rendered PDF (ISSUED). The PDF is fetched via
/// [DpcService.previewPdf], which works for both DRAFT and ISSUED
/// documents (the backend renderer accepts any document id).
class DpcRevisionsScreen extends StatefulWidget {
  final int projectId;
  const DpcRevisionsScreen({super.key, required this.projectId});

  @override
  State<DpcRevisionsScreen> createState() => _DpcRevisionsScreenState();
}

class _DpcRevisionsScreenState extends State<DpcRevisionsScreen> {
  final DpcService _service = DpcService();
  final NumberFormat _inr = NumberFormat.currency(
      locale: 'en_IN', symbol: '\u20B9', decimalDigits: 0);

  List<DpcDocument> _revisions = [];
  bool _loading = true;
  bool _downloading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await _service.listForProject(widget.projectId);
      // Most-recent revision first.
      list.sort((a, b) => b.revisionNumber.compareTo(a.revisionNumber));
      if (!mounted) return;
      setState(() {
        _revisions = list;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = ErrorHandler.getErrorMessage(e);
        _loading = false;
      });
    }
  }

  Future<void> _downloadIssuedPdf(DpcDocument doc) async {
    if (_downloading) return;
    setState(() => _downloading = true);
    try {
      final Uint8List bytes = await _service.previewPdf(doc.id);
      final filename = 'DPC_r${doc.revisionNumber}_${doc.id}.pdf';
      if (!mounted) return;
      await FileDownloadHelper.downloadAndShareFile(
        bytes: bytes,
        fileName: filename,
        mimeType: 'application/pdf',
        shareText: 'DPC revision r${doc.revisionNumber}',
      );
      if (mounted) {
        ErrorHandler.showSuccessSnackBar(context, 'PDF downloaded');
      }
    } catch (e) {
      if (mounted) ErrorHandler.showErrorSnackBar(context, e);
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text('DPC Revisions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _loading ? null : _load,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: errorColor),
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(color: textSecondary)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _load, child: const Text('Retry')),
          ],
        ),
      );
    }
    if (_revisions.isEmpty) {
      final canCreate = context.watch<PermissionProvider>().canCreateDpc;
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.description_outlined,
                size: 48, color: textMuted),
            const SizedBox(height: 8),
            const Text('No DPC revisions for this project yet.',
                style: TextStyle(color: textSecondary)),
            const SizedBox(height: 16),
            if (canCreate)
              ElevatedButton.icon(
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Create first DPC'),
                onPressed: () =>
                    context.go('/dpc/builder/${widget.projectId}'),
              ),
          ],
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(defaultPadding),
      itemCount: _revisions.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (ctx, i) => _revisionCard(_revisions[i]),
    );
  }

  Widget _revisionCard(DpcDocument doc) {
    final isIssued = doc.isIssued;
    final issuedAtText = doc.issuedAt != null
        ? DateFormat('d MMM yyyy, h:mm a').format(doc.issuedAt!)
        : null;
    return Container(
      padding: const EdgeInsets.all(defaultPadding),
      decoration: BoxDecoration(
        color: cardBackground,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: containerBorder),
      ),
      child: Row(
        children: [
          // Revision number chip
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: boxInfo,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: boxBorderInfo),
            ),
            child: Text('r${doc.revisionNumber}',
                style: const TextStyle(
                    color: infoColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14)),
          ),
          const SizedBox(width: 12),
          // Body: status pill + dates + totals
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _statusPill(doc),
                    const SizedBox(width: 8),
                    if (issuedAtText != null)
                      Flexible(
                        child: Text(
                          'Issued $issuedAtText',
                          style: const TextStyle(
                              fontSize: 12, color: textSecondary),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 16,
                  runSpacing: 4,
                  children: [
                    _stat('Original',
                        _inr.format(doc.masterCostSummary.totalOriginal),
                        textSecondary),
                    _stat(
                        'Customized',
                        _inr.format(doc.masterCostSummary.totalCustomized),
                        primaryColor),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Action chip
          if (isIssued)
            ElevatedButton.icon(
              icon: const Icon(Icons.picture_as_pdf, size: 16),
              label: Text(_downloading ? 'Downloading…' : 'Download PDF'),
              onPressed: _downloading ? null : () => _downloadIssuedPdf(doc),
              style: ElevatedButton.styleFrom(
                backgroundColor: successColor,
                foregroundColor: Colors.white,
              ),
            )
          else
            ElevatedButton.icon(
              icon: const Icon(Icons.edit_outlined, size: 16),
              label: const Text('Open builder'),
              onPressed: () =>
                  context.go('/dpc/builder/${widget.projectId}'),
            ),
        ],
      ),
    );
  }

  Widget _statusPill(DpcDocument doc) {
    final isDraft = doc.isDraft;
    final color = isDraft ? warningColor : successColor;
    final bg = isDraft ? boxWarning : boxSuccess;
    final border = isDraft ? boxBorderWarning : boxBorderSuccess;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Text(doc.status.toUpperCase(),
          style: TextStyle(
              color: color, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }

  Widget _stat(String label, String value, Color valueColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 11, color: textSecondary)),
        Text(value,
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color: valueColor,
                fontSize: 13)),
      ],
    );
  }
}
