import 'package:flutter/foundation.dart';

@immutable
class MonsoonWarning {
  final int taskId;
  final String taskName;
  final DateTime? plannedStart;
  final DateTime? plannedEnd;
  final DateTime monsoonStart;
  final DateTime monsoonEnd;

  const MonsoonWarning({
    required this.taskId,
    required this.taskName,
    required this.plannedStart,
    required this.plannedEnd,
    required this.monsoonStart,
    required this.monsoonEnd,
  });

  factory MonsoonWarning.fromJson(Map<String, dynamic> j) => MonsoonWarning(
        taskId: (j['taskId'] as num).toInt(),
        taskName: j['taskName'] as String,
        plannedStart: j['plannedStart'] == null
            ? null
            : DateTime.parse(j['plannedStart'] as String),
        plannedEnd: j['plannedEnd'] == null
            ? null
            : DateTime.parse(j['plannedEnd'] as String),
        monsoonStart: DateTime.parse(j['monsoonStart'] as String),
        monsoonEnd: DateTime.parse(j['monsoonEnd'] as String),
      );
}
