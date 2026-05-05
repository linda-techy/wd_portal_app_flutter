import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:admin/features/scheduling/data/models/monsoon_warning_model.dart';

/// Amber chip used wherever a monsoon-affected task is rendered.
///
/// `compact` (default true): just an icon + "Monsoon" label.
/// `compact: false`: also shows the monsoon window date range, suitable for
/// the project detail Schedule tab.
class MonsoonWarningChip extends StatelessWidget {
  final MonsoonWarning warning;
  final bool compact;

  const MonsoonWarningChip({
    super.key,
    required this.warning,
    this.compact = true,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('MMM d');
    final tooltip = 'Task "${warning.taskName}" overlaps the monsoon window '
        '(${fmt.format(warning.monsoonStart)} – ${fmt.format(warning.monsoonEnd)}).';
    final label = compact
        ? 'Monsoon'
        : 'Monsoon ${fmt.format(warning.monsoonStart)}–${fmt.format(warning.monsoonEnd)}';

    return Tooltip(
      message: tooltip,
      child: Chip(
        avatar: const Icon(Icons.umbrella, size: 16, color: Color(0xFFB78103)),
        label: Text(
          label,
          style: const TextStyle(fontSize: 12, color: Color(0xFFB78103)),
        ),
        backgroundColor: const Color(0xFFFFF4D6),
        side: const BorderSide(color: Color(0xFFE0B85A)),
        padding: const EdgeInsets.symmetric(horizontal: 4),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}
