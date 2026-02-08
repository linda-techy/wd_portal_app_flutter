import 'package:intl/intl.dart';

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
      reportType: ReportType.values.firstWhere(
        (e) => e.name == json['reportType'],
        orElse: () => ReportType.dailyProgress,
      ),
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

