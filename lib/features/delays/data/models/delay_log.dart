class DelayLog {
  final int? id;
  final int projectId;
  final int? phaseId;
  final String delayType; // WEATHER, LABOUR_STRIKE, MATERIAL_DELAY, CLIENT_APPROVAL, OTHER
  final DateTime fromDate;
  final DateTime? toDate;
  final String? reasonText;
  final DateTime? createdAt;

  DelayLog({
    this.id,
    required this.projectId,
    this.phaseId,
    required this.delayType,
    required this.fromDate,
    this.toDate,
    this.reasonText,
    this.createdAt,
  });

  factory DelayLog.fromJson(Map<String, dynamic> json) {
    return DelayLog(
      id: json['id'],
      projectId: json['project'] != null ? json['project']['id'] : 0,
      phaseId: json['phase'] != null ? json['phase']['id'] : null,
      delayType: json['delayType'] ?? 'OTHER',
      fromDate: DateTime.parse(json['fromDate']),
      toDate: json['toDate'] != null ? DateTime.parse(json['toDate']) : null,
      reasonText: json['reasonText'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'project': {'id': projectId},
      'phase': phaseId != null ? {'id': phaseId} : null,
      'delayType': delayType,
      'fromDate': fromDate.toIso8601String().substring(0, 10), // Send YYYY-MM-DD
      'toDate': toDate?.toIso8601String().substring(0, 10),
      'reasonText': reasonText,
    };
  }
}
