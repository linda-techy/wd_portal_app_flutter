import 'package:flutter/foundation.dart';
import 'package:admin/features/estimation_settings/data/models/package_rate_version.dart';
import 'package:admin/features/lead_estimation/data/models/estimation_sub_resource.dart';

enum LeadEstimationStatus { DRAFT, SENT, ACCEPTED, REJECTED }

@immutable
class LeadEstimationLineItem {
  final String lineType;
  final String description;
  final String? sourceRefId;
  final num? quantity;
  final String? unit;
  final num? unitRate;
  final num amount;
  final int displayOrder;

  const LeadEstimationLineItem({
    required this.lineType,
    required this.description,
    this.sourceRefId,
    this.quantity,
    this.unit,
    this.unitRate,
    required this.amount,
    required this.displayOrder,
  });

  factory LeadEstimationLineItem.fromJson(Map<String, dynamic> json) {
    return LeadEstimationLineItem(
      lineType: json['lineType'] as String,
      description: json['description'] as String,
      sourceRefId: json['sourceRefId'] as String?,
      quantity: json['quantity'] as num?,
      unit: json['unit'] as String?,
      unitRate: json['unitRate'] as num?,
      amount: json['amount'] as num,
      displayOrder: json['displayOrder'] as int,
    );
  }
}

@immutable
class LeadEstimationSummary {
  final String id;
  final String estimationNo;
  final int leadId;
  final ProjectType projectType;
  final String? packageId;
  final LeadEstimationStatus status;
  final double grandTotal;
  final DateTime? validUntil;
  final DateTime createdAt;

  const LeadEstimationSummary({
    required this.id,
    required this.estimationNo,
    required this.leadId,
    required this.projectType,
    this.packageId,
    required this.status,
    required this.grandTotal,
    this.validUntil,
    required this.createdAt,
  });

  factory LeadEstimationSummary.fromJson(Map<String, dynamic> json) {
    return LeadEstimationSummary(
      id: json['id'] as String,
      estimationNo: json['estimationNo'] as String,
      leadId: (json['leadId'] as num).toInt(),
      projectType: ProjectType.values.byName(json['projectType'] as String),
      packageId: json['packageId'] as String?,
      status: LeadEstimationStatus.values.byName(json['status'] as String),
      grandTotal: (json['grandTotal'] as num).toDouble(),
      validUntil: json['validUntil'] != null
          ? DateTime.parse(json['validUntil'] as String)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

@immutable
class LeadEstimationDetail {
  final String id;
  final String estimationNo;
  final int leadId;
  final ProjectType projectType;
  final String? packageId;
  final String? rateVersionId;
  final String? marketIndexId;
  final LeadEstimationStatus status;
  final double subtotal;
  final double discountAmount;
  final double gstAmount;
  final double grandTotal;
  final DateTime? validUntil;
  final DateTime createdAt;
  final List<LeadEstimationLineItem> lineItems;
  final List<EstimationSubResource> inclusions;
  final List<EstimationSubResource> exclusions;
  final List<EstimationSubResource> assumptions;
  final List<EstimationSubResource> paymentMilestones;

  const LeadEstimationDetail({
    required this.id,
    required this.estimationNo,
    required this.leadId,
    required this.projectType,
    this.packageId,
    this.rateVersionId,
    this.marketIndexId,
    required this.status,
    required this.subtotal,
    required this.discountAmount,
    required this.gstAmount,
    required this.grandTotal,
    this.validUntil,
    required this.createdAt,
    required this.lineItems,
    this.inclusions = const [],
    this.exclusions = const [],
    this.assumptions = const [],
    this.paymentMilestones = const [],
  });

  factory LeadEstimationDetail.fromJson(Map<String, dynamic> json) {
    return LeadEstimationDetail(
      id: json['id'] as String,
      estimationNo: json['estimationNo'] as String,
      leadId: (json['leadId'] as num).toInt(),
      projectType: ProjectType.values.byName(json['projectType'] as String),
      packageId: json['packageId'] as String?,
      rateVersionId: json['rateVersionId'] as String?,
      marketIndexId: json['marketIndexId'] as String?,
      status: LeadEstimationStatus.values.byName(json['status'] as String),
      subtotal: (json['subtotal'] as num).toDouble(),
      discountAmount: (json['discountAmount'] as num).toDouble(),
      gstAmount: (json['gstAmount'] as num).toDouble(),
      grandTotal: (json['grandTotal'] as num).toDouble(),
      validUntil: json['validUntil'] != null
          ? DateTime.parse(json['validUntil'] as String)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lineItems: (json['lineItems'] as List<dynamic>)
          .map((j) => LeadEstimationLineItem.fromJson(j as Map<String, dynamic>))
          .toList(),
      inclusions: ((json['inclusions'] as List<dynamic>?) ?? [])
          .map((j) => EstimationSubResource.fromJson(j as Map<String, dynamic>))
          .toList(),
      exclusions: ((json['exclusions'] as List<dynamic>?) ?? [])
          .map((j) => EstimationSubResource.fromJson(j as Map<String, dynamic>))
          .toList(),
      assumptions: ((json['assumptions'] as List<dynamic>?) ?? [])
          .map((j) => EstimationSubResource.fromJson(j as Map<String, dynamic>))
          .toList(),
      paymentMilestones: ((json['paymentMilestones'] as List<dynamic>?) ?? [])
          .map((j) => EstimationSubResource.fromJson(j as Map<String, dynamic>))
          .toList(),
    );
  }

  /// Build the POST body for /api/lead-estimations.
  /// `previewPayload` is the raw map from a CalculatePreviewRequest (you can
  /// build it inline from the wizard's draft state).
  static Map<String, dynamic> createPayload({
    required int leadId,
    required Map<String, dynamic> previewPayload,
    DateTime? validUntil,
  }) {
    return {
      'leadId': leadId,
      'preview': previewPayload,
      if (validUntil != null)
        'validUntil': validUntil.toIso8601String().substring(0, 10),
    };
  }
}
