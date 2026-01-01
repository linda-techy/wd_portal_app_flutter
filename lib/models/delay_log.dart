/// Delay Log model for tracking project delays
class DelayLog {
  final int? id;
  final int projectId;
  final int? phaseId;
  final String delayType;
  final DateTime fromDate;
  final DateTime? toDate;
  final String? reasonText;
  final int? loggedById;
  final DateTime? createdAt;

  DelayLog({
    this.id,
    required this.projectId,
    this.phaseId,
    required this.delayType,
    required this.fromDate,
    this.toDate,
    this.reasonText,
    this.loggedById,
    this.createdAt,
  });

  factory DelayLog.fromJson(Map<String, dynamic> json) {
    return DelayLog(
      id: json['id'],
      projectId: json['project']?['id'] ?? json['projectId'] ?? 0,
      phaseId: json['phase']?['id'] ?? json['phaseId'],
      delayType: json['delayType'] ?? '',
      fromDate: DateTime.parse(json['fromDate']),
      toDate: json['toDate'] != null ? DateTime.parse(json['toDate']) : null,
      reasonText: json['reasonText'],
      loggedById: json['loggedBy']?['id'] ?? json['loggedById'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'projectId': projectId,
      if (phaseId != null) 'phaseId': phaseId,
      'delayType': delayType,
      'fromDate': fromDate.toIso8601String().split('T')[0],
      if (toDate != null) 'toDate': toDate!.toIso8601String().split('T')[0],
      'reason': reasonText,
      if (loggedById != null) 'loggedById': loggedById,
    };
  }

  String get delayTypeDisplay {
    switch (delayType) {
      case 'WEATHER':
        return 'Weather';
      case 'LABOUR_STRIKE':
        return 'Labour Strike';
      case 'MATERIAL_DELAY':
        return 'Material Delay';
      case 'CLIENT_APPROVAL':
        return 'Client Approval';
      case 'OTHER':
        return 'Other';
      default:
        return delayType;
    }
  }

  int get daysDelayed {
    final end = toDate ?? DateTime.now();
    return end.difference(fromDate).inDays;
  }

  static List<String> get delayTypes => [
        'WEATHER',
        'LABOUR_STRIKE',
        'MATERIAL_DELAY',
        'CLIENT_APPROVAL',
        'OTHER',
      ];
}
