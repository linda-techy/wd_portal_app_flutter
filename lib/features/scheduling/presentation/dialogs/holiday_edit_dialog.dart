import 'package:flutter/material.dart';
import 'package:admin/features/scheduling/data/models/holiday_model.dart';

class HolidayEditDialog extends StatefulWidget {
  final Holiday? existing;

  const HolidayEditDialog({super.key, this.existing});

  static Future<Holiday?> show(BuildContext context, {Holiday? existing}) {
    return showDialog<Holiday>(
      context: context,
      builder: (_) => HolidayEditDialog(existing: existing),
    );
  }

  @override
  State<HolidayEditDialog> createState() => _HolidayEditDialogState();
}

class _HolidayEditDialogState extends State<HolidayEditDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _name;
  late TextEditingController _code;
  late TextEditingController _scopeRef;
  late DateTime _date;
  late HolidayScope _scope;
  late HolidayRecurrenceType _recurrence;
  late bool _active;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _name = TextEditingController(text: e?.name ?? '');
    _code = TextEditingController(text: e?.code ?? '');
    _scopeRef = TextEditingController(text: e?.scopeRef ?? '');
    _date = e?.date ?? DateTime.now();
    _scope = e?.scope ?? HolidayScope.national;
    _recurrence = e?.recurrenceType ?? HolidayRecurrenceType.fixedDate;
    _active = e?.active ?? true;
  }

  @override
  void dispose() {
    _name.dispose();
    _code.dispose();
    _scopeRef.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEdit ? 'Edit Holiday' : 'New Holiday'),
      content: SizedBox(
        width: 500,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _name,
                  decoration: const InputDecoration(labelText: 'Name *'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                TextFormField(
                  controller: _code,
                  decoration: const InputDecoration(
                    labelText: 'Code (e.g., KL_ONAM_DAY1)',
                  ),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    'Date: ${_date.year}-'
                    '${_date.month.toString().padLeft(2, '0')}-'
                    '${_date.day.toString().padLeft(2, '0')}',
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: _pickDate,
                ),
                DropdownButtonFormField<HolidayScope>(
                  value: _scope,
                  decoration: const InputDecoration(labelText: 'Scope *'),
                  items: HolidayScope.values
                      .map((s) =>
                          DropdownMenuItem(value: s, child: Text(s.label)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _scope = v);
                  },
                ),
                TextFormField(
                  controller: _scopeRef,
                  decoration: InputDecoration(
                    labelText: _scope == HolidayScope.national
                        ? 'Scope ref (leave blank for NATIONAL)'
                        : _scope == HolidayScope.state
                            ? 'State code (e.g., KL)'
                            : _scope == HolidayScope.district
                                ? 'District code (e.g., KL-EKM)'
                                : 'Project ID',
                  ),
                ),
                DropdownButtonFormField<HolidayRecurrenceType>(
                  value: _recurrence,
                  decoration:
                      const InputDecoration(labelText: 'Recurrence type *'),
                  items: HolidayRecurrenceType.values
                      .map((r) =>
                          DropdownMenuItem(value: r, child: Text(r.label)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _recurrence = v);
                  },
                ),
                if (_isEdit)
                  SwitchListTile(
                    title: const Text('Active'),
                    value: _active,
                    onChanged: (v) => setState(() => _active = v),
                    contentPadding: EdgeInsets.zero,
                  ),
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

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
    );
    if (picked != null) setState(() => _date = picked);
  }

  void _onSave() {
    if (!_formKey.currentState!.validate()) return;
    final result = Holiday(
      id: widget.existing?.id,
      code: _code.text.trim().isEmpty ? null : _code.text.trim(),
      name: _name.text.trim(),
      date: _date,
      scope: _scope,
      scopeRef: _scopeRef.text.trim().isEmpty ? null : _scopeRef.text.trim(),
      recurrenceType: _recurrence,
      active: _active,
    );
    Navigator.of(context).pop(result);
  }
}
