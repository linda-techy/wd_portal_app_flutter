/// One predecessor edge as returned by GET /api/tasks/{taskId}/predecessors.
class TaskPredecessorEdge {
  final int id;
  final int successorId;
  final int predecessorId;
  final String predecessorTitle;
  final int lagDays;
  final String depType; // FS / SS / FF / SF — currently only FS used

  TaskPredecessorEdge({
    required this.id,
    required this.successorId,
    required this.predecessorId,
    required this.predecessorTitle,
    required this.lagDays,
    required this.depType,
  });

  factory TaskPredecessorEdge.fromJson(Map<String, dynamic> json) {
    return TaskPredecessorEdge(
      id: (json['id'] as num).toInt(),
      successorId: (json['successorId'] as num).toInt(),
      predecessorId: (json['predecessorId'] as num).toInt(),
      predecessorTitle:
          (json['predecessorTitle'] as String?) ?? '(deleted)',
      lagDays: (json['lagDays'] as num?)?.toInt() ?? 0,
      depType: (json['depType'] as String?) ?? 'FS',
    );
  }
}

/// Payload for `PUT /api/tasks/{taskId}/predecessors`.
class PredecessorListRequest {
  final List<PredecessorEntry> predecessors;

  PredecessorListRequest(this.predecessors);

  Map<String, dynamic> toJson() => {
        'predecessors': predecessors.map((e) => e.toJson()).toList(),
      };
}

class PredecessorEntry {
  final int predecessorId;
  final int lagDays;

  PredecessorEntry({required this.predecessorId, this.lagDays = 0});

  Map<String, dynamic> toJson() =>
      {'predecessorId': predecessorId, 'lagDays': lagDays};
}
