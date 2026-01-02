import 'dart:convert';

class ChangeOrder {
  final int? id;
  final int projectId;
  final String description;
  final double estimatedAmount;
  final bool clientApproved;
  final String status; // DRAFT, PENDING_APPROVAL, APPROVED, REJECTED
  final String? notes;
  final DateTime? createdAt;
  final DateTime? approvedAt;

  ChangeOrder({
    this.id,
    required this.projectId,
    required this.description,
    required this.estimatedAmount,
    this.clientApproved = false,
    this.status = 'DRAFT',
    this.notes,
    this.createdAt,
    this.approvedAt,
  });

  factory ChangeOrder.fromJson(Map<String, dynamic> json) {
    return ChangeOrder(
      id: json['id'],
      projectId: json['project'] != null ? json['project']['id'] : 0, // Handle nested project object if needed
      description: json['description'],
      estimatedAmount: (json['estimatedAmount'] as num).toDouble(),
      clientApproved: json['clientApproved'] ?? false,
      status: json['status'] ?? 'DRAFT',
      notes: json['notes'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      approvedAt: json['approved_at'] != null ? DateTime.parse(json['approved_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'project': {'id': projectId}, // Send as object reference usually expected by JPA
      'description': description,
      'estimatedAmount': estimatedAmount,
      'clientApproved': clientApproved,
      'status': status,
      'notes': notes,
    };
  }

  ChangeOrder copyWith({
    int? id,
    int? projectId,
    String? description,
    double? estimatedAmount,
    bool? clientApproved,
    String? status,
    String? notes,
  }) {
    return ChangeOrder(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      description: description ?? this.description,
      estimatedAmount: estimatedAmount ?? this.estimatedAmount,
      clientApproved: clientApproved ?? this.clientApproved,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: this.createdAt,
      approvedAt: this.approvedAt,
    );
  }
}
