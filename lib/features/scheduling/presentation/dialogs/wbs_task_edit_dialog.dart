import 'package:flutter/material.dart';
import 'package:admin/features/scheduling/data/models/wbs_template_model.dart';
import 'package:admin/features/scheduling/presentation/dialogs/predecessor_picker_dialog.dart';

class WbsTaskEditDialog extends StatefulWidget {
  final WbsTemplate template;
  final WbsTemplateTask? existing;
  final int nextSequence;

  const WbsTaskEditDialog({
    super.key,
    required this.template,
    this.existing,
    required this.nextSequence,
  });

  static Future<WbsTemplateTask?> show(
    BuildContext context, {
    required WbsTemplate template,
    WbsTemplateTask? existing,
    required int nextSequence,
  }) {
    return showDialog<WbsTemplateTask>(
      context: context,
      builder: (_) => WbsTaskEditDialog(
        template: template,
        existing: existing,
        nextSequence: nextSequence,
      ),
    );
  }

  @override
  State<WbsTaskEditDialog> createState() => _WbsTaskEditDialogState();
}

class _WbsTaskEditDialogState extends State<WbsTaskEditDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _name;
  late TextEditingController _roleHint;
  late TextEditingController _durationDays;
  late TextEditingController _weightFactor; // empty = null = "use duration"
  late bool _monsoonSensitive;
  late bool _isPaymentMilestone;
  late FloorLoop _floorLoop;
  late List<WbsTemplateTaskPredecessorRef> _predecessors;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _name = TextEditingController(text: e?.name ?? '');
    _roleHint = TextEditingController(text: e?.roleHint ?? '');
    _durationDays =
        TextEditingController(text: (e?.durationDays ?? 1).toString());
    _weightFactor = TextEditingController(
      text: e?.weightFactor?.toString() ?? '',
    );
    _monsoonSensitive = e?.monsoonSensitive ?? false;
    _isPaymentMilestone = e?.isPaymentMilestone ?? false;
    _floorLoop = e?.floorLoop ?? FloorLoop.none;
    _predecessors = List.of(e?.predecessors ?? const []);
  }

  @override
  void dispose() {
    _name.dispose();
    _roleHint.dispose();
    _durationDays.dispose();
    _weightFactor.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEdit ? 'Edit Task' : 'New Task'),
      content: SizedBox(
        width: 600,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _name,
                  decoration: const InputDecoration(labelText: 'Task name *'),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Required';
                    if (v.length > 128) return 'Max 128 characters';
                    return null;
                  },
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _durationDays,
                        decoration: const InputDecoration(
                          labelText: 'Duration (working days) *',
                        ),
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          final n = int.tryParse(v ?? '');
                          if (n == null || n < 1) return 'Must be >= 1';
                          if (n > 365) return 'Max 365';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _weightFactor,
                        decoration: const InputDecoration(
                          labelText: 'Weight (blank = use duration)',
                        ),
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          if (v == null || v.isEmpty) return null;
                          final n = int.tryParse(v);
                          if (n == null || n < 1) return 'Must be >= 1';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                TextFormField(
                  controller: _roleHint,
                  decoration: const InputDecoration(labelText: 'Role hint'),
                ),
                DropdownButtonFormField<FloorLoop>(
                  value: _floorLoop,
                  decoration: const InputDecoration(labelText: 'Floor loop'),
                  items: FloorLoop.values
                      .map((f) =>
                          DropdownMenuItem(value: f, child: Text(f.label)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _floorLoop = v);
                  },
                ),
                SwitchListTile(
                  title: const Text('Monsoon-sensitive'),
                  value: _monsoonSensitive,
                  onChanged: (v) => setState(() => _monsoonSensitive = v),
                  contentPadding: EdgeInsets.zero,
                ),
                SwitchListTile(
                  title: const Text('Payment milestone'),
                  value: _isPaymentMilestone,
                  onChanged: (v) => setState(() => _isPaymentMilestone = v),
                  contentPadding: EdgeInsets.zero,
                ),
                const Divider(),
                _buildPredecessorsSection(),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _onSave, child: const Text('Save')),
      ],
    );
  }

  Widget _buildPredecessorsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('Predecessors',
                style: TextStyle(fontWeight: FontWeight.w600)),
            const Spacer(),
            TextButton.icon(
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add'),
              onPressed: _onAddPredecessor,
            ),
          ],
        ),
        if (_predecessors.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('(none — task starts immediately)',
                style: TextStyle(color: Colors.grey)),
          )
        else
          ..._predecessors.map((p) => ListTile(
                dense: true,
                title: Text(_resolveTaskName(p.predecessorTemplateTaskId)),
                subtitle: Text('Lag: ${p.lagDays} days'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => setState(() => _predecessors.remove(p)),
                ),
              )),
      ],
    );
  }

  String _resolveTaskName(int taskId) {
    for (final phase in widget.template.phases) {
      for (final task in phase.tasks) {
        if (task.id == taskId) return '${phase.name}: ${task.name}';
      }
    }
    return 'Task #$taskId';
  }

  Future<void> _onAddPredecessor() async {
    final picked = await PredecessorPickerDialog.show(
      context,
      template: widget.template,
      excludeTaskId: widget.existing?.id,
    );
    if (picked == null) return;
    if (_predecessors.any((p) =>
        p.predecessorTemplateTaskId == picked.predecessorTemplateTaskId)) {
      return;
    }
    setState(() => _predecessors.add(picked));
  }

  void _onSave() {
    if (!_formKey.currentState!.validate()) return;
    final weight =
        _weightFactor.text.isEmpty ? null : int.parse(_weightFactor.text);
    final base = widget.existing;
    final result = base == null
        ? WbsTemplateTask(
            sequence: widget.nextSequence,
            name: _name.text.trim(),
            roleHint:
                _roleHint.text.trim().isEmpty ? null : _roleHint.text.trim(),
            durationDays: int.parse(_durationDays.text),
            weightFactor: weight,
            monsoonSensitive: _monsoonSensitive,
            isPaymentMilestone: _isPaymentMilestone,
            floorLoop: _floorLoop,
            predecessors: _predecessors,
          )
        : base.copyWith(
            name: _name.text.trim(),
            roleHint:
                _roleHint.text.trim().isEmpty ? null : _roleHint.text.trim(),
            durationDays: int.parse(_durationDays.text),
            weightFactor: weight,
            clearWeightFactor: weight == null,
            monsoonSensitive: _monsoonSensitive,
            isPaymentMilestone: _isPaymentMilestone,
            floorLoop: _floorLoop,
            predecessors: _predecessors,
          );
    Navigator.of(context).pop(result);
  }
}
