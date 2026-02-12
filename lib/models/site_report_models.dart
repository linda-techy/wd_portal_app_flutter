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

    return map[json] ?? 
           // Try camelCase match if backend sends camelCase
           ReportType.values.firstWhere(
             (e) => e.name == json,
             orElse: () => ReportType.other, // Safer default than dailyProgress to avoid masking errors
           );
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

  SiteReportPhoto({
    this.id,
    required this.photoUrl,
    required this.storagePath,
    this.createdAt,
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
    );
  }
}

class SiteReport {
  final int? id;
  final int projectId;
  final String title;
  final String? description;
  final DateTime reportDate;
  final String status;
  final ReportType reportType;
  final int? siteVisitId;
  final List<SiteReportPhoto> photos;
  final String? submittedByName;

  SiteReport({
    this.id,
    required this.projectId,
    required this.title,
    this.description,
    required this.reportDate,
    required this.status,
    required this.reportType,
    this.siteVisitId,
    this.photos = const [],
    this.submittedByName,
  });

  factory SiteReport.fromJson(Map<String, dynamic> json) {
    // Determine report date from multiple possible fields
    DateTime? parsedDate;
    if (json['reportDate'] != null) parsedDate = DateTime.tryParse(json['reportDate'].toString());
    parsedDate ??= json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) : null;

    return SiteReport(
      id: json['id'] as int?,
      projectId: json['project'] != null ? (json['project']['id'] as int? ?? 0) : 0,
      title: json['title'] as String? ?? 'Untitled Report',
      description: json['description'] as String?,
      reportDate: parsedDate ?? DateTime.now(),
      status: json['status'] as String? ?? 'SUBMITTED',
      reportType: ReportType.fromJson(json['reportType']),
      siteVisitId: json['siteVisit'] != null ? (json['siteVisit']['id'] as int?) : null,
      photos: (json['photos'] as List? ?? [])
          .map((p) => SiteReportPhoto.fromJson(p))
          .toList(),
      submittedByName: json['submittedBy'] != null 
          ? '${json['submittedBy']['firstName'] ?? ''} ${json['submittedBy']['lastName'] ?? ''}'.trim()
          : null,
    );
  }

  String get formattedDate => DateFormat('dd MMM yyyy, hh:mm a').format(reportDate);

  /// Project name when provided by API (e.g. from expanded project).
  String? get projectName => null;

  /// Alias for description (used by site_reports_screen).
  String? get summary => description;

  /// Alias for submittedByName (used by site_reports_screen).
  String? get reportedByName => submittedByName;

  /// Weather condition when provided by API (optional).
  String? get weatherCondition => null;

  /// Labour count when provided by API (optional).
  int? get labourCount => null;
}

