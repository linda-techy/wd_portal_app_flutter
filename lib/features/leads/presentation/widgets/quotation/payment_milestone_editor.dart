import 'package:flutter/material.dart';
import 'package:admin/features/leads/data/models/quotation_payment_milestone.dart';

/// Editor for the Kerala-style 8-stage milestone schedule. Surfaces a
/// running percentage total at the top so staff can see at a glance
/// whether they're at 100% (contract-valid) or off by a few points.
///
/// Amounts are intentionally NOT edited here — at the BUDGETARY stage
/// the rupee figure isn't meaningful, and at DETAILED/CONTRACT_BOQ the
/// service derives it from `parent.finalAmount × percentage`.
class PaymentMilestoneEditor extends StatefulWidget {
  final List<QuotationPaymentMilestone> milestones;
  final ValueChanged<List<QuotationPaymentMilestone>> onChanged;

  const PaymentMilestoneEditor({
    super.key,
    required this.milestones,
    required this.onChanged,
  });

  @override
  State<PaymentMilestoneEditor> createState() => _PaymentMilestoneEditorState();
}

class _PaymentMilestoneEditorState extends State<PaymentMilestoneEditor> {
  final _eventController = TextEditingController();
  final _pctController = TextEditingController();

  @override
  void dispose() {
    _eventController.dispose();
    _pctController.dispose();
    super.dispose();
  }

  double get _totalPct => widget.milestones.fold(
      0.0, (sum, m) => sum + m.percentage);

  void _add() {
    final event = _eventController.text.trim();
    final pct = double.tryParse(_pctController.text.trim());
    if (event.isEmpty || pct == null || pct <= 0) return;
    final next = [...widget.milestones];
    next.add(QuotationPaymentMilestone(
      milestoneNumber: next.length + 1,
      triggerEvent: event,
      percentage: pct,
    ));
    widget.onChanged(next);
    _eventController.clear();
    _pctController.clear();
  }

  void _remove(int index) {
    final next = [...widget.milestones]..removeAt(index);
    // Renumber 1..n so the customer-facing "Stage 3 of 8" stays correct.
    widget.onChanged([
      for (var i = 0; i < next.length; i++)
        next[i].copyWith(milestoneNumber: i + 1),
    ]);
  }

  void _seedKeralaDefault() {
    widget.onChanged(
        QuotationPaymentMilestone.defaultKeralaSchedule());
  }

  @override
  Widget build(BuildContext context) {
    final pct = _totalPct;
    final pctColor = (pct - 100).abs() < 0.01
        ? Colors.green
        : pct > 100
            ? Colors.red
            : Colors.orange;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Running-total banner
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: pctColor.withOpacity(0.08),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: pctColor.withOpacity(0.4)),
          ),
          child: Row(
            children: [
              Icon(
                pct == 100
                    ? Icons.check_circle
                    : pct > 100
                        ? Icons.warning
                        : Icons.info_outline,
                color: pctColor,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  pct == 100
                      ? 'Allocation: 100% — contract-ready'
                      : pct > 100
                          ? 'Allocation: ${pct.toStringAsFixed(1)}% — over by ${(pct - 100).toStringAsFixed(1)}%'
                          : 'Allocation: ${pct.toStringAsFixed(1)}% — ${(100 - pct).toStringAsFixed(1)}% remaining',
                  style: TextStyle(color: pctColor),
                ),
              ),
              if (widget.milestones.isEmpty)
                TextButton.icon(
                  icon: const Icon(Icons.auto_awesome, size: 16),
                  label: const Text('Kerala 8-stage default'),
                  onPressed: _seedKeralaDefault,
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        for (var i = 0; i < widget.milestones.length; i++)
          _Row(
            milestone: widget.milestones[i],
            onRemove: () => _remove(i),
          ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              flex: 3,
              child: TextField(
                controller: _eventController,
                decoration: const InputDecoration(
                  labelText: 'Trigger event',
                  hintText: 'Plinth beam complete',
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 80,
              child: TextField(
                controller: _pctController,
                decoration: const InputDecoration(
                  labelText: '%',
                  isDense: true,
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                onSubmitted: (_) => _add(),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton.icon(
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add'),
              onPressed: _add,
            ),
          ],
        ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  final QuotationPaymentMilestone milestone;
  final VoidCallback onRemove;

  const _Row({required this.milestone, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(
              '${milestone.milestoneNumber}.',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(milestone.triggerEvent)),
          SizedBox(
            width: 60,
            child: Text(
              '${milestone.percentage.toStringAsFixed(1)}%',
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline,
                size: 16, color: Colors.red),
            onPressed: onRemove,
            tooltip: 'Remove',
          ),
        ],
      ),
    );
  }
}
