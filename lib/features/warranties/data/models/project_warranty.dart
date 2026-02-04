class ProjectWarranty {
  final int? id;
  final int projectId;
  final String componentName;
  final String? description;
  final String? providerName;
  final DateTime? startDate;
  final DateTime? endDate;
  final String status; // ACTIVE, EXPIRED, VOID
  final String? coverageDetails;

  ProjectWarranty({
    this.id,
    required this.projectId,
    required this.componentName,
    this.description,
    this.providerName,
    this.startDate,
    this.endDate,
    this.status = 'ACTIVE',
    this.coverageDetails,
  });

  factory ProjectWarranty.fromJson(Map<String, dynamic> json) {
    return ProjectWarranty(
      id: json['id'],
      projectId: json['project'] != null ? json['project']['id'] : 0,
      componentName: json['componentName'],
      description: json['description'],
      providerName: json['providerName'],
      startDate: json['startDate'] != null ? DateTime.parse(json['startDate']) : null,
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
      status: json['status'] ?? 'ACTIVE',
      coverageDetails: json['coverage_details'], // Note: API uses coverage_details snake_case potentially
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'project': {'id': projectId},
      'componentName': componentName,
      'description': description,
      'providerName': providerName,
      'startDate': startDate?.toIso8601String().substring(0, 10),
      'endDate': endDate?.toIso8601String().substring(0, 10),
      'status': status,
      'coverage_details': coverageDetails,
    };
  }

  /// Display label for warranty type (alias for componentName).
  String? get warrantyType => componentName;

  /// Project name when provided by API (optional; override if API returns it).
  String? get projectName => null;

  /// Duration in months between start and end date.
  int? get durationMonths {
    if (startDate == null || endDate == null) return null;
    return (endDate!.difference(startDate!).inDays / 30).round();
  }

  /// Provider name (alias for providerName).
  String? get provider => providerName;
}
