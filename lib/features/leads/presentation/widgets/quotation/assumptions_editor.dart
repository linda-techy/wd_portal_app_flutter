import 'package:flutter/material.dart';
import 'package:admin/features/leads/data/models/quotation_assumption.dart';

/// Editable list of site / customer-side assumptions. Plain text rows —
/// the simplest of the three sub-resource editors.
///
/// Defaults the empty-state hint to the common Kerala set: plot levelled,
/// motorable road access, single-phase electricity, customer supplies water.
class AssumptionsEditor extends StatefulWidget {
  final List<QuotationAssumption> assumptions;
  final ValueChanged<List<QuotationAssumption>> onChanged;

  const AssumptionsEditor({
    super.key,
    required this.assumptions,
    required this.onChanged,
  });

  @override
  State<AssumptionsEditor> createState() => _AssumptionsEditorState();
}

class _AssumptionsEditorState extends State<AssumptionsEditor> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _add() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    final next = [...widget.assumptions];
    next.add(QuotationAssumption(
      displayOrder: next.length,
      text: text,
    ));
    widget.onChanged(next);
    _controller.clear();
  }

  void _remove(int index) {
    final next = [...widget.assumptions]..removeAt(index);
    widget.onChanged([
      for (var i = 0; i < next.length; i++) next[i].copyWith(displayOrder: i),
    ]);
  }

  /// Auto-populate the standard Kerala set so staff aren't typing them
  /// repeatedly across customers.
  void _seedDefaults() {
    if (widget.assumptions.isNotEmpty) return;
    const defaults = [
      'Plot is levelled and free of obstructions',
      'Motorable road access is available to the site',
      'Single-phase electricity available at site',
      'Customer supplies water during construction',
    ];
    widget.onChanged([
      for (var i = 0; i < defaults.length; i++)
        QuotationAssumption(displayOrder: i, text: defaults[i]),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < widget.assumptions.length; i++)
          Container(
            margin: const EdgeInsets.symmetric(vertical: 2),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).dividerColor),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                const Icon(Icons.fiber_manual_record, size: 8),
                const SizedBox(width: 8),
                Expanded(child: Text(widget.assumptions[i].text)),
                IconButton(
                  icon: const Icon(Icons.delete_outline,
                      size: 16, color: Colors.red),
                  onPressed: () => _remove(i),
                  tooltip: 'Remove',
                ),
              ],
            ),
          ),
        if (widget.assumptions.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'No assumptions yet — every Kerala builder lists at least these four.',
                    style: TextStyle(
                        color: Colors.grey, fontStyle: FontStyle.italic),
                  ),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.auto_awesome, size: 16),
                  label: const Text('Use Kerala defaults'),
                  onPressed: _seedDefaults,
                ),
              ],
            ),
          ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                decoration: const InputDecoration(
                  labelText: 'Assumption',
                  hintText: 'Plot is levelled',
                  isDense: true,
                ),
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
