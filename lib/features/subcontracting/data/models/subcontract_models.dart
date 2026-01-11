class SubcontractWorkOrder {
  final int? id;
  final String workOrderNumber;
  final int projectId;
  final int vendorId;
  final String? vendorName; // Helper for UI
  final String scopeDescription;
  final String measurementBasis;
  final double negotiatedAmount;
  final String status;
  final double retentionPercentage;
  final double totalRetentionAccumulated;
  final String? paymentTerms;

  SubcontractWorkOrder({
    this.id,
    required this.workOrderNumber,
    required this.projectId,
    required this.vendorId,
    this.vendorName,
    required this.scopeDescription,
    this.measurementBasis = 'UNIT_RATE',
    required this.negotiatedAmount,
    this.status = 'DRAFT',
    this.retentionPercentage = 5.0,
    this.totalRetentionAccumulated = 0.0,
    this.paymentTerms,
  });

  factory SubcontractWorkOrder.fromJson(Map<String, dynamic> json) {
    return SubcontractWorkOrder(
      id: json['id'],
      workOrderNumber: json['work_order_number'],
      projectId: json['project'] != null ? json['project']['id'] : 0,
      vendorId: json['vendor'] != null ? json['vendor']['id'] : 0,
      vendorName: json['vendor'] != null ? json['vendor']['name'] : 'Unknown Vendor',
      scopeDescription: json['scope_description'],
      measurementBasis: json['measurement_basis'],
      negotiatedAmount: (json['negotiated_amount'] as num).toDouble(),
      status: json['status'],
      retentionPercentage: (json['retention_percentage'] as num?)?.toDouble() ?? 5.0,
      totalRetentionAccumulated: (json['total_retention_accumulated'] as num?)?.toDouble() ?? 0.0,
      paymentTerms: json['payment_terms'],
    );
  }
}

class RetentionRelease {
  final int? id;
  final int workOrderId;
  final double amountReleased;
  final String releaseDate;
  final String status;
  final String? notes;

  RetentionRelease({
    this.id,
    required this.workOrderId,
    required this.amountReleased,
    required this.releaseDate,
    this.status = 'PENDING',
    this.notes,
  });

  factory RetentionRelease.fromJson(Map<String, dynamic> json) {
    return RetentionRelease(
      id: json['id'],
      workOrderId: json['work_order'] != null ? json['work_order']['id'] : 0,
      amountReleased: (json['amount_released'] as num).toDouble(),
      releaseDate: json['release_date'],
      status: json['status'],
      notes: json['notes'],
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'work_order': {'id': workOrderId},
      'amount_released': amountReleased,
      'release_date': releaseDate,
      'status': status,
      'notes': notes,
    };
  }
}
