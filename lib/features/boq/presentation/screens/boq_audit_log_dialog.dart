import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:admin/services/boq_service.dart';
import 'package:admin/theme/app_theme.dart';

/// Modal dialog showing a vertical timeline of audit-log entries for a single
/// BoQ item.
///
/// Each entry is a row with a timestamp, actor, action label, and (optionally)
/// a before -> after diff. The dialog renders three states: loading, empty,
/// and populated. Errors surface as a snackbar on the calling context.
class BoqAuditLogDialog extends StatefulWidget {
  final int itemId;
  final String? itemDescription;

  const BoqAuditLogDialog({
    super.key,
    required this.itemId,
    this.itemDescription,
  });

  @override
  State<BoqAuditLogDialog> createState() => _BoqAuditLogDialogState();
}

class _BoqAuditLogDialogState extends State<BoqAuditLogDialog> {
  final BoqService _service = BoqService();
  final DateFormat _dateFmt = DateFormat('dd MMM yyyy, HH:mm');

  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _entries = const [];

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
      final list = await _service.getBoqItemAuditLog(widget.itemId);
      if (!mounted) return;
      setState(() {
        _entries = list;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load audit log: $e'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
              child: Row(
                children: [
                  const Icon(Icons.history, color: AppTheme.deepSlate),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Audit Log',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        if (widget.itemDescription != null)
                          Text(
                            widget.itemDescription!,
                            style: const TextStyle(
                                fontSize: 12, color: AppTheme.textSecondary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Body
            Flexible(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: CircularProgressIndicator(),
        ),
      );
    }
    if (_error != null && _entries.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline,
                  size: 40, color: AppTheme.errorRed),
              const SizedBox(height: 8),
              const Text('Failed to load audit log',
                  style: TextStyle(color: AppTheme.errorRed)),
              const SizedBox(height: 12),
              ElevatedButton(onPressed: _load, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }
    if (_entries.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: Text(
            'No history yet for this item.',
            style: TextStyle(color: AppTheme.textSecondary),
          ),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      itemCount: _entries.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) => _entryTile(_entries[i]),
    );
  }

  Widget _entryTile(Map<String, dynamic> entry) {
    final ts = entry['timestamp']?.toString() ?? entry['createdAt']?.toString();
    DateTime? when;
    if (ts != null) {
      when = DateTime.tryParse(ts);
    }
    final actor = entry['actorName']?.toString() ??
        entry['userName']?.toString() ??
        (entry['actorId'] != null ? 'User #${entry['actorId']}' : 'System');
    final action = entry['action']?.toString() ??
        entry['actionType']?.toString() ??
        entry['eventType']?.toString() ??
        'CHANGE';
    final before = entry['before'] ?? entry['oldValue'];
    final after = entry['after'] ?? entry['newValue'];
    final field = entry['field']?.toString() ?? entry['fieldName']?.toString();
    final note = entry['note']?.toString() ?? entry['reason']?.toString();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.deepSlate.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  action,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.deepSlate,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  actor,
                  style: const TextStyle(
                      fontWeight: FontWeight.w500, fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (when != null)
                Text(
                  _dateFmt.format(when.toLocal()),
                  style: const TextStyle(
                      fontSize: 11, color: AppTheme.textTertiary),
                ),
            ],
          ),
          if (field != null || before != null || after != null) ...[
            const SizedBox(height: 8),
            _diffRow(field, before, after),
          ],
          if (note != null && note.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              note,
              style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                  fontStyle: FontStyle.italic),
            ),
          ],
        ],
      ),
    );
  }

  Widget _diffRow(String? field, dynamic before, dynamic after) {
    final beforeStr = before?.toString() ?? '—';
    final afterStr = after?.toString() ?? '—';
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (field != null) ...[
          SizedBox(
            width: 90,
            child: Text(
              field,
              style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(width: 8),
        ],
        Expanded(
          child: Text(
            beforeStr,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.errorRed,
              decoration: TextDecoration.lineThrough,
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 6),
          child: Icon(Icons.arrow_forward, size: 14, color: Colors.grey),
        ),
        Expanded(
          child: Text(
            afterStr,
            style: const TextStyle(
                fontSize: 12,
                color: AppTheme.successGreen,
                fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }
}
