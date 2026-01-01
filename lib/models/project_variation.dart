/// Project Variation model for change orders
class ProjectVariation {
  final int? id;
  final int projectId;
  final String description;
  final double estimatedAmount;
  final bool clientApproved;
  final int? approvedById;
  final DateTime? approvedAt;
  final String status;
  final String? notes;
  final int? createdById;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ProjectVariation({
    this.id,
    required this.projectId,
    required this.description,
    required this.estimatedAmount,
    this.clientApproved = false,
    this.approvedById,
    this.approvedAt,
    this.status = 'DRAFT',
    this.notes,
    this.createdById,
    this.createdAt,
    this.updatedAt,
  });

  factory ProjectVariation.fromJson(Map<String, dynamic> json) {
    return ProjectVariation(
      id: json['id'],
      projectId: json['project']?['id'] ?? json['projectId'] ?? 0,
      description: json['description'] ?? '',
      estimatedAmount: (json['estimatedAmount'] ?? 0).toDouble(),
      clientApproved: json['clientApproved'] ?? false,
      approvedById: json['approvedBy']?['id'] ?? json['approvedById'],
      approvedAt: json['approvedAt'] != null
          ? DateTime.parse(json['approvedAt'])
          : null,
      status: json['status'] ?? 'DRAFT',
      notes: json['notes'],
      createdById: json['createdBy']?['id'] ?? json['createdById'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'projectId': projectId,
      'description': description,
      'estimatedAmount': estimatedAmount,
      'status': status,
      if (notes != null) 'notes': notes,
      if (createdById != null) 'createdById': createdById,
    };
  }

  String get statusDisplay {
    switch (status) {
      case 'DRAFT':
        return 'Draft';
      case 'PENDING_APPROVAL':
        return 'Pending Approval';
      case 'APPROVED':
        return 'Approved';
      case 'REJECTED':
        return 'Rejected';
      default:
        return status;
    }
  }

  bool get canSubmit => status == 'DRAFT';
  bool get canApprove => status == 'PENDING_APPROVAL';
  bool get isApproved => status == 'APPROVED';
  bool get isRejected => status == 'REJECTED';
}
