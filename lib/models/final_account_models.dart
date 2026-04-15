// Models for Final Account —
// maps to Portal API FinalAccountDtos.java

class FinalAccountData {
  final int id;
  final int? projectId;
  final double baseContractValue;
  final double totalAdditions;
  final double totalAcceptedDeductions;
  final double netRevisedContractValue;
  final double totalReceivedToDate;
  final double totalRetentionHeld;
  final double balancePayable;
  final String status;
  final String? dlpStartDate;
  final String? dlpEndDate;
  final bool retentionReleased;
  final String? retentionReleaseDate;
  final String? preparedBy;
  final String? agreedBy;
  final String? createdAt;
  final String? updatedAt;

  const FinalAccountData({
    required this.id,
    this.projectId,
    required this.baseContractValue,
    required this.totalAdditions,
    required this.totalAcceptedDeductions,
    required this.netRevisedContractValue,
    required this.totalReceivedToDate,
    required this.totalRetentionHeld,
    required this.balancePayable,
    required this.status,
    this.dlpStartDate,
    this.dlpEndDate,
    required this.retentionReleased,
    this.retentionReleaseDate,
    this.preparedBy,
    this.agreedBy,
    this.createdAt,
    this.updatedAt,
  });

  bool get isDraft     => status == 'DRAFT';
  bool get isSubmitted => status == 'SUBMITTED';
  bool get isDisputed  => status == 'DISPUTED';
  bool get isAgreed    => status == 'AGREED';
  bool get isClosed    => status == 'CLOSED';

  factory FinalAccountData.fromJson(Map<String, dynamic> json) {
    return FinalAccountData(
      id: json['id'],
      projectId: json['projectId'],
      baseContractValue: (json['baseContractValue'] as num?)?.toDouble() ?? 0.0,
      totalAdditions: (json['totalAdditions'] as num?)?.toDouble() ?? 0.0,
      totalAcceptedDeductions: (json['totalAcceptedDeductions'] as num?)?.toDouble() ?? 0.0,
      netRevisedContractValue: (json['netRevisedContractValue'] as num?)?.toDouble() ?? 0.0,
      totalReceivedToDate: (json['totalReceivedToDate'] as num?)?.toDouble() ?? 0.0,
      totalRetentionHeld: (json['totalRetentionHeld'] as num?)?.toDouble() ?? 0.0,
      balancePayable: (json['balancePayable'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] ?? 'DRAFT',
      dlpStartDate: json['dlpStartDate'],
      dlpEndDate: json['dlpEndDate'],
      retentionReleased: json['retentionReleased'] == true,
      retentionReleaseDate: json['retentionReleaseDate'],
      preparedBy: json['preparedBy'],
      agreedBy: json['agreedBy'],
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
    );
  }
}

// ---- Request payloads ----

class CreateFinalAccountRequest {
  final double baseContractValue;
  final double? totalAdditions;
  final double? totalAcceptedDeductions;
  final double? totalReceivedToDate;
  final double? totalRetentionHeld;
  final String? dlpStartDate;
  final String? dlpEndDate;
  final String preparedBy;

  const CreateFinalAccountRequest({
    required this.baseContractValue,
    this.totalAdditions,
    this.totalAcceptedDeductions,
    this.totalReceivedToDate,
    this.totalRetentionHeld,
    this.dlpStartDate,
    this.dlpEndDate,
    required this.preparedBy,
  });

  Map<String, dynamic> toJson() => {
        'baseContractValue': baseContractValue,
        if (totalAdditions != null) 'totalAdditions': totalAdditions,
        if (totalAcceptedDeductions != null)
          'totalAcceptedDeductions': totalAcceptedDeductions,
        if (totalReceivedToDate != null) 'totalReceivedToDate': totalReceivedToDate,
        if (totalRetentionHeld != null) 'totalRetentionHeld': totalRetentionHeld,
        if (dlpStartDate != null) 'dlpStartDate': dlpStartDate,
        if (dlpEndDate != null) 'dlpEndDate': dlpEndDate,
        'preparedBy': preparedBy,
      };
}

class FinalAccountStatusRequest {
  final String targetStatus;
  final String? agreedBy;
  final String? comment;

  const FinalAccountStatusRequest({
    required this.targetStatus,
    this.agreedBy,
    this.comment,
  });

  Map<String, dynamic> toJson() => {
        'targetStatus': targetStatus,
        if (agreedBy != null) 'agreedBy': agreedBy,
        if (comment != null) 'comment': comment,
      };
}

class ReleaseRetentionRequest {
  final String releaseDate;
  final String releasedBy;

  const ReleaseRetentionRequest({
    required this.releaseDate,
    required this.releasedBy,
  });

  Map<String, dynamic> toJson() => {
        'releaseDate': releaseDate,
        'releasedBy': releasedBy,
      };
}
