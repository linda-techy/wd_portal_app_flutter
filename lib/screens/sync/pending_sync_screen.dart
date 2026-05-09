import 'package:admin/data/local/outbox_db.dart';
import 'package:admin/providers/pending_sync_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class PendingSyncScreen extends StatelessWidget {
  const PendingSyncScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Pending Sync'),
          bottom: const TabBar(tabs: [
            Tab(text: 'Queued'),
            Tab(text: 'Issues'),
          ]),
        ),
        body: Consumer<PendingSyncProvider>(
          builder: (context, p, _) => Column(children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(children: [
                ElevatedButton.icon(
                  onPressed: p.isSyncing ? null : () => p.syncNow(),
                  icon: const Icon(Icons.sync),
                  label: Text(p.isSyncing ? 'Syncing...' : 'Sync now'),
                ),
              ]),
            ),
            Expanded(
              child: TabBarView(children: [
                _QueuedList(rows: p.queued),
                _IssuesList(rows: p.issues, onRetry: p.retryPermanent, onDiscard: p.discardPermanent),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

class _QueuedList extends StatelessWidget {
  const _QueuedList({required this.rows});
  final List<OutboxEntry> rows;
  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return const Center(child: Text('All synced — nothing waiting'));
    }
    return ListView.separated(
      itemCount: rows.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (_, i) {
        final r = rows[i];
        return ListTile(
          leading: Icon(_iconFor(r.mutationType)),
          title: Text(r.mutationType),
          subtitle: Text('Project ${r.projectId ?? '-'} · attempts ${r.attempts}'),
          trailing: Text(_attemptedLabel(r)),
        );
      },
    );
  }

  static IconData _iconFor(String t) {
    switch (t) {
      case 'TASK_MARK_COMPLETE':
        return Icons.task_alt;
      case 'SITE_REPORT_CREATE':
        return Icons.photo_camera;
      case 'DELAY_LOG_CREATE':
        return Icons.report_problem;
      default:
        return Icons.cloud_queue;
    }
  }

  static String _attemptedLabel(OutboxEntry r) =>
      r.nextRetryAt == null ? 'pending' : 'next ${r.nextRetryAt!.toLocal()}';
}

class _IssuesList extends StatelessWidget {
  const _IssuesList({required this.rows, required this.onRetry, required this.onDiscard});
  final List<OutboxEntry> rows;
  final Future<void> Function(int) onRetry;
  final Future<void> Function(int) onDiscard;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) return const Center(child: Text('No issues'));
    return ListView.separated(
      itemCount: rows.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (_, i) {
        final r = rows[i];
        return ListTile(
          leading: const Icon(Icons.error_outline, color: Colors.red),
          title: Text(r.mutationType),
          subtitle: Text(r.lastErrorMessage ?? 'Unknown error'),
          trailing: Wrap(spacing: 4, children: [
            TextButton(onPressed: () => onRetry(r.id), child: const Text('Retry')),
            TextButton(onPressed: () => onDiscard(r.id), child: const Text('Discard')),
          ]),
        );
      },
    );
  }
}
