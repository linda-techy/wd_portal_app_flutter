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
}
