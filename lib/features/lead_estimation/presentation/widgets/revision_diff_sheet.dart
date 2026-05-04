import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:admin/features/lead_estimation/data/models/lead_estimation.dart';
import 'package:admin/features/lead_estimation/data/services/lead_estimation_service.dart';
import 'package:admin/utils/indian_number_formatter.dart';

/// N — Bottom-sheet that diffs a child estimation against its parent.
///
/// Compares line items by description (a heuristic — the backend doesn't
/// expose stable line-item identity across revisions) and renders three
/// sections: Removed, Added, Changed-amount. Mode-mismatched parent/child
/// pairs (e.g. budgetary parent → line-item child) skip per-line diff and
/// just show the grand-total delta.
class RevisionDiffSheet extends StatefulWidget {
  final LeadEstimationDetail child;

  const RevisionDiffSheet({super.key, required this.child});

  static Future<void> show(BuildContext context, LeadEstimationDetail child) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.85,
        child: RevisionDiffSheet(child: child),
      ),
    );
  }

  @override
  State<RevisionDiffSheet> createState() => _RevisionDiffSheetState();
}

class _RevisionDiffSheetState extends State<RevisionDiffSheet> {
  final _service = LeadEstimationService();
  LeadEstimationDetail? _parent;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final parentId = widget.child.parentEstimationId;
    if (parentId == null) {
      setState(() {
        _error = 'No parent linked to this estimation.';
        _loading = false;
      });
      return;
    }
    try {
      final parent = await _service.get(parentId);
      if (!mounted) return;
      setState(() {
        _parent = parent;
        _loading = false;
      });
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load parent: ${e.message ?? e.response?.statusCode}';
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  String _fmt(num n) => IndianNumberFormatter.formatINR(n);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Compare with parent',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const Divider(),
          if (_loading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (_error != null)
            Expanded(
              child: Center(
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              ),
            )
          else
            Expanded(child: SingleChildScrollView(child: _buildDiff(_parent!))),
        ],
      ),
    );
  }

  Widget _buildDiff(LeadEstimationDetail parent) {
    final modeChanged = parent.pricingMode != widget.child.pricingMode;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Header(parent: parent, child: widget.child),
        const SizedBox(height: 12),
        if (modeChanged)
          Card(
            color: Colors.amber.shade50,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                'Mode changed: ${parent.pricingMode.name} → ${widget.child.pricingMode.name}.\n'
                'Per-line comparison skipped (different shapes).',
                style: const TextStyle(fontSize: 13),
              ),
            ),
          )
        else
          ..._buildLineItemDiff(parent),
        const SizedBox(height: 16),
        _TotalDelta(parent: parent, child: widget.child),
      ],
    );
  }

  List<Widget> _buildLineItemDiff(LeadEstimationDetail parent) {
    // Match line items by description (best-effort — descriptions are stable for
    // BASE/CUSTOMISATION/SITE/ADDON/FEE/GST/DISCOUNT lines as emitted by the calculator).
    final parentByDesc = {for (final li in parent.lineItems) li.description: li};
    final childByDesc = {for (final li in widget.child.lineItems) li.description: li};

    final removed = parentByDesc.keys.where((k) => !childByDesc.containsKey(k)).toList();
    final added = childByDesc.keys.where((k) => !parentByDesc.containsKey(k)).toList();
    final changed = <String>[];
    for (final k in parentByDesc.keys.where(childByDesc.containsKey)) {
      if (parentByDesc[k]!.amount != childByDesc[k]!.amount) changed.add(k);
    }

    return [
      _Section(
        title: 'Removed (${removed.length})',
        color: Colors.red.shade50,
        items: removed.map((d) => Text('− $d  ${_fmt(parentByDesc[d]!.amount)}')).toList(),
      ),
      _Section(
        title: 'Added (${added.length})',
        color: Colors.green.shade50,
        items: added.map((d) => Text('+ $d  ${_fmt(childByDesc[d]!.amount)}')).toList(),
      ),
      _Section(
        title: 'Changed amount (${changed.length})',
        color: Colors.amber.shade50,
        items: changed.map((d) {
          final pa = parentByDesc[d]!.amount;
          final ca = childByDesc[d]!.amount;
          final delta = ca - pa;
          final sign = delta >= 0 ? '+' : '';
          return Text('• $d  ${_fmt(pa)} → ${_fmt(ca)} ($sign${_fmt(delta)})');
        }).toList(),
      ),
      if (removed.isEmpty && added.isEmpty && changed.isEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Text(
            'No line-item differences detected.',
            style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey[700]),
          ),
        ),
    ];
  }
}

class _Header extends StatelessWidget {
  final LeadEstimationDetail parent;
  final LeadEstimationDetail child;
  const _Header({required this.parent, required this.child});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Parent', style: TextStyle(color: Colors.grey[600], fontSize: 11)),
              Text(parent.estimationNo, style: const TextStyle(fontWeight: FontWeight.w600)),
              Text(parent.createdAt.toIso8601String().substring(0, 10),
                  style: const TextStyle(fontSize: 11)),
            ],
          ),
        ),
        const Icon(Icons.arrow_forward, size: 18),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('This revision',
                  style: TextStyle(color: Colors.grey[600], fontSize: 11)),
              Text(child.estimationNo, style: const TextStyle(fontWeight: FontWeight.w600)),
              Text(child.createdAt.toIso8601String().substring(0, 10),
                  style: const TextStyle(fontSize: 11)),
            ],
          ),
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Color color;
  final List<Widget> items;
  const _Section({required this.title, required this.color, required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Card(
      color: color,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            ...items,
          ],
        ),
      ),
    );
  }
}

class _TotalDelta extends StatelessWidget {
  final LeadEstimationDetail parent;
  final LeadEstimationDetail child;
  const _TotalDelta({required this.parent, required this.child});

  @override
  Widget build(BuildContext context) {
    final parentTotal = parent.grandTotal;
    final childTotal = child.grandTotal;
    final delta = childTotal - parentTotal;
    final sign = delta >= 0 ? '+' : '';
    final color = delta >= 0 ? Colors.red.shade700 : Colors.green.shade800;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Grand total', style: TextStyle(fontWeight: FontWeight.w600)),
            Text(
              '${IndianNumberFormatter.formatINR(parentTotal)} \u2192 ${IndianNumberFormatter.formatINR(childTotal)} ($sign${IndianNumberFormatter.formatINR(delta)})',
              style: TextStyle(fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
      ),
    );
  }
}
