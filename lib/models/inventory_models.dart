class MaterialModel {
  final int? id;
  final String name;
  final String unit;
  final String category;
  final bool active;

  MaterialModel({
    this.id,
    required this.name,
    required this.unit,
    required this.category,
    this.active = true,
  });

  factory MaterialModel.fromJson(Map<String, dynamic> json) {
    return MaterialModel(
      id: json['id'],
      name: json['name'],
      unit: json['unit'],
      category: json['category'],
      active: json['active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'unit': unit,
      'category': category,
      'active': active,
    };
  }
}

class InventoryStock {
  final int? id;
  final int projectId;
  final String? projectName;
  final int materialId;
  final String? materialName;
  final String? unit;
  final double currentQuantity;
  final String lastUpdated;

  InventoryStock({
    this.id,
    required this.projectId,
    this.projectName,
    required this.materialId,
    this.materialName,
    this.unit,
    required this.currentQuantity,
    required this.lastUpdated,
  });

  factory InventoryStock.fromJson(Map<String, dynamic> json) {
    return InventoryStock(
      id: json['id'],
      projectId: json['projectId'],
      projectName: json['projectName'],
      materialId: json['materialId'],
      materialName: json['materialName'],
      unit: json['unit'],
      currentQuantity: (json['currentQuantity'] as num).toDouble(),
      lastUpdated: json['lastUpdated'],
    );
  }
}

class StockAdjustment {
  final int? id;
  final int projectId;
  final int materialId;
  final String adjustmentType; // WASTAGE, THEFT, DAMAGE, CORRECTION, TRANSFER_OUT
  final double quantity;
  final String? reason;
  final DateTime? adjustedAt;

  StockAdjustment({
    this.id,
    required this.projectId,
    required this.materialId,
    required this.adjustmentType,
    required this.quantity,
    this.reason,
    this.adjustedAt,
  });

  factory StockAdjustment.fromJson(Map<String, dynamic> json) {
    return StockAdjustment(
      id: json['id'],
      projectId: json['projectId'],
      materialId: json['materialId'],
      adjustmentType: json['adjustmentType'],
      quantity: (json['quantity'] as num).toDouble(),
      reason: json['reason'],
      adjustedAt: json['adjustedAt'] != null ? DateTime.parse(json['adjustedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'projectId': projectId,
      'materialId': materialId,
      'adjustmentType': adjustmentType,
      'quantity': quantity,
      'reason': reason,
    };
  }
}
