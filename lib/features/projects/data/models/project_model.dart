/// Project model for the features/projects module.
/// Matches the /customer-projects/search API response.
class ProjectModel {
  final int? id;
  final String name;
  final String? code;
  final String location;
  final String? projectPhase;
  final String? projectStatus;
  final String? projectType;
  final double? overallProgress;
  final DateTime? startDate;
  final DateTime? endDate;
  final double? budget;
  final double? sqfeet;
  final String? customerName;
  final int? customerId;

  ProjectModel({
    this.id,
    required this.name,
    this.code,
    required this.location,
    this.projectPhase,
    this.projectStatus,
    this.projectType,
    this.overallProgress,
    this.startDate,
    this.endDate,
    this.budget,
    this.sqfeet,
    this.customerName,
    this.customerId,
  });

  static double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return double.tryParse(v.toString());
  }

  static DateTime? _toDate(dynamic v) {
    if (v == null) return null;
    return DateTime.tryParse(v.toString());
  }

  static int? _toInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    return int.tryParse(v.toString());
  }

  factory ProjectModel.fromJson(Map<String, dynamic> json) {
    // Customer name may be nested under a customer object
    String? customerName;
    final customer = json['customer'];
    if (customer is Map<String, dynamic>) {
      customerName = customer['name']?.toString() ??
          customer['fullName']?.toString() ??
          customer['full_name']?.toString();
    }
    customerName ??= json['customerName']?.toString() ??
        json['customer_name']?.toString();

    return ProjectModel(
      id: _toInt(json['id']),
      name: json['name']?.toString() ?? '',
      code: json['code']?.toString(),
      location: json['location']?.toString() ?? '',
      projectPhase: json['projectPhase']?.toString() ??
          json['project_phase']?.toString(),
      projectStatus: json['projectStatus']?.toString() ??
          json['project_status']?.toString() ??
          json['status']?.toString(),
      projectType: json['projectType']?.toString() ??
          json['project_type']?.toString(),
      overallProgress: _toDouble(json['overallProgress'] ??
          json['overall_progress'] ??
          json['progress']),
      startDate: _toDate(json['startDate'] ?? json['start_date']),
      endDate: _toDate(json['endDate'] ?? json['end_date']),
      budget: _toDouble(json['budget']),
      sqfeet: _toDouble(json['sqfeet']),
      customerName: customerName,
      customerId: _toInt(json['customerId'] ?? json['customer_id'] ??
          (customer is Map ? customer['id'] : null)),
    );
  }
}
