import 'package:flutter/material.dart';

/// A colored chip for deduction decision values.
///
/// Decisions: PENDING · ACCEPTABLE · PARTIALLY_ACCEPTABLE · REJECTED
class DeductionStatusChip extends StatelessWidget {
  final String decision;
  final double fontSize;

  const DeductionStatusChip({
    super.key,
    required this.decision,
    this.fontSize = 11,
  });

  static const _colors = <String, Color>{
    'PENDING':              Colors.orange,
    'ACCEPTABLE':           Colors.green,
    'PARTIALLY_ACCEPTABLE': Colors.teal,
    'REJECTED':             Colors.red,
  };

  Color get _color => _colors[decision] ?? Colors.grey;

  @override
  Widget build(BuildContext context) {
    final color = _color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        decision,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
