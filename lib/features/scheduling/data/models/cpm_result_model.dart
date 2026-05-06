/// CPM (Critical Path Method) result snapshot served by
/// `GET /api/projects/{id}/cpm` (S2 PR1 backend).
///
/// The backend `CpmResultDto` JSON shape:
/// ```json
/// {
///   "projectId": 42,
///   "projectStartDate": "2026-06-01",
///   "projectFinishDate": "2026-09-30",
///   "criticalTaskIds": [101, 103],
///   "tasks": [
///     {
///       "taskId": 101,
///       "taskName": "Site Prep",
///       "durationDays": 5,
///       "esDate": "2026-06-01",
///       "efDate": "2026-06-05",
///       "lsDate": "2026-06-01",
///       "lfDate": "2026-06-05",
///       "totalFloatDays": 0,
///       "isCritical": true
///     }
///   ]
/// }
/// ```
///
/// The Flutter-side getter is named `criticalPathTaskIds` for readability,
/// but it is parsed from the backend's `criticalTaskIds` JSON key.
library;

class CpmTaskResult {
  final int taskId;
  final String taskName;
  final int? durationDays;
  final DateTime esDate;
  final DateTime efDate;
  final DateTime lsDate;
  final DateTime lfDate;
  final int totalFloatDays;
  final bool isCritical;

  const CpmTaskResult({
    required this.taskId,
    required this.taskName,
    this.durationDays,
    required this.esDate,
    required this.efDate,
    required this.lsDate,
    required this.lfDate,
    required this.totalFloatDays,
    required this.isCritical,
  });

  factory CpmTaskResult.fromJson(Map<String, dynamic> json) => CpmTaskResult(
        taskId: (json['taskId'] as num).toInt(),
        taskName: json['taskName'] as String? ?? '',
        durationDays: (json['durationDays'] as num?)?.toInt(),
        esDate: _parseUtcDate(json['esDate'] as String),
        efDate: _parseUtcDate(json['efDate'] as String),
        lsDate: _parseUtcDate(json['lsDate'] as String),
        lfDate: _parseUtcDate(json['lfDate'] as String),
        totalFloatDays: (json['totalFloatDays'] as num).toInt(),
        isCritical: json['isCritical'] as bool,
      );

  Map<String, dynamic> toJson() => {
        'taskId': taskId,
        'taskName': taskName,
        if (durationDays != null) 'durationDays': durationDays,
        'esDate': _fmt(esDate),
        'efDate': _fmt(efDate),
        'lsDate': _fmt(lsDate),
        'lfDate': _fmt(lfDate),
        'totalFloatDays': totalFloatDays,
        'isCritical': isCritical,
      };
}

class CpmResultModel {
  final int projectId;
  final DateTime projectStartDate;
  final DateTime projectFinishDate;

  /// Parsed from the backend's `criticalTaskIds` JSON field. Renamed on the
  /// Flutter side for clarity at call sites.
  final List<int> criticalPathTaskIds;
  final List<CpmTaskResult> tasks;

  const CpmResultModel({
    required this.projectId,
    required this.projectStartDate,
    required this.projectFinishDate,
    required this.criticalPathTaskIds,
    required this.tasks,
  });

  factory CpmResultModel.fromJson(Map<String, dynamic> json) => CpmResultModel(
        projectId: (json['projectId'] as num).toInt(),
        projectStartDate: _parseUtcDate(json['projectStartDate'] as String),
        projectFinishDate: _parseUtcDate(json['projectFinishDate'] as String),
        criticalPathTaskIds: (json['criticalTaskIds'] as List)
            .map((e) => (e as num).toInt())
            .toList(),
        tasks: (json['tasks'] as List)
            .map((e) => CpmTaskResult.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'projectId': projectId,
        'projectStartDate': _fmt(projectStartDate),
        'projectFinishDate': _fmt(projectFinishDate),
        'criticalTaskIds': criticalPathTaskIds,
        'tasks': tasks.map((t) => t.toJson()).toList(),
      };

  /// Convenience: returns a Map keyed by `taskId` for O(1) lookup from the
  /// Gantt screen's row builder.
  Map<int, CpmTaskResult> get byTaskId =>
      {for (final t in tasks) t.taskId: t};
}

String _fmt(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// Parses an ISO `yyyy-MM-dd` (date-only) string into a UTC DateTime so date
/// equality works regardless of the host machine's local zone.
DateTime _parseUtcDate(String s) {
  final parts = s.split('-');
  return DateTime.utc(
    int.parse(parts[0]),
    int.parse(parts[1]),
    int.parse(parts[2]),
  );
}
