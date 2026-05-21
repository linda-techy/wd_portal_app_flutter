/// One ITP (Inspection-Test Plan) quality gate on a schedule task.
/// Three gates per task: PRELIMINARY, IN_PROGRESS, FINAL.
class TaskQualityGate {
  final int id;
  final int taskId;
  final String gateType; // PRELIMINARY | IN_PROGRESS | FINAL
  final String status;   // PENDING | PASSED | FAILED | NA
  final int? signedByUserId;
  final String? signedByName;
  final DateTime? signedAt;
  final String? notes;
  final String? failureReason;

  TaskQualityGate({
    required this.id,
    required this.taskId,
    required this.gateType,
    required this.status,
    this.signedByUserId,
    this.signedByName,
    this.signedAt,
    this.notes,
    this.failureReason,
  });

  factory TaskQualityGate.fromJson(Map<String, dynamic> json) {
    return TaskQualityGate(
      id: (json['id'] as num).toInt(),
      taskId: (json['taskId'] as num).toInt(),
      gateType: json['gateType'] as String? ?? 'PRELIMINARY',
      status: json['status'] as String? ?? 'PENDING',
      signedByUserId: (json['signedByUserId'] as num?)?.toInt(),
      signedByName: json['signedByName'] as String?,
      signedAt: json['signedAt'] != null
          ? DateTime.tryParse(json['signedAt'].toString())
          : null,
      notes: json['notes'] as String?,
      failureReason: json['failureReason'] as String?,
    );
  }

  bool get isPending  => status == 'PENDING';
  bool get isPassed   => status == 'PASSED';
  bool get isFailed   => status == 'FAILED';
  bool get isNa       => status == 'NA';
  bool get isCleared  => isPassed || isNa;

  String get displayName {
    switch (gateType) {
      case 'PRELIMINARY': return 'Preliminary Check';
      case 'IN_PROGRESS': return 'In-Progress Check';
      case 'FINAL':       return 'Final Check';
      default: return gateType;
    }
  }

  String get description {
    switch (gateType) {
      case 'PRELIMINARY':
        return 'Before work starts — setting out, layout marking, material check, area readiness.';
      case 'IN_PROGRESS':
        return 'During execution — formwork, reinforcement placement, alignment mid-work.';
      case 'FINAL':
        return 'After completion — dimensional verification, finish quality, sign-off.';
      default:
        return '';
    }
  }

  int get orderIndex {
    switch (gateType) {
      case 'PRELIMINARY': return 1;
      case 'IN_PROGRESS': return 2;
      case 'FINAL':       return 3;
      default: return 99;
    }
  }
}
