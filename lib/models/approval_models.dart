class ApprovalRequest {
  final int? id;
  final String targetType;
  final int targetId;
  final String? targetName;
  final int requestedById;
  final String? requestedByName;
  final int? approverId;
  final String? approverName;
  final String status;
  final String? comments;
  final String requestedAt;
  final String? decidedAt;

  ApprovalRequest({
    this.id,
    required this.targetType,
    required this.targetId,
    this.targetName,
    required this.requestedById,
    this.requestedByName,
    this.approverId,
    this.approverName,
    this.status = 'PENDING',
    this.comments,
    required this.requestedAt,
    this.decidedAt,
  });

  factory ApprovalRequest.fromJson(Map<String, dynamic> json) {
    return ApprovalRequest(
      id: json['id'],
      targetType: json['targetType'],
      targetId: json['targetId'],
      targetName: json['targetName'],
      requestedById: json['requestedById'],
      requestedByName: json['requestedByName'],
      approverId: json['approverId'],
      approverName: json['approverName'],
      status: json['status'],
      comments: json['comments'],
      requestedAt: json['requestedAt'],
      decidedAt: json['decidedAt'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'targetType': targetType,
      'targetId': targetId,
      'requestedById': requestedById,
      if (approverId != null) 'approverId': approverId,
      'status': status,
      if (comments != null) 'comments': comments,
    };
  }

  /// Display label for request type (alias for targetType).
  String? get requestType => targetType;

  /// Entity type for display (targetName or targetType).
  String get entityType => targetName ?? targetType;

  /// Request date parsed from requestedAt string.
  DateTime? get requestDate => DateTime.tryParse(requestedAt);

  /// Priority when provided by API (optional).
  String? get priority => null;
}
