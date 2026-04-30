import 'package:intl/intl.dart';
import '../constants.dart';

enum ReportType {
  dailyProgress,
  qualityCheck,
  safetyIncident,
  materialDelivery,
  siteVisitSummary,
  other;

  String get label {
    switch (this) {
      case ReportType.dailyProgress: return 'Daily Progress';
      case ReportType.qualityCheck: return 'Quality Check';
      case ReportType.safetyIncident: return 'Safety Incident';
      case ReportType.materialDelivery: return 'Material Delivery';
      case ReportType.siteVisitSummary: return 'Site Visit Summary';
      case ReportType.other: return 'Other';
    }
  }

  // Convert from backend SCREAMING_SNAKE_CASE to camelCase enum
  static ReportType fromJson(String? json) {
    if (json == null) return ReportType.dailyProgress;
    
    // Normalize string to match enum names (e.g. DAILY_PROGRESS -> dailyProgress)
    // Map of backend values to enum values
    const map = {
      'DAILY_PROGRESS': ReportType.dailyProgress,
      'QUALITY_CHECK': ReportType.qualityCheck,
      'SAFETY_INCIDENT': ReportType.safetyIncident,
      'MATERIAL_DELIVERY': ReportType.materialDelivery,
      'SITE_VISIT_SUMMARY': ReportType.siteVisitSummary,
      'OTHER': ReportType.other,
    };

    final mapped = map[json];
    if (mapped != null) return mapped;
    // Try camelCase match if backend sends camelCase
    final camel = ReportType.values.where((e) => e.name == json);
    if (camel.isNotEmpty) return camel.first;
    // Unknown value — log so backend/app schema drift is visible instead
    // of silently collapsing to OTHER. Common cause: backend added a new
    // ReportType enum and the app hasn't shipped yet.
    // ignore: avoid_print
    print('[ReportType.fromJson] Unknown report type from backend: $json — '
        'falling back to OTHER. App may be out of date.');
    return ReportType.other;
  }

  // Convert to backend SCREAMING_SNAKE_CASE
  String toJson() {
    switch (this) {
      case ReportType.dailyProgress: return 'DAILY_PROGRESS';
      case ReportType.qualityCheck: return 'QUALITY_CHECK';
      case ReportType.safetyIncident: return 'SAFETY_INCIDENT';
      case ReportType.materialDelivery: return 'MATERIAL_DELIVERY';
      case ReportType.siteVisitSummary: return 'SITE_VISIT_SUMMARY';
      case ReportType.other: return 'OTHER';
    }
  }
}

class SiteReportPhoto {
  final int? id;
  final String photoUrl;
  final String storagePath;
  final DateTime? createdAt;
  final String? caption;
  final double? latitude;
  final double? longitude;
  final int displayOrder;

  SiteReportPhoto({
    this.id,
    required this.photoUrl,
    required this.storagePath,
    this.createdAt,
    this.caption,
    this.latitude,
    this.longitude,
    this.displayOrder = 0,
  });

  /// Full URL for loading the photo (prepends API base URL to relative path).
  String get fullUrl {
    if (photoUrl.startsWith('http')) return photoUrl;
    return '${ApiConfig.fullApiUrl}$photoUrl';
  }

  factory SiteReportPhoto.fromJson(Map<String, dynamic> json) {
    return SiteReportPhoto(
      id: json['id'] as int?,
      photoUrl: json['photoUrl'] as String? ?? '',
      storagePath: json['storagePath'] as String? ?? '',
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) : null,
      caption: json['caption'] as String?,
      latitude: json['latitude'] != null ? (json['latitude'] as num).toDouble() : null,
      longitude: json['longitude'] != null ? (json['longitude'] as num).toDouble() : null,
      displayOrder: json['displayOrder'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'photoUrl': photoUrl,
      'storagePath': storagePath,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (caption != null) 'caption': caption,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      'displayOrder': displayOrder,
    };
  }
}

class SiteReport {
  final int? id;
  final int projectId;
  final String? _projectName;
  final String title;
  final String? description;
  final DateTime reportDate;
  final String status;
  final ReportType reportType;
  final int? siteVisitId;
  final List<SiteReportPhoto> photos;
  final String? submittedByName;
  final double? latitude;
  final double? longitude;
  final double? locationAccuracy;
  final double? distanceFromProject;

  SiteReport({
    this.id,
    required this.projectId,
    String? projectName,
    required this.title,
    this.description,
    required this.reportDate,
    required this.status,
    required this.reportType,
    this.siteVisitId,
    this.photos = const [],
    this.submittedByName,
    this.latitude,
    this.longitude,
    this.locationAccuracy,
    this.distanceFromProject,
  }) : _projectName = projectName;

  factory SiteReport.fromJson(Map<String, dynamic> json) {
    // Determine report date from multiple possible fields
    DateTime? parsedDate;
    if (json['reportDate'] != null) parsedDate = DateTime.tryParse(json['reportDate'].toString());
    parsedDate ??= json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) : null;

    // The /search endpoint now returns the flat DTO shape
    // (projectId/projectName/submittedByName as direct fields). Some legacy
    // endpoints still return the entity shape (project: {id, name},
    // submittedBy: {firstName, lastName}). Read flat first, then fall back
    // to nested so both shapes parse cleanly.
    int? flatProjectId = json['projectId'] as int?;
    int parsedProjectId = flatProjectId
        ?? (json['project'] is Map ? (json['project']['id'] as int? ?? 0) : 0);
    String? parsedProjectName = json['projectName'] as String?
        ?? (json['project'] is Map ? json['project']['name'] as String? : null);

    String? parsedSubmittedByName = json['submittedByName'] as String?;
    if ((parsedSubmittedByName == null || parsedSubmittedByName.isEmpty)
        && json['submittedBy'] is Map) {
      final sb = json['submittedBy'] as Map;
      parsedSubmittedByName = ('${sb['firstName'] ?? ''} ${sb['lastName'] ?? ''}').trim();
      if (parsedSubmittedByName.isEmpty) parsedSubmittedByName = null;
    }

    int? parsedSiteVisitId = json['siteVisitId'] as int?
        ?? (json['siteVisit'] is Map ? json['siteVisit']['id'] as int? : null);

    return SiteReport(
      id: json['id'] as int?,
      projectId: parsedProjectId,
      projectName: parsedProjectName,
      title: json['title'] as String? ?? 'Untitled Report',
      description: json['description'] as String?,
      reportDate: parsedDate ?? DateTime.now(),
      status: json['status'] as String? ?? 'SUBMITTED',
      reportType: ReportType.fromJson(json['reportType']),
      siteVisitId: parsedSiteVisitId,
      photos: (json['photos'] as List? ?? [])
          .map((p) => SiteReportPhoto.fromJson(p))
          .toList(),
      submittedByName: parsedSubmittedByName,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      locationAccuracy: (json['locationAccuracy'] as num?)?.toDouble(),
      distanceFromProject: (json['distanceFromProject'] as num?)?.toDouble(),
    );
  }

  String get formattedDate => DateFormat('dd MMM yyyy, hh:mm a').format(reportDate);

  /// Project name when provided by API (DTO shape) or null (legacy entity shape).
  String? get projectName => _projectName;

  /// Alias for description (used by site_reports_screen).
  String? get summary => description;

  /// Alias for submittedByName (used by site_reports_screen).
  String? get reportedByName => submittedByName;

  /// Weather condition when provided by API (optional).
  String? get weatherCondition => null;

  /// Labour count when provided by API (optional).
  int? get labourCount => null;
}

