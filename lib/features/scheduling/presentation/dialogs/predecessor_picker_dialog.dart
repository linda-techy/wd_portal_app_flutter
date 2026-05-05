import 'package:flutter/material.dart';
import 'package:admin/features/scheduling/data/models/wbs_template_model.dart';

/// Searchable picker that lists every task in the template (except the
/// successor itself). Returns a `(predecessorTemplateTaskId, lagDays)` pair.
class PredecessorPickerDialog extends StatefulWidget {
  final WbsTemplate template;
  final int? excludeTaskId;

  const PredecessorPickerDialog({
    super.key,
    required this.template,
    this.excludeTaskId,
  });

  static Future<WbsTemplateTaskPredecessorRef?> show(
    BuildContext context, {
    required WbsTemplate template,
    int? excludeTaskId,
  }) {
    return showDialog<WbsTemplateTaskPredecessorRef>(
      context: context,
      builder: (_) => PredecessorPickerDialog(
        template: template,
        excludeTaskId: excludeTaskId,
      ),
    );
  }

  @override
  State<PredecessorPickerDialog> createState() =>
      _PredecessorPickerDialogState();
}

class _PredecessorPickerDialogState extends State<PredecessorPickerDialog> {
  String _query = '';
  int? _selectedTaskId;
  int _lagDays = 0;

  List<({String label, int taskId})> get _candidates {
    final out = <({String label, int taskId})>[];
    for (final phase in widget.template.phases) {
      for (final task in phase.tasks) {
        if (task.id == null) continue;
        if (task.id == widget.excludeTaskId) continue;
        out.add((label: '${phase.name}: ${task.name}', taskId: task.id!));
      }
    }
    if (_query.isEmpty) return out;
    final q = _query.toLowerCase();
    return out.where((c) => c.label.toLowerCase().contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Pick predecessor'),
      content: SizedBox(
        width: 500,
        height: 400,
        child: Column(
          children: [
            TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                labelText: 'Search task',
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: _candidates.length,
                itemBuilder: (_, i) {
                  final c = _candidates[i];
                  return RadioListTile<int>(
                    title: Text(c.label),
                    value: c.taskId,
                    groupValue: _selectedTaskId,
                    onChanged: (v) => setState(() => _selectedTaskId = v),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('Lag days:'),
                const SizedBox(width: 8),
                SizedBox(
                  width: 80,
                  child: TextFormField(
                    initialValue: '0',
                    keyboardType: TextInputType.number,
                    onChanged: (v) => _lagDays = int.tryParse(v) ?? 0,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _selectedTaskId == null
              ? null
              : () => Navigator.of(context).pop(WbsTemplateTaskPredecessorRef(
                    predecessorTemplateTaskId: _selectedTaskId!,
                    lagDays: _lagDays,
                  )),
          child: const Text('Add'),
        ),
      ],
    );
  }
}
