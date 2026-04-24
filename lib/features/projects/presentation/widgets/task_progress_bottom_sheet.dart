import 'package:flutter/material.dart';

class TaskProgressBottomSheet extends StatefulWidget {
  final String taskTitle;
  final String? milestoneName;
  final int initialProgress;
  final Future<void> Function(int progress, String? note) onSave;

  const TaskProgressBottomSheet({
    super.key,
    required this.taskTitle,
    this.milestoneName,
    required this.initialProgress,
    required this.onSave,
  });

  @override
  State<TaskProgressBottomSheet> createState() =>
      _TaskProgressBottomSheetState();
}

class _TaskProgressBottomSheetState extends State<TaskProgressBottomSheet> {
  late double _value;
  final _noteCtrl = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _value = widget.initialProgress.toDouble();
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext c) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.taskTitle,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            if (widget.milestoneName != null)
              Text(
                widget.milestoneName!,
                style: const TextStyle(color: Colors.grey),
              ),
            const SizedBox(height: 16),
            Text(
              'Progress: ${_value.round()}%',
              style: const TextStyle(fontSize: 16),
            ),
            Slider(
              value: _value,
              min: 0,
              max: 100,
              divisions: 20, // 100 / 5 = 20 steps -> snaps to 5%
              label: '${_value.round()}%',
              onChanged: _saving ? null : (v) => setState(() => _value = v),
            ),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _saving
                        ? null
                        : () => setState(() => _value = 100.0),
                    child: const Text('Mark complete'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _noteCtrl,
              decoration:
                  const InputDecoration(labelText: 'Note (optional)'),
              enabled: !_saving,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                TextButton(
                  onPressed: _saving ? null : () => Navigator.pop(c),
                  child: const Text('Cancel'),
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: _saving
                      ? null
                      : () async {
                          setState(() => _saving = true);
                          try {
                            await widget.onSave(
                              _value.round(),
                              _noteCtrl.text.isEmpty ? null : _noteCtrl.text,
                            );
                            if (c.mounted) Navigator.pop(c);
                          } finally {
                            if (mounted) setState(() => _saving = false);
                          }
                        },
                  child: _saving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save'),
                ),
              ],
            ),
          ],
        ),
      );
}
