class VendorQuotation {
  final int? id;
  final int indentId;
  final int vendorId;
  final double quotedAmount;
  final String? itemsIncluded;
  final double? deliveryCharges;
  final double? taxAmount;
  final DateTime? expectedDeliveryDate;
  final DateTime? validUntil;
  final String? documentUrl;
  final String? notes;
  final String status; // PENDING, SELECTED, REJECTED, EXPIRED
  final DateTime? selectedAt;
  final DateTime? createdAt;

  // Transient/UI fields
  final String? vendorName;

  VendorQuotation({
    this.id,
    required this.indentId,
    required this.vendorId,
    required this.quotedAmount,
    this.itemsIncluded,
    this.deliveryCharges,
    this.taxAmount,
    this.expectedDeliveryDate,
    this.validUntil,
    this.documentUrl,
    this.notes,
    this.status = 'PENDING',
    this.selectedAt,
    this.createdAt,
    this.vendorName,
  });

  factory VendorQuotation.fromJson(Map<String, dynamic> json) {
    return VendorQuotation(
      id: json['id'],
      indentId: json['indentId'] ?? json['indent']?['id'],
      vendorId: json['vendorId'] ?? json['vendor']?['id'],
      quotedAmount: (json['quotedAmount'] as num).toDouble(),
      itemsIncluded: json['itemsIncluded'],
      deliveryCharges: json['deliveryCharges'] != null
          ? (json['deliveryCharges'] as num).toDouble()
          : null,
      taxAmount: json['taxAmount'] != null
          ? (json['taxAmount'] as num).toDouble()
          : null,
      expectedDeliveryDate: json['expectedDeliveryDate'] != null
          ? DateTime.parse(json['expectedDeliveryDate'])
          : null,
      validUntil: json['validUntil'] != null
          ? DateTime.parse(json['validUntil'])
          : null,
      documentUrl: json['documentUrl'],
      notes: json['notes'],
      status: json['status'] ?? 'PENDING',
      selectedAt: json['selectedAt'] != null
          ? DateTime.parse(json['selectedAt'])
          : null,
      createdAt:
          json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      vendorName: json['vendor']?['name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'indentId': indentId,
      'vendorId': vendorId,
      'quotedAmount': quotedAmount,
      'itemsIncluded': itemsIncluded,
      'deliveryCharges': deliveryCharges,
      'taxAmount': taxAmount,
      'expectedDeliveryDate':
          expectedDeliveryDate?.toIso8601String().split('T')[0],
      'validUntil': validUntil?.toIso8601String().split('T')[0],
      'documentUrl': documentUrl,
      'notes': notes,
      'status': status,
    };
  }
}
