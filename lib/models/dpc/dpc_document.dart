import 'dpc_customization_line.dart';
import 'dpc_document_scope.dart';
import 'dpc_master_cost_summary.dart';
import 'dpc_payment_milestone.dart';

/// Top-level DTO for a DPC document.
///
/// Mirrors `DpcDocumentDto` from the backend.
class DpcDocument {
  final int id;
  final int? projectId;
  final int? boqDocumentId;
  final int revisionNumber;

  /// 'DRAFT' | 'ISSUED'
  final String status;

  // Title / subtitle
  final String? titleOverride;
  final String? subtitleOverride;

  // Project header
  final String? projectName;
  final String? projectLocation;
  final String? projectState;
  final String? projectDistrict;
  final String? projectType;
  final double? sqfeet;
  final int? customerId;

  // Signatories
  final String? clientSignatoryName;
  final String? walldotSignatoryName;

  // Walldot contacts
  final int? projectEngineerUserId;
  final String? branchManagerName;
  final String? branchManagerPhone;
  final String? crmTeamName;
  final String? crmTeamPhone;

  // Issue snapshot
  final DateTime? issuedAt;
  final int? issuedByUserId;
  final int? issuedPdfDocumentId;

  // Children
  final List<DpcDocumentScope> scopes;
  final List<DpcCustomizationLine> customizationLines;
  final DpcMasterCostSummary masterCostSummary;
  final List<DpcPaymentMilestone> paymentMilestones;

  // Audit
  final DateTime? createdAt;
  final DateTime? updatedAt;

  DpcDocument({
    required this.id,
    this.projectId,
    this.boqDocumentId,
    this.revisionNumber = 1,
    this.status = 'DRAFT',
    this.titleOverride,
    this.subtitleOverride,
    this.projectName,
    this.projectLocation,
    this.projectState,
    this.projectDistrict,
    this.projectType,
    this.sqfeet,
    this.customerId,
    this.clientSignatoryName,
    this.walldotSignatoryName,
    this.projectEngineerUserId,
    this.branchManagerName,
    this.branchManagerPhone,
    this.crmTeamName,
    this.crmTeamPhone,
    this.issuedAt,
    this.issuedByUserId,
    this.issuedPdfDocumentId,
    this.scopes = const [],
    this.customizationLines = const [],
    DpcMasterCostSummary? masterCostSummary,
    this.paymentMilestones = const [],
    this.createdAt,
    this.updatedAt,
  }) : masterCostSummary = masterCostSummary ?? DpcMasterCostSummary.empty();

  bool get isDraft => status.toUpperCase() == 'DRAFT';
  bool get isIssued => status.toUpperCase() == 'ISSUED';

  /// Customer/project name for header banner. Falls back to project name.
  String get displayCustomerName => projectName ?? '';

  factory DpcDocument.fromJson(Map<String, dynamic> json) {
    int? parseInt(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v);
      return null;
    }

    double? parseDoubleNullable(dynamic v) {
      if (v == null) return null;
      if (v is double) return v;
      if (v is int) return v.toDouble();
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v);
      return null;
    }

    DateTime? parseDate(dynamic v) {
      if (v == null) return null;
      if (v is DateTime) return v;
      if (v is String) {
        try {
          return DateTime.parse(v);
        } catch (_) {
          return null;
        }
      }
      return null;
    }

    final rawScopes = json['scopes'] as List? ?? [];
    final rawLines = json['customizationLines'] as List? ?? [];
    final rawMilestones = json['paymentMilestones'] as List? ?? [];
    final summaryJson = json['masterCostSummary'] as Map<String, dynamic>?;

    return DpcDocument(
      id: parseInt(json['id']) ?? 0,
      projectId: parseInt(json['projectId']),
      boqDocumentId: parseInt(json['boqDocumentId']),
      revisionNumber: parseInt(json['revisionNumber']) ?? 1,
      status: json['status'] as String? ?? 'DRAFT',
      titleOverride: json['titleOverride'] as String?,
      subtitleOverride: json['subtitleOverride'] as String?,
      projectName: json['projectName'] as String?,
      projectLocation: json['projectLocation'] as String?,
      projectState: json['projectState'] as String?,
      projectDistrict: json['projectDistrict'] as String?,
      projectType: json['projectType'] as String?,
      sqfeet: parseDoubleNullable(json['sqfeet']),
      customerId: parseInt(json['customerId']),
      clientSignatoryName: json['clientSignatoryName'] as String?,
      walldotSignatoryName: json['walldotSignatoryName'] as String?,
      projectEngineerUserId: parseInt(json['projectEngineerUserId']),
      branchManagerName: json['branchManagerName'] as String?,
      branchManagerPhone: json['branchManagerPhone'] as String?,
      crmTeamName: json['crmTeamName'] as String?,
      crmTeamPhone: json['crmTeamPhone'] as String?,
      issuedAt: parseDate(json['issuedAt']),
      issuedByUserId: parseInt(json['issuedByUserId']),
      issuedPdfDocumentId: parseInt(json['issuedPdfDocumentId']),
      scopes: rawScopes
          .whereType<Map<String, dynamic>>()
          .map(DpcDocumentScope.fromJson)
          .toList(),
      customizationLines: rawLines
          .whereType<Map<String, dynamic>>()
          .map(DpcCustomizationLine.fromJson)
          .toList(),
      masterCostSummary: summaryJson != null
          ? DpcMasterCostSummary.fromJson(summaryJson)
          : DpcMasterCostSummary.empty(),
      paymentMilestones: rawMilestones
          .whereType<Map<String, dynamic>>()
          .map(DpcPaymentMilestone.fromJson)
          .toList(),
      createdAt: parseDate(json['createdAt']),
      updatedAt: parseDate(json['updatedAt']),
    );
  }
}
