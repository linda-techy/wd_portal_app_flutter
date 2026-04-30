import 'package:flutter/material.dart';
import 'package:admin/features/leads/data/models/quotation_inclusion.dart';

/// Editable list of "what's included" rows. Stateless w.r.t. the data —
/// the parent screen owns the list and reacts to [onChanged].
///
/// Designed to feel like a chip cloud / line list, not a heavy data grid:
/// staff add 8–16 rows on a residential quote, not hundreds. Re-ordering
/// is via up/down arrows (not a drag handle) because PDF generation
/// goes through Thymeleaf, where stable display_order is what matters.
class InclusionsEditor extends StatefulWidget {
  final List<QuotationInclusion> inclusions;
  final ValueChanged<List<QuotationInclusion>> onChanged;

  const InclusionsEditor({
    super.key,
    required this.inclusions,
    required this.onChanged,
  });

  @override
  State<InclusionsEditor> createState() => _InclusionsEditorState();
}

class _InclusionsEditorState extends State<InclusionsEditor> {
  final _textController = TextEditingController();
  final _categoryController = TextEditingController();

  @override
  void dispose() {
    _textController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  void _add() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    final next = [...widget.inclusions];
    next.add(QuotationInclusion(
      displayOrder: next.length,
      category: _categoryController.text.trim().isEmpty
          ? null
          : _categoryController.text.trim(),
      text: text,
    ));
    widget.onChanged(next);
    _textController.clear();
    _categoryController.clear();
  }

  void _remove(int index) {
    final next = [...widget.inclusions]..removeAt(index);
    widget.onChanged(_renumber(next));
  }

  void _move(int index, int delta) {
    if (index + delta < 0 || index + delta >= widget.inclusions.length) return;
    final next = [...widget.inclusions];
    final picked = next.removeAt(index);
    next.insert(index + delta, picked);
    widget.onChanged(_renumber(next));
  }

  /// Re-derive [displayOrder] after add/remove/move so the list always
  /// has 0..n-1 contiguous values — the backend tolerates gaps but the
  /// PDF renders cleaner this way.
  List<QuotationInclusion> _renumber(List<QuotationInclusion> rows) {
    return [
      for (var i = 0; i < rows.length; i++)
        rows[i].copyWith(displayOrder: i),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < widget.inclusions.length; i++)
          _Row(
            inclusion: widget.inclusions[i],
            onMoveUp: i > 0 ? () => _move(i, -1) : null,
            onMoveDown:
                i < widget.inclusions.length - 1 ? () => _move(i, 1) : null,
            onRemove: () => _remove(i),
          ),
        if (widget.inclusions.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'No inclusions yet — add at least 5 to render a credible PDF.',
              style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
            ),
          ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 120,
              child: TextField(
                controller: _categoryController,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  hintText: 'Civil',
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _textController,
                decoration: const InputDecoration(
                  labelText: 'Inclusion',
                  hintText: 'RCC 1:1.5:3 for sloped roof slab',
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

class _Row extends StatelessWidget {
  final QuotationInclusion inclusion;
  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveDown;
  final VoidCallback onRemove;

  const _Row({
    required this.inclusion,
    required this.onMoveUp,
    required this.onMoveDown,
    required this.onRemove,
  });

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
          const Icon(Icons.check, size: 16, color: Colors.green),
          const SizedBox(width: 8),
          if (inclusion.category != null)
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(3),
              ),
              child: Text(
                inclusion.category!,
                style: const TextStyle(fontSize: 10, letterSpacing: 0.5),
              ),
            ),
          Expanded(child: Text(inclusion.text)),
          IconButton(
            icon: const Icon(Icons.arrow_upward, size: 16),
            onPressed: onMoveUp,
            tooltip: 'Move up',
          ),
          IconButton(
            icon: const Icon(Icons.arrow_downward, size: 16),
            onPressed: onMoveDown,
            tooltip: 'Move down',
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
