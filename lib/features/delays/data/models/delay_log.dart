class DelayLog {
  final int? id;
  final int projectId;
  final int? phaseId;
  final String delayType; // WEATHER, LABOUR_STRIKE, MATERIAL_DELAY, CLIENT_APPROVAL, OTHER
  final DateTime fromDate;
  final DateTime? toDate;
  final String? reasonText;
  final String? reasonCategory;
  final String? responsibleParty;
  final int? durationDaysField;
  final String? impactDescription;
  final DateTime? createdAt;

  DelayLog({
    this.id,
    required this.projectId,
    this.phaseId,
    required this.delayType,
    required this.fromDate,
    this.toDate,
    this.reasonText,
    this.reasonCategory,
    this.responsibleParty,
    this.durationDaysField,
    this.impactDescription,
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
      reasonCategory: json['reasonCategory'],
      responsibleParty: json['responsibleParty'],
      durationDaysField: json['durationDays'] as int?,
      impactDescription: json['impactDescription'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'project': {'id': projectId},
      'phase': phaseId != null ? {'id': phaseId} : null,
      'delayType': delayType,
      'fromDate': fromDate.toIso8601String().substring(0, 10),
      'toDate': toDate?.toIso8601String().substring(0, 10),
      'reasonText': reasonText,
      if (reasonCategory != null) 'reasonCategory': reasonCategory,
      if (responsibleParty != null) 'responsibleParty': responsibleParty,
      if (durationDaysField != null) 'durationDays': durationDaysField,
      if (impactDescription != null) 'impactDescription': impactDescription,
    };
  }

  /// Project name when provided by API.
  String? get projectName => null;

  /// True when toDate is set (delay period ended).
  bool get isResolved => toDate != null;

  /// Description / reason for delay (alias for reasonText).
  String? get description => reasonText;

  /// Start date of delay (alias for fromDate).
  DateTime get startDate => fromDate;

  /// Number of days delayed — uses explicit field if set, else computed.
  int get durationDays =>
      durationDaysField ?? (toDate ?? DateTime.now()).difference(fromDate).inDays;

  /// Severity / type for display (alias for delayType).
  String get severity => delayType;

  /// Display label for the reason category.
  String get categoryLabel =>
      (reasonCategory ?? delayType).replaceAll('_', ' ');
}
