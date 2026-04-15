import 'package:flutter/material.dart';

/// A colored pill badge for VO / Final Account statuses.
///
/// Usage:
/// ```dart
/// VOStatusBadge(status: 'APPROVED')
/// VOStatusBadge(status: 'REJECTED', fontSize: 11)
/// ```
class VOStatusBadge extends StatelessWidget {
  final String status;
  final double fontSize;

  const VOStatusBadge({
    super.key,
    required this.status,
    this.fontSize = 12,
  });

  static const _colors = <String, Color>{
    'DRAFT':             Colors.grey,
    'SUBMITTED':         Colors.orange,
    'CUSTOMER_REVIEW':   Colors.blue,
    'APPROVED':          Colors.green,
    'REJECTED':          Colors.red,
    'DISPUTED':          Colors.red,
    'AGREED':            Colors.green,
    'CLOSED':            Colors.black54,
  };

  Color get _color => _colors[status] ?? Colors.grey;

  @override
  Widget build(BuildContext context) {
    final color = _color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
