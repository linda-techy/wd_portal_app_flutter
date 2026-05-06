import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:admin/features/projects/data/models/pending_approval_row.dart';
import 'package:admin/features/projects/data/services/task_completion_service.dart';
import 'package:admin/features/projects/presentation/widgets/reject_completion_dialog.dart';
import 'package:admin/providers/permission_provider.dart';

class PmApprovalInboxScreen extends StatefulWidget {
  const PmApprovalInboxScreen({super.key});

  @override
  State<PmApprovalInboxScreen> createState() => _PmApprovalInboxScreenState();
}

class _PmApprovalInboxScreenState extends State<PmApprovalInboxScreen> {
  Future<List<PendingApprovalRow>>? _rowsFuture;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Defer the initial fetch until permissions are available — saves a
    // wasted /pending-pm-approval round-trip for users without
    // TASK_COMPLETION_APPROVE (the build() short-circuits to the denied-
    // placeholder before ever rendering the FutureBuilder).
    if (_rowsFuture == null &&
        context.read<PermissionProvider>().canApproveTaskCompletion) {
      _refresh();
    }
  }

  void _refresh() {
    final svc = context.read<TaskCompletionService>();
    setState(() {
      _rowsFuture = svc.pendingApprovalInbox();
    });
  }

  Future<void> _approve(PendingApprovalRow row) async {
    final svc = context.read<TaskCompletionService>();
    await svc.approve(row.taskId);
    if (mounted) _refresh();
  }

  Future<void> _reject(PendingApprovalRow row) async {
    final reason = await RejectCompletionDialog.show(context, row.taskTitle);
    if (reason == null) return;
    if (!mounted) return;
    final svc = context.read<TaskCompletionService>();
    await svc.reject(row.taskId, reason);
    if (mounted) _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final perm = context.watch<PermissionProvider>();
    if (!perm.canApproveTaskCompletion) {
      return Scaffold(
        appBar: AppBar(title: const Text('Approval Inbox')),
        body: const Center(
          child: Text('You are not authorised to approve task completions.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Approval Inbox')),
      body: FutureBuilder<List<PendingApprovalRow>>(
        future: _rowsFuture,
        builder: (c, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));
          final rows = snap.data ?? const [];
          if (rows.isEmpty) {
            return const Center(child: Text('No tasks pending approval.'));
          }
          return RefreshIndicator(
            onRefresh: () async => _refresh(),
            child: ListView.separated(
              itemCount: rows.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (ctx, i) {
                final r = rows[i];
                return ListTile(
                  leading: r.completionPhotoUrl != null
                      ? Image.network(
                          r.completionPhotoUrl!,
                          width: 56,
                          height: 56,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              const Icon(Icons.photo, size: 56),
                        )
                      : const Icon(Icons.photo, size: 56),
                  title: Text(r.taskTitle),
                  subtitle: Text(
                    '${r.projectName} • completed '
                    '${r.markedCompleteOn?.toIso8601String().split('T').first ?? '—'}',
                  ),
                  trailing: Wrap(
                    spacing: 8,
                    children: [
                      OutlinedButton(
                        onPressed: () => _reject(r),
                        child: const Text('Reject'),
                      ),
                      FilledButton(
                        onPressed: () => _approve(r),
                        child: const Text('Approve'),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
