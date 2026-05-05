import 'package:flutter/material.dart';
import 'package:admin/features/scheduling/data/models/wbs_template_model.dart';

class WbsPhaseEditDialog extends StatefulWidget {
  final WbsTemplatePhase? existing;
  final int nextSequence;

  const WbsPhaseEditDialog({
    super.key,
    this.existing,
    required this.nextSequence,
  });

  static Future<WbsTemplatePhase?> show(
    BuildContext context, {
    WbsTemplatePhase? existing,
    required int nextSequence,
  }) {
    return showDialog<WbsTemplatePhase>(
      context: context,
      builder: (_) => WbsPhaseEditDialog(
        existing: existing,
        nextSequence: nextSequence,
      ),
    );
  }

  @override
  State<WbsPhaseEditDialog> createState() => _WbsPhaseEditDialogState();
}

class _WbsPhaseEditDialogState extends State<WbsPhaseEditDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _name;
  late TextEditingController _roleHint;
  late bool _monsoonSensitive;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.existing?.name ?? '');
    _roleHint = TextEditingController(text: widget.existing?.roleHint ?? '');
    _monsoonSensitive = widget.existing?.monsoonSensitive ?? false;
  }

  @override
  void dispose() {
    _name.dispose();
    _roleHint.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEdit ? 'Edit Phase' : 'New Phase'),
      content: SizedBox(
        width: 500,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Phase name *'),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Required';
                  if (v.length > 128) return 'Max 128 characters';
                  return null;
                },
              ),
              TextFormField(
                controller: _roleHint,
                decoration: const InputDecoration(
                  labelText: 'Role hint (e.g., SCHEDULER, PROJECT_MANAGER)',
                ),
              ),
              SwitchListTile(
                title: const Text('Monsoon-sensitive (whole phase)'),
                value: _monsoonSensitive,
                onChanged: (v) => setState(() => _monsoonSensitive = v),
                contentPadding: EdgeInsets.zero,
              ),
            ],
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

  void _onSave() {
    if (!_formKey.currentState!.validate()) return;
    final base = widget.existing;
    final result = base == null
        ? WbsTemplatePhase(
            sequence: widget.nextSequence,
            name: _name.text.trim(),
            roleHint:
                _roleHint.text.trim().isEmpty ? null : _roleHint.text.trim(),
            monsoonSensitive: _monsoonSensitive,
            tasks: const [],
          )
        : base.copyWith(
            name: _name.text.trim(),
            roleHint:
                _roleHint.text.trim().isEmpty ? null : _roleHint.text.trim(),
            monsoonSensitive: _monsoonSensitive,
          );
    Navigator.of(context).pop(result);
  }
}
