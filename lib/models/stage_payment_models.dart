// Models for Stage Payment certification and retention —
// maps to Portal API StagePaymentDtos.java

class StageTimelineSummary {
  final int id;
  final int stageNumber;
  final String stageName;
  final double stageAmountInclGst;
  final double netPayableAmount;
  final double? retentionHeld;
  final String status;
  final String? dueDate;
  final bool certified;
  final String? certifiedAt;

  const StageTimelineSummary({
    required this.id,
    required this.stageNumber,
    required this.stageName,
    required this.stageAmountInclGst,
    required this.netPayableAmount,
    this.retentionHeld,
    required this.status,
    this.dueDate,
    required this.certified,
    this.certifiedAt,
  });

  factory StageTimelineSummary.fromJson(Map<String, dynamic> json) {
    return StageTimelineSummary(
      id: json['id'],
      stageNumber: json['stageNumber'] ?? 0,
      stageName: json['stageName'] ?? '',
      stageAmountInclGst: (json['stageAmountInclGst'] as num?)?.toDouble() ?? 0.0,
      netPayableAmount: (json['netPayableAmount'] as num?)?.toDouble() ?? 0.0,
      retentionHeld: (json['retentionHeld'] as num?)?.toDouble(),
      status: json['status'] ?? 'UPCOMING',
      dueDate: json['dueDate'],
      certified: json['certified'] == true,
      certifiedAt: json['certifiedAt'],
    );
  }
}

class StageCertificationDetail {
  final int id;
  final int? projectId;
  final int stageNumber;
  final String stageName;
  final double stageAmountExGst;
  final double stageAmountInclGst;
  final double appliedCreditAmount;
  final double netPayableAmount;
  final double paidAmount;
  final String status;
  final String? dueDate;
  final String? milestoneDescription;
  final int? invoiceId;
  final String? paidAt;
  final String? certifiedBy;
  final double? retentionPct;
  final double? retentionHeld;
  final String? certifiedAt;

  const StageCertificationDetail({
    required this.id,
    this.projectId,
    required this.stageNumber,
    required this.stageName,
    required this.stageAmountExGst,
    required this.stageAmountInclGst,
    required this.appliedCreditAmount,
    required this.netPayableAmount,
    required this.paidAmount,
    required this.status,
    this.dueDate,
    this.milestoneDescription,
    this.invoiceId,
    this.paidAt,
    this.certifiedBy,
    this.retentionPct,
    this.retentionHeld,
    this.certifiedAt,
  });

  factory StageCertificationDetail.fromJson(Map<String, dynamic> json) {
    return StageCertificationDetail(
      id: json['id'],
      projectId: json['projectId'],
      stageNumber: json['stageNumber'] ?? 0,
      stageName: json['stageName'] ?? '',
      stageAmountExGst: (json['stageAmountExGst'] as num?)?.toDouble() ?? 0.0,
      stageAmountInclGst: (json['stageAmountInclGst'] as num?)?.toDouble() ?? 0.0,
      appliedCreditAmount: (json['appliedCreditAmount'] as num?)?.toDouble() ?? 0.0,
      netPayableAmount: (json['netPayableAmount'] as num?)?.toDouble() ?? 0.0,
      paidAmount: (json['paidAmount'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] ?? 'UPCOMING',
      dueDate: json['dueDate'],
      milestoneDescription: json['milestoneDescription'],
      invoiceId: json['invoiceId'],
      paidAt: json['paidAt'],
      certifiedBy: json['certifiedBy'],
      retentionPct: (json['retentionPct'] as num?)?.toDouble(),
      retentionHeld: (json['retentionHeld'] as num?)?.toDouble(),
      certifiedAt: json['certifiedAt'],
    );
  }
}

// ---- Request payloads ----

class CertifyStageRequest {
  final String certifiedBy;
  final double? retentionPct;

  const CertifyStageRequest({required this.certifiedBy, this.retentionPct});

  Map<String, dynamic> toJson() => {
        'certifiedBy': certifiedBy,
        if (retentionPct != null) 'retentionPct': retentionPct,
      };
}

class RecordStagePaymentRequest {
  final double paidAmount;
  final String? paidDate;

  const RecordStagePaymentRequest({required this.paidAmount, this.paidDate});

  Map<String, dynamic> toJson() => {
        'paidAmount': paidAmount,
        if (paidDate != null) 'paidDate': paidDate,
      };
}
