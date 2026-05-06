import 'package:flutter/material.dart';

/// Modal dialog used by the PM Approval Inbox to capture a rejection
/// reason (5–500 chars). Returns the trimmed reason string on submit, or
/// null if the user cancels.
class RejectCompletionDialog extends StatefulWidget {
  const RejectCompletionDialog({super.key, required this.taskTitle});

  final String taskTitle;

  static Future<String?> show(BuildContext context, String taskTitle) {
    return showDialog<String>(
      context: context,
      builder: (_) => RejectCompletionDialog(taskTitle: taskTitle),
    );
  }

  @override
  State<RejectCompletionDialog> createState() => _RejectCompletionDialogState();
}

class _RejectCompletionDialogState extends State<RejectCompletionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Reject completion: ${widget.taskTitle}'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _ctrl,
          autofocus: true,
          minLines: 3,
          maxLines: 6,
          maxLength: 500,
          decoration: const InputDecoration(
            labelText: 'Reason (5–500 chars)',
            hintText: 'Why is this completion being rejected?',
            border: OutlineInputBorder(),
          ),
          validator: (v) {
            final t = (v ?? '').trim();
            if (t.length < 5) return 'Reason must be at least 5 characters';
            if (t.length > 500) return 'Reason cannot exceed 500 characters';
            return null;
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.of(context).pop(_ctrl.text.trim());
            }
          },
          child: const Text('Reject'),
        ),
      ],
    );
  }
}
