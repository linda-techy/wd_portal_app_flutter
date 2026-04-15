// Models for Deduction Register —
// maps to Portal API DeductionRegisterDtos.java

class DeductionRegisterEntry {
  final int id;
  final int? projectId;
  final int? coId;
  final String itemDescription;
  final double requestedAmount;
  final double? acceptedAmount;
  final String decision;
  final String? rejectionReason;
  final String escalationStatus;
  final String? escalatedTo;
  final bool settledInFinalAccount;
  final String? approvedBy;
  final String? decisionDate;
  final String? createdAt;
  final String? updatedAt;

  const DeductionRegisterEntry({
    required this.id,
    this.projectId,
    this.coId,
    required this.itemDescription,
    required this.requestedAmount,
    this.acceptedAmount,
    required this.decision,
    this.rejectionReason,
    required this.escalationStatus,
    this.escalatedTo,
    required this.settledInFinalAccount,
    this.approvedBy,
    this.decisionDate,
    this.createdAt,
    this.updatedAt,
  });

  bool get isPending => decision == 'PENDING';
  bool get isAccepted =>
      decision == 'ACCEPTABLE' || decision == 'PARTIALLY_ACCEPTABLE';
  bool get isEscalated => escalationStatus == 'ESCALATED';

  factory DeductionRegisterEntry.fromJson(Map<String, dynamic> json) {
    return DeductionRegisterEntry(
      id: json['id'],
      projectId: json['projectId'],
      coId: json['coId'],
      itemDescription: json['itemDescription'] ?? '',
      requestedAmount: (json['requestedAmount'] as num?)?.toDouble() ?? 0.0,
      acceptedAmount: (json['acceptedAmount'] as num?)?.toDouble(),
      decision: json['decision'] ?? 'PENDING',
      rejectionReason: json['rejectionReason'],
      escalationStatus: json['escalationStatus'] ?? 'NONE',
      escalatedTo: json['escalatedTo'],
      settledInFinalAccount: json['settledInFinalAccount'] == true,
      approvedBy: json['approvedBy'],
      decisionDate: json['decisionDate'],
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
    );
  }
}

// ---- Request payloads ----

class CreateDeductionRequest {
  final int? coId;
  final String itemDescription;
  final double requestedAmount;

  const CreateDeductionRequest({
    this.coId,
    required this.itemDescription,
    required this.requestedAmount,
  });

  Map<String, dynamic> toJson() => {
        if (coId != null) 'coId': coId,
        'itemDescription': itemDescription,
        'requestedAmount': requestedAmount,
      };
}

class DeductionDecisionRequest {
  final String decision; // ACCEPTABLE | PARTIALLY_ACCEPTABLE | REJECTED
  final double? acceptedAmount;
  final String? rejectionReason;
  final String approvedBy;
  final String? decisionDate;

  const DeductionDecisionRequest({
    required this.decision,
    this.acceptedAmount,
    this.rejectionReason,
    required this.approvedBy,
    this.decisionDate,
  });

  Map<String, dynamic> toJson() => {
        'decision': decision,
        if (acceptedAmount != null) 'acceptedAmount': acceptedAmount,
        if (rejectionReason != null) 'rejectionReason': rejectionReason,
        'approvedBy': approvedBy,
        if (decisionDate != null) 'decisionDate': decisionDate,
      };
}

class EscalateDeductionRequest {
  final String escalatedTo;
  final String? comment;

  const EscalateDeductionRequest({required this.escalatedTo, this.comment});

  Map<String, dynamic> toJson() => {
        'escalatedTo': escalatedTo,
        if (comment != null) 'comment': comment,
      };
}
