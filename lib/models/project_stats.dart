class ProjectStats {
  final int totalProjects;
  final int activeProjects;
  final int completedProjects;
  final Map<String, int> projectsByPhase;
  final Map<String, int> projectsByStatus;
  final double completionRate;
  final int onTrackCount;
  final int delayedCount;

  ProjectStats({
    required this.totalProjects,
    required this.activeProjects,
    required this.completedProjects,
    required this.projectsByPhase,
    required this.projectsByStatus,
    required this.completionRate,
    required this.onTrackCount,
    required this.delayedCount,
  });

  factory ProjectStats.fromJson(Map<String, dynamic> json) {
    return ProjectStats(
      totalProjects: _parseInt(json['total_projects'] ?? json['totalProjects']),
      activeProjects:
          _parseInt(json['active_projects'] ?? json['activeProjects']),
      completedProjects:
          _parseInt(json['completed_projects'] ?? json['completedProjects']),
      projectsByPhase:
          _parseMap(json['projects_by_phase'] ?? json['projectsByPhase']),
      projectsByStatus:
          _parseMap(json['projects_by_status'] ?? json['projectsByStatus']),
      completionRate:
          _parseDouble(json['completion_rate'] ?? json['completionRate']),
      onTrackCount: _parseInt(json['on_track_count'] ?? json['onTrackCount']),
      delayedCount: _parseInt(json['delayed_count'] ?? json['delayedCount']),
    );
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  static Map<String, int> _parseMap(dynamic value) {
    if (value == null) return {};
    if (value is Map) {
      return value.map((key, val) => MapEntry(
            key.toString(),
            _parseInt(val),
          ));
    }
    return {};
  }

  factory ProjectStats.empty() {
    return ProjectStats(
      totalProjects: 0,
      activeProjects: 0,
      completedProjects: 0,
      projectsByPhase: {},
      projectsByStatus: {},
      completionRate: 0.0,
      onTrackCount: 0,
      delayedCount: 0,
    );
  }
}
