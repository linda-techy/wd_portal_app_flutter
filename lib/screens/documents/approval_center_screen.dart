import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:admin/constants.dart';
import 'package:admin/theme/app_theme.dart';
import 'package:admin/providers/approval_provider.dart';
import 'package:admin/providers/portal_auth_provider.dart';
import 'package:admin/models/approval_models.dart';
import 'package:intl/intl.dart';

class ApprovalCenterScreen extends StatefulWidget {
  const ApprovalCenterScreen({super.key});

  @override
  State<ApprovalCenterScreen> createState() => _ApprovalCenterScreenState();
}

class _ApprovalCenterScreenState extends State<ApprovalCenterScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = context.read<PortalAuthProvider>().user?.id;
      if (userId != null) {
        context.read<ApprovalProvider>().fetchPendingApprovals(userId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Approval Center")),
      body: Consumer<ApprovalProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) return const Center(child: CircularProgressIndicator());
          if (provider.pendingRequests.isEmpty) {
            return const Center(child: Text("No pending approvals"));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: provider.pendingRequests.length,
            itemBuilder: (context, index) {
              final req = provider.pendingRequests[index];
              return _buildApprovalCard(req);
            },
          );
        },
      ),
    );
  }

  Widget _buildApprovalCard(ApprovalRequest req) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Chip(
                  label: Text(req.targetType),
                  backgroundColor: WalldotColors.primary.withOpacity(0.1),
                  labelStyle: const TextStyle(color: WalldotColors.primary),
                ),
                Text(
                  DateFormat('yyyy-MM-dd HH:mm').format(DateTime.parse(req.requestedAt)),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              "Requested by: ${req.requestedByName}",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text("Ref ID: ${req.targetId}"),
            if (req.comments != null && req.comments!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text("Notes: ${req.comments}"),
            ],
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12.0),
              child: Divider(),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => _processApproval(req, 'REJECTED'),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  child: const Text("Reject"),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _processApproval(req, 'APPROVED'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  child: const Text("Approve"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _processApproval(ApprovalRequest req, String status) async {
    final commentController = TextEditingController();
    final decision = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("$status Request"),
        content: TextField(
          controller: commentController,
          decoration: const InputDecoration(labelText: "Comments (Optional)"),
          maxLines: 2,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: status == 'APPROVED' ? Colors.green : Colors.red),
            child: Text(status),
          ),
        ],
      ),
    );

    if (decision == true) {
      final userId = context.read<PortalAuthProvider>().user?.id;
      if (userId != null) {
        await context.read<ApprovalProvider>().processApproval(
          req.id!,
          status,
          commentController.text,
          userId,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Request $status")));
        }
      }
    }
  }
}
