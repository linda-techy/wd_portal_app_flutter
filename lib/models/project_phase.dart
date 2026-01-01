/// Project Phase model for tracking construction phases
class ProjectPhase {
  final int? id;
  final int projectId;
  final String phaseName;
  final DateTime? plannedStart;
  final DateTime? plannedEnd;
  final DateTime? actualStart;
  final DateTime? actualEnd;
  final String status;
  final int? displayOrder;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ProjectPhase({
    this.id,
    required this.projectId,
    required this.phaseName,
    this.plannedStart,
    this.plannedEnd,
    this.actualStart,
    this.actualEnd,
    this.status = 'NOT_STARTED',
    this.displayOrder,
    this.createdAt,
    this.updatedAt,
  });

  factory ProjectPhase.fromJson(Map<String, dynamic> json) {
    return ProjectPhase(
      id: json['id'],
      projectId: json['project']?['id'] ?? json['projectId'] ?? 0,
      phaseName: json['phaseName'] ?? '',
      plannedStart: json['plannedStart'] != null
          ? DateTime.parse(json['plannedStart'])
          : null,
      plannedEnd: json['plannedEnd'] != null
          ? DateTime.parse(json['plannedEnd'])
          : null,
      actualStart: json['actualStart'] != null
          ? DateTime.parse(json['actualStart'])
          : null,
      actualEnd: json['actualEnd'] != null
          ? DateTime.parse(json['actualEnd'])
          : null,
      status: json['status'] ?? 'NOT_STARTED',
      displayOrder: json['displayOrder'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'projectId': projectId,
      'phaseName': phaseName,
      'plannedStart': plannedStart?.toIso8601String().split('T')[0],
      'plannedEnd': plannedEnd?.toIso8601String().split('T')[0],
      'actualStart': actualStart?.toIso8601String().split('T')[0],
      'actualEnd': actualEnd?.toIso8601String().split('T')[0],
      'status': status,
      'displayOrder': displayOrder,
    };
  }

  String get statusDisplay {
    switch (status) {
      case 'NOT_STARTED':
        return 'Not Started';
      case 'IN_PROGRESS':
        return 'In Progress';
      case 'COMPLETED':
        return 'Completed';
      case 'DELAYED':
        return 'Delayed';
      default:
        return status;
    }
  }

  bool get isDelayed {
    if (status == 'DELAYED') return true;
    if (plannedEnd != null && actualEnd == null && status == 'IN_PROGRESS') {
      return DateTime.now().isAfter(plannedEnd!);
    }
    return false;
  }

  int? get delayDays {
    if (plannedEnd == null) return null;
    final endDate = actualEnd ?? DateTime.now();
    if (endDate.isAfter(plannedEnd!)) {
      return endDate.difference(plannedEnd!).inDays;
    }
    return null;
  }
}
