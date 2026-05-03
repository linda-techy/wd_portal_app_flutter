import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:admin/features/leads/data/models/lead.dart';
import 'package:admin/providers/permission_provider.dart';
import 'package:admin/features/lead_estimation/data/models/lead_estimation.dart';
import 'package:admin/features/lead_estimation/presentation/screens/estimation_detail_screen.dart';
import 'package:admin/features/lead_estimation/presentation/screens/lead_estimation_wizard_screen.dart';
import 'package:admin/features/lead_estimation/providers/lead_estimations_provider.dart';

class LeadQuotationsScreen extends StatefulWidget {
  final Lead? lead;
  final int? leadId;

  /// When true, suppress the screen's own AppBar — used when this widget
  /// is hosted inside a parent's TabBarView (e.g. EditLeadScreen tabs).
  final bool embedded;

  const LeadQuotationsScreen(
      {super.key, this.lead, this.leadId, this.embedded = false});

  @override
  State<LeadQuotationsScreen> createState() => _LeadQuotationsScreenState();
}

class _LeadQuotationsScreenState extends State<LeadQuotationsScreen> {
  int _refreshKey = 0;

  Future<void> _generateEstimation(BuildContext context) async {
    final leadId = widget.leadId;
    if (leadId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No lead selected')),
      );
      return;
    }
    final created = await Navigator.of(context).push<LeadEstimationDetail>(
      MaterialPageRoute(
        builder: (_) => LeadEstimationWizardScreen(leadId: leadId),
        fullscreenDialog: true,
      ),
    );
    if (created != null && mounted) {
      setState(() => _refreshKey++);
    }
  }

  @override
  Widget build(BuildContext context) {
    final leadName = widget.lead?.name ?? 'Lead';
    final title = 'Estimations for $leadName';

    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Consumer<PermissionProvider>(
                builder: (context, permissionProvider, _) {
                  if (permissionProvider.hasPermission('lead:edit')) {
                    return ElevatedButton.icon(
                      icon: const Icon(Icons.calculate_outlined, size: 18),
                      label: const Text('Generate Estimation'),
                      onPressed: () => _generateEstimation(context),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ],
          ),
        ),
        if (widget.leadId != null)
          Expanded(
            child: _LeadEstimationsSection(
              leadId: widget.leadId!,
              refreshKey: _refreshKey,
            ),
          ),
      ],
    );

    if (widget.embedded) {
      return body;
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          Consumer<PermissionProvider>(
            builder: (context, permissionProvider, _) {
              if (permissionProvider.hasPermission('lead:edit') &&
                  widget.lead != null) {
                return IconButton(
                  icon: const Icon(Icons.calculate_outlined),
                  tooltip: 'Generate Estimation',
                  onPressed: () => _generateEstimation(context),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: body,
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────
// Estimations section
// ──────────────────────────────────────────────────────────────────────────

class _LeadEstimationsSection extends StatelessWidget {
  final int leadId;
  final int refreshKey;

  const _LeadEstimationsSection({
    required this.leadId,
    required this.refreshKey,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: ChangeNotifierProvider<LeadEstimationsProvider>(
        key: ValueKey(refreshKey),
        create: (_) => LeadEstimationsProvider()..loadForLead(leadId),
        child: ExpansionTile(
          initiallyExpanded: true,
          title: const Text('Estimations',
              style: TextStyle(fontWeight: FontWeight.w600)),
          children: [
            Consumer<LeadEstimationsProvider>(
              builder: (context, p, _) {
                if (p.isLoading && p.estimations.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (p.errorMessage != null) {
                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Text(p.errorMessage!,
                            style: const TextStyle(color: Colors.red)),
                        const SizedBox(height: 8),
                        FilledButton(
                            onPressed: p.load, child: const Text('Retry')),
                      ],
                    ),
                  );
                }
                if (p.estimations.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'No estimations yet — click "Generate Estimation" to create one.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }
                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: p.estimations.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final e = p.estimations[i];
                    final created =
                        e.createdAt.toIso8601String().substring(0, 10);
                    return ListTile(
                      leading: const CircleAvatar(
                          child: Icon(Icons.receipt_long)),
                      title: Row(
                        children: [
                          Text(e.estimationNo),
                          const SizedBox(width: 8),
                          _EstimationStatusPill(status: e.status),
                        ],
                      ),
                      subtitle: Text(
                        '${e.projectType.name} \u00b7 \u20b9${e.grandTotal.toStringAsFixed(2)} \u00b7 $created',
                      ),
                      onTap: () {
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) =>
                              EstimationDetailScreen(estimationId: e.id),
                        ));
                      },
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        tooltip: 'Delete',
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: const Text('Delete estimation?'),
                              content:
                                  Text('Soft-delete ${e.estimationNo}?'),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: const Text('Cancel'),
                                ),
                                FilledButton.tonal(
                                  onPressed: () =>
                                      Navigator.pop(context, true),
                                  style: FilledButton.styleFrom(
                                      backgroundColor:
                                          Colors.red.shade100),
                                  child: const Text('Delete'),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            await p.delete(e.id);
                          }
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Small status pill for the estimations list row
// ─────────────────────────────────────────────────────────────────────────────

class _EstimationStatusPill extends StatelessWidget {
  final LeadEstimationStatus status;

  const _EstimationStatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      LeadEstimationStatus.DRAFT => ('DRAFT', Colors.grey),
      LeadEstimationStatus.SENT => ('SENT', Colors.blue),
      LeadEstimationStatus.ACCEPTED => ('ACCEPTED', Colors.green),
      LeadEstimationStatus.REJECTED => ('REJECTED', Colors.red),
    };
    return Chip(
      label: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 10),
      ),
      backgroundColor: color,
      padding: EdgeInsets.zero,
      labelPadding: const EdgeInsets.symmetric(horizontal: 6),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}
