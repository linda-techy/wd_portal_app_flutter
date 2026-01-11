class MaterialIndent {
  final int? id;
  final String? indentNumber;
  final int projectId;
  final String requestDate;
  final String requiredDate;
  final String status;
  final String priority;
  final String? notes;
  final int? requestedById;
  final List<MaterialIndentItem> items;

  MaterialIndent({
    this.id,
    this.indentNumber,
    required this.projectId,
    required this.requestDate,
    required this.requiredDate,
    this.status = 'DRAFT',
    this.priority = 'MEDIUM',
    this.notes,
    this.requestedById,
    this.items = const [],
  });

  factory MaterialIndent.fromJson(Map<String, dynamic> json) {
    return MaterialIndent(
      id: json['id'],
      indentNumber: json['indent_number'],
      projectId: json['project']['id'], // Nested object from API
      requestDate: json['request_date'],
      requiredDate: json['required_date'],
      status: json['status'],
      priority: json['priority'],
      notes: json['notes'],
      requestedById: json['requested_by_id'],
      items: (json['items'] as List<dynamic>?)
              ?.map((item) => MaterialIndentItem.fromJson(item))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'project': {'id': projectId}, // Send mainly ID back
      'request_date': requestDate,
      'required_date': requiredDate,
      'status': status,
      'priority': priority,
      'notes': notes,
      'items': items.map((item) => item.toJson()).toList(),
    };
  }
}

class MaterialIndentItem {
  final int? id;
  final int? materialId;
  final String itemName;
  final String? description;
  final String unit;
  final double quantityRequested;
  final double? estimatedRate;

  MaterialIndentItem({
    this.id,
    this.materialId,
    required this.itemName,
    this.description,
    required this.unit,
    required this.quantityRequested,
    this.estimatedRate,
  });

  factory MaterialIndentItem.fromJson(Map<String, dynamic> json) {
    return MaterialIndentItem(
      id: json['id'],
      materialId: json['material'] != null ? json['material']['id'] : null,
      itemName: json['item_name'],
      description: json['description'],
      unit: json['unit'],
      quantityRequested: (json['quantity_requested'] as num).toDouble(),
      estimatedRate: json['estimated_rate'] != null
          ? (json['estimated_rate'] as num).toDouble()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (materialId != null) 'material': {'id': materialId},
      'item_name': itemName,
      'description': description,
      'unit': unit,
      'quantity_requested': quantityRequested,
      'estimated_rate': estimatedRate,
    };
  }
}
