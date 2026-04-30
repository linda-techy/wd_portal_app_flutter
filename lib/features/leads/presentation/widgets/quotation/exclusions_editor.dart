import 'package:flutter/material.dart';
import 'package:admin/features/leads/data/models/quotation_exclusion.dart';

/// Editable list of "what's NOT included" rows with the optional
/// cost-implication note ("Earth filling: ~₹40k–60k extra"). Pre-empting
/// these in writing has been shown to raise close rates — especially in
/// Kerala where compound wall / borewell / earth filling are recurring
/// scope-dispute items.
class ExclusionsEditor extends StatefulWidget {
  final List<QuotationExclusion> exclusions;
  final ValueChanged<List<QuotationExclusion>> onChanged;

  const ExclusionsEditor({
    super.key,
    required this.exclusions,
    required this.onChanged,
  });

  @override
  State<ExclusionsEditor> createState() => _ExclusionsEditorState();
}

class _ExclusionsEditorState extends State<ExclusionsEditor> {
  final _textController = TextEditingController();
  final _noteController = TextEditingController();

  @override
  void dispose() {
    _textController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _add() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    final next = [...widget.exclusions];
    next.add(QuotationExclusion(
      displayOrder: next.length,
      text: text,
      costImplicationNote: _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim(),
    ));
    widget.onChanged(next);
    _textController.clear();
    _noteController.clear();
  }

  void _remove(int index) {
    final next = [...widget.exclusions]..removeAt(index);
    widget.onChanged([
      for (var i = 0; i < next.length; i++) next[i].copyWith(displayOrder: i),
    ]);
  }

  void _move(int index, int delta) {
    if (index + delta < 0 || index + delta >= widget.exclusions.length) return;
    final next = [...widget.exclusions];
    final picked = next.removeAt(index);
    next.insert(index + delta, picked);
    widget.onChanged([
      for (var i = 0; i < next.length; i++) next[i].copyWith(displayOrder: i),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < widget.exclusions.length; i++)
          _Row(
            exclusion: widget.exclusions[i],
            onMoveUp: i > 0 ? () => _move(i, -1) : null,
            onMoveDown:
                i < widget.exclusions.length - 1 ? () => _move(i, 1) : null,
            onRemove: () => _remove(i),
          ),
        if (widget.exclusions.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'No exclusions yet — add the usual suspects (compound wall, borewell, earth filling, modular kitchen, furniture) to pre-empt disputes.',
              style:
                  TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
            ),
          ),
        const SizedBox(height: 8),
        Column(
          children: [
            TextField(
              controller: _textController,
              decoration: const InputDecoration(
                labelText: 'Exclusion',
                hintText: 'Earth filling material',
                isDense: true,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _noteController,
                    decoration: const InputDecoration(
                      labelText: 'Cost implication (optional)',
                      hintText: 'Estimate ₹40,000–60,000 extra',
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
        ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  final QuotationExclusion exclusion;
  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveDown;
  final VoidCallback onRemove;

  const _Row({
    required this.exclusion,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(Icons.close, size: 16, color: Colors.red),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(exclusion.text),
                if (exclusion.costImplicationNote != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      exclusion.costImplicationNote!,
                      style: const TextStyle(
                        fontStyle: FontStyle.italic,
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),
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
