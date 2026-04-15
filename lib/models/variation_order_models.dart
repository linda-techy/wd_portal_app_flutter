// Models for Variation Order (VO) lifecycle —
// maps to Portal API VariationOrderDtos.java

class VariationOrderSummary {
  final int id;
  final String referenceNumber;
  final String title;
  final String? coType;
  final String status;
  final String? voCategory;
  final double? netAmountInclGst;
  final double? approvedCost;
  final String? submittedAt;
  final String? approvedAt;
  final String? createdAt;

  const VariationOrderSummary({
    required this.id,
    required this.referenceNumber,
    required this.title,
    this.coType,
    required this.status,
    this.voCategory,
    this.netAmountInclGst,
    this.approvedCost,
    this.submittedAt,
    this.approvedAt,
    this.createdAt,
  });

  factory VariationOrderSummary.fromJson(Map<String, dynamic> json) {
    return VariationOrderSummary(
      id: json['id'],
      referenceNumber: json['referenceNumber'] ?? '',
      title: json['title'] ?? '',
      coType: json['coType'],
      status: json['status'] ?? 'DRAFT',
      voCategory: json['voCategory'],
      netAmountInclGst: (json['netAmountInclGst'] as num?)?.toDouble(),
      approvedCost: (json['approvedCost'] as num?)?.toDouble(),
      submittedAt: json['submittedAt'],
      approvedAt: json['approvedAt'],
      createdAt: json['createdAt'],
    );
  }
}

class ApprovalHistoryEntry {
  final int id;
  final String approverName;
  final int? approverId;
  final String? level;
  final String? action;
  final String? comment;
  final String? actionAt;

  const ApprovalHistoryEntry({
    required this.id,
    required this.approverName,
    this.approverId,
    this.level,
    this.action,
    this.comment,
    this.actionAt,
  });

  factory ApprovalHistoryEntry.fromJson(Map<String, dynamic> json) {
    return ApprovalHistoryEntry(
      id: json['id'],
      approverName: json['approverName'] ?? '',
      approverId: json['approverId'],
      level: json['level'],
      action: json['action'],
      comment: json['comment'],
      actionAt: json['actionAt'],
    );
  }
}

class VOPaymentSchedule {
  final int id;
  final int advancePct;
  final double advanceAmount;
  final String advanceStatus;
  final String? advanceDueDate;
  final String? advancePaidDate;
  final String? advanceInvoiceNumber;
  final int progressPct;
  final double progressAmount;
  final String progressStatus;
  final int? progressTriggerStageId;
  final String? progressPaidDate;
  final int completionPct;
  final double completionAmount;
  final String completionStatus;
  final String? completionTrigger;
  final String? completionPaidDate;

  const VOPaymentSchedule({
    required this.id,
    required this.advancePct,
    required this.advanceAmount,
    required this.advanceStatus,
    this.advanceDueDate,
    this.advancePaidDate,
    this.advanceInvoiceNumber,
    required this.progressPct,
    required this.progressAmount,
    required this.progressStatus,
    this.progressTriggerStageId,
    this.progressPaidDate,
    required this.completionPct,
    required this.completionAmount,
    required this.completionStatus,
    this.completionTrigger,
    this.completionPaidDate,
  });

  factory VOPaymentSchedule.fromJson(Map<String, dynamic> json) {
    return VOPaymentSchedule(
      id: json['id'],
      advancePct: json['advancePct'] ?? 0,
      advanceAmount: (json['advanceAmount'] as num?)?.toDouble() ?? 0.0,
      advanceStatus: json['advanceStatus'] ?? 'PENDING',
      advanceDueDate: json['advanceDueDate'],
      advancePaidDate: json['advancePaidDate'],
      advanceInvoiceNumber: json['advanceInvoiceNumber'],
      progressPct: json['progressPct'] ?? 0,
      progressAmount: (json['progressAmount'] as num?)?.toDouble() ?? 0.0,
      progressStatus: json['progressStatus'] ?? 'PENDING',
      progressTriggerStageId: json['progressTriggerStageId'],
      progressPaidDate: json['progressPaidDate'],
      completionPct: json['completionPct'] ?? 0,
      completionAmount: (json['completionAmount'] as num?)?.toDouble() ?? 0.0,
      completionStatus: json['completionStatus'] ?? 'PENDING',
      completionTrigger: json['completionTrigger'],
      completionPaidDate: json['completionPaidDate'],
    );
  }
}

class VariationOrderDetail {
  final int id;
  final int? projectId;
  final int? boqDocumentId;
  final String referenceNumber;
  final String? coType;
  final String status;
  final String title;
  final String? description;
  final String? justification;
  final String? scopeNotes;
  final String? voCategory;
  final int? revisesCoId;
  final double? netAmountExGst;
  final double? gstRate;
  final double? gstAmount;
  final double netAmountInclGst;
  final double? approvedCost;
  final bool advanceCollected;
  final String? submittedAt;
  final String? approvedAt;
  final String? rejectedAt;
  final String? rejectionReason;
  final String? reviewDeadline;
  final String? createdAt;
  final List<ApprovalHistoryEntry> approvalHistory;
  final VOPaymentSchedule? paymentSchedule;

  const VariationOrderDetail({
    required this.id,
    this.projectId,
    this.boqDocumentId,
    required this.referenceNumber,
    this.coType,
    required this.status,
    required this.title,
    this.description,
    this.justification,
    this.scopeNotes,
    this.voCategory,
    this.revisesCoId,
    this.netAmountExGst,
    this.gstRate,
    this.gstAmount,
    required this.netAmountInclGst,
    this.approvedCost,
    required this.advanceCollected,
    this.submittedAt,
    this.approvedAt,
    this.rejectedAt,
    this.rejectionReason,
    this.reviewDeadline,
    this.createdAt,
    required this.approvalHistory,
    this.paymentSchedule,
  });

  factory VariationOrderDetail.fromJson(Map<String, dynamic> json) {
    final historyJson = json['approvalHistory'] as List? ?? [];
    final schedJson = json['paymentSchedule'];
    return VariationOrderDetail(
      id: json['id'],
      projectId: json['projectId'],
      boqDocumentId: json['boqDocumentId'],
      referenceNumber: json['referenceNumber'] ?? '',
      coType: json['coType'],
      status: json['status'] ?? 'DRAFT',
      title: json['title'] ?? '',
      description: json['description'],
      justification: json['justification'],
      scopeNotes: json['scopeNotes'],
      voCategory: json['voCategory'],
      revisesCoId: json['revisesCoId'],
      netAmountExGst: (json['netAmountExGst'] as num?)?.toDouble(),
      gstRate: (json['gstRate'] as num?)?.toDouble(),
      gstAmount: (json['gstAmount'] as num?)?.toDouble(),
      netAmountInclGst: (json['netAmountInclGst'] as num?)?.toDouble() ?? 0.0,
      approvedCost: (json['approvedCost'] as num?)?.toDouble(),
      advanceCollected: json['advanceCollected'] == true,
      submittedAt: json['submittedAt'],
      approvedAt: json['approvedAt'],
      rejectedAt: json['rejectedAt'],
      rejectionReason: json['rejectionReason'],
      reviewDeadline: json['reviewDeadline'],
      createdAt: json['createdAt'],
      approvalHistory: historyJson
          .map((h) => ApprovalHistoryEntry.fromJson(h as Map<String, dynamic>))
          .toList(),
      paymentSchedule: schedJson != null
          ? VOPaymentSchedule.fromJson(schedJson as Map<String, dynamic>)
          : null,
    );
  }
}

// ---- Request payloads ----

class CreateVariationOrderRequest {
  final int boqDocumentId;
  final String title;
  final String? description;
  final String? justification;
  final String? scopeNotes;
  final String coType;
  final String? voCategory;
  final int? revisesCoId;
  final double netAmountExGst;
  final double? gstRate;
  final String? reviewDeadline;

  const CreateVariationOrderRequest({
    required this.boqDocumentId,
    required this.title,
    this.description,
    this.justification,
    this.scopeNotes,
    required this.coType,
    this.voCategory,
    this.revisesCoId,
    required this.netAmountExGst,
    this.gstRate,
    this.reviewDeadline,
  });

  Map<String, dynamic> toJson() => {
        'boqDocumentId': boqDocumentId,
        'title': title,
        if (description != null) 'description': description,
        if (justification != null) 'justification': justification,
        if (scopeNotes != null) 'scopeNotes': scopeNotes,
        'coType': coType,
        if (voCategory != null) 'voCategory': voCategory,
        if (revisesCoId != null) 'revisesCoId': revisesCoId,
        'netAmountExGst': netAmountExGst,
        if (gstRate != null) 'gstRate': gstRate,
        if (reviewDeadline != null) 'reviewDeadline': reviewDeadline,
      };
}

class VOApprovalRequest {
  final String action; // APPROVED | REJECTED | ESCALATED | RETURNED
  final String comment;

  const VOApprovalRequest({required this.action, required this.comment});

  Map<String, dynamic> toJson() => {'action': action, 'comment': comment};
}
