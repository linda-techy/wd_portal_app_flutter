class Vendor {
  final int id;
  final String name;
  final String contactName;
  final String phone;
  final String email;
  final String address;
  final String gstNumber;
  final String vendorType;
  final String status;

  Vendor({
    required this.id,
    required this.name,
    required this.contactName,
    required this.phone,
    required this.email,
    required this.address,
    required this.gstNumber,
    required this.vendorType,
    required this.status,
  });

  factory Vendor.fromJson(Map<String, dynamic> json) {
    return Vendor(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      contactName: json['contactPerson'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'] ?? '',
      address: json['address'] ?? '',
      gstNumber: json['gstin'] ?? '',
      vendorType: json['vendorType'] ?? 'SUPPLIER',
      status: json['status'] ?? 'ACTIVE',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'contactPerson': contactName,
    'phone': phone,
    'email': email,
    'address': address,
    'gstin': gstNumber,
    'vendorType': vendorType,
    'status': status,
  };
}

class PurchaseOrder {
  final int? id;
  final String? poNumber;
  final int projectId;
  final String? projectName;
  final int vendorId;
  final String? vendorName;
  final DateTime poDate;
  final DateTime? expectedDeliveryDate;
  final double totalAmount;
  final double gstAmount;
  final double netAmount;
  final String status;
  final String? notes;
  final int? createdById;
  final List<PurchaseOrderItem> items;

  PurchaseOrder({
    this.id,
    this.poNumber,
    required this.projectId,
    this.projectName,
    required this.vendorId,
    this.vendorName,
    required this.poDate,
    this.expectedDeliveryDate,
    required this.totalAmount,
    this.gstAmount = 0,
    required this.netAmount,
    this.status = 'DRAFT',
    this.notes,
    this.createdById,
    this.items = const [],
  });

  factory PurchaseOrder.fromJson(Map<String, dynamic> json) {
    return PurchaseOrder(
      id: json['id'],
      poNumber: json['poNumber'],
      projectId: json['projectId'],
      projectName: json['projectName'],
      vendorId: json['vendorId'],
      vendorName: json['vendorName'],
      poDate: DateTime.parse(json['poDate']),
      expectedDeliveryDate: json['expectedDeliveryDate'] != null 
          ? DateTime.parse(json['expectedDeliveryDate']) 
          : null,
      totalAmount: (json['totalAmount'] as num).toDouble(),
      gstAmount: (json['gstAmount'] as num).toDouble(),
      netAmount: (json['netAmount'] as num).toDouble(),
      status: json['status'],
      notes: json['notes'],
      items: (json['items'] as List?)
          ?.map((i) => PurchaseOrderItem.fromJson(i))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'poNumber': poNumber,
      'projectId': projectId,
      'projectName': projectName,
      'vendorId': vendorId,
      'vendorName': vendorName,
      'poDate': poDate.toIso8601String(),
      'expectedDeliveryDate': expectedDeliveryDate?.toIso8601String(),
      'totalAmount': totalAmount,
      'gstAmount': gstAmount,
      'netAmount': netAmount,
      'status': status,
      'notes': notes,
      'createdById': createdById,
      'items': items.map((i) => i.toJson()).toList(),
    };
  }
}

class PurchaseOrderItem {
  final String description;
  final double quantity;
  final String unit;
  final double rate;
  final double gstPercentage;
  final double amount;

  final int? materialId;

  PurchaseOrderItem({
    required this.description,
    required this.quantity,
    required this.unit,
    required this.rate,
    required this.gstPercentage,
    required this.amount,
    this.materialId,
  });

  factory PurchaseOrderItem.fromJson(Map<String, dynamic> json) {
    return PurchaseOrderItem(
      description: json['description'],
      quantity: (json['quantity'] as num).toDouble(),
      unit: json['unit'],
      rate: (json['rate'] as num).toDouble(),
      gstPercentage: (json['gstPercentage'] as num).toDouble(),
      amount: (json['amount'] as num).toDouble(),
      materialId: json['materialId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'description': description,
      'quantity': quantity,
      'unit': unit,
      'rate': rate,
      'gstPercentage': gstPercentage,
      'amount': amount,
      if (materialId != null) 'materialId': materialId,
    };
  }
}

class GoodsReceivedNote {
  final int? id;
  final String? grnNumber;
  final int purchaseOrderId;
  final String? poNumber;
  final DateTime receivedDate;
  final String? deliveryNoteNumber;
  final String? comments;
  final int? receivedById;
  final String? vendorName;
  final String? projectName;
  final String? invoiceNumber;
  final String? challanNumber;
  final List<GoodsReceivedNoteItem> items;

  GoodsReceivedNote({
    this.id,
    this.grnNumber,
    required this.purchaseOrderId,
    this.poNumber,
    required this.receivedDate,
    this.deliveryNoteNumber,
    this.comments,
    this.receivedById,
    this.vendorName,
    this.projectName,
    this.invoiceNumber,
    this.challanNumber,
    this.items = const [],
  });

  factory GoodsReceivedNote.fromJson(Map<String, dynamic> json) {
    return GoodsReceivedNote(
      id: json['id'],
      grnNumber: json['grnNumber'],
      purchaseOrderId: json['poId'] ?? json['purchaseOrderId'] ?? 0,
      poNumber: json['poNumber'],
      receivedDate: json['receivedDate'] != null ? DateTime.parse(json['receivedDate']) : DateTime.now(),
      deliveryNoteNumber: json['deliveryNoteNumber'],
      comments: json['notes'] ?? json['comments'],
      receivedById: json['receivedById'],
      vendorName: json['vendorName'],
      projectName: json['projectName'],
      invoiceNumber: json['invoiceNumber'],
      challanNumber: json['challanNumber'],
      items: (json['items'] as List?)
          ?.map((i) => GoodsReceivedNoteItem.fromJson(i))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'grnNumber': grnNumber,
      'purchaseOrderId': purchaseOrderId,
      'poNumber': poNumber,
      'receivedDate': receivedDate.toIso8601String(),
      'deliveryNoteNumber': deliveryNoteNumber,
      'comments': comments,
      'receivedById': receivedById,
      'items': items.map((i) => i.toJson()).toList(),
    };
  }
}

class GoodsReceivedNoteItem {
  final int? purchaseOrderItemId;
  final String description;
  final double receivedQuantity;
  final double rejectedQuantity;
  final String? rejectionReason;
  
  GoodsReceivedNoteItem({
    this.purchaseOrderItemId,
    required this.description,
    required this.receivedQuantity,
    this.rejectedQuantity = 0,
    this.rejectionReason,
  });

  factory GoodsReceivedNoteItem.fromJson(Map<String, dynamic> json) {
    return GoodsReceivedNoteItem(
      purchaseOrderItemId: json['purchaseOrderItemId'],
      description: json['description'] ?? '',
      receivedQuantity: (json['receivedQuantity'] as num).toDouble(),
      rejectedQuantity: (json['rejectedQuantity'] as num?)?.toDouble() ?? 0,
      rejectionReason: json['rejectionReason'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'purchaseOrderItemId': purchaseOrderItemId,
      'description': description,
      'receivedQuantity': receivedQuantity,
      'rejectedQuantity': rejectedQuantity,
      'rejectionReason': rejectionReason,
    };
  }
}
