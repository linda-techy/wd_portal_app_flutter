import 'package:flutter/material.dart';
import 'package:admin/theme/app_theme.dart';

/// A generic confirmation dialog with an optional freetext input field.
///
/// Returns `null` (cancelled) or the entered text / empty string (confirmed).
///
/// Example — simple confirm:
/// ```dart
/// final ok = await ConfirmActionDialog.show(
///   context: context,
///   title: 'Submit Final Account',
///   message: 'This will move the account to SUBMITTED status.',
///   confirmLabel: 'Submit',
///   confirmColor: Colors.orange,
/// );
/// if (ok == null) return; // cancelled
/// ```
///
/// Example — with required text input:
/// ```dart
/// final agreedBy = await ConfirmActionDialog.show(
///   context: context,
///   title: 'Mark as Agreed',
///   inputLabel: 'Agreed By *',
///   confirmLabel: 'Confirm',
///   confirmColor: Colors.green,
/// );
/// if (agreedBy == null || agreedBy.isEmpty) return;
/// ```
class ConfirmActionDialog extends StatefulWidget {
  final String title;
  final String? message;
  final String? inputLabel;
  final String confirmLabel;
  final Color confirmColor;
  final String cancelLabel;

  const ConfirmActionDialog({
    super.key,
    required this.title,
    this.message,
    this.inputLabel,
    this.confirmLabel = 'Confirm',
    this.confirmColor = AppTheme.coralRed,
    this.cancelLabel = 'Cancel',
  });

  /// Shows the dialog and returns the input text on confirm, null on cancel.
  /// If [inputLabel] is null, returns empty string on confirm.
  static Future<String?> show({
    required BuildContext context,
    required String title,
    String? message,
    String? inputLabel,
    String confirmLabel = 'Confirm',
    Color confirmColor = AppTheme.coralRed,
    String cancelLabel = 'Cancel',
  }) {
    return showDialog<String>(
      context: context,
      builder: (_) => ConfirmActionDialog(
        title: title,
        message: message,
        inputLabel: inputLabel,
        confirmLabel: confirmLabel,
        confirmColor: confirmColor,
        cancelLabel: cancelLabel,
      ),
    );
  }

  @override
  State<ConfirmActionDialog> createState() => _ConfirmActionDialogState();
}

class _ConfirmActionDialogState extends State<ConfirmActionDialog> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.message != null) ...[
            Text(widget.message!,
                style: const TextStyle(fontSize: 14, color: Colors.black87)),
            const SizedBox(height: 12),
          ],
          if (widget.inputLabel != null)
            TextField(
              controller: _ctrl,
              autofocus: true,
              decoration: InputDecoration(
                labelText: widget.inputLabel,
                border: const OutlineInputBorder(),
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(widget.cancelLabel),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
              backgroundColor: widget.confirmColor),
          onPressed: () =>
              Navigator.pop(context, _ctrl.text.trim()),
          child: Text(widget.confirmLabel,
              style: const TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
