/// DTO for one DPC customization-line row (auto from BoQ ADDON or manual).
class DpcCustomizationLine {
  final int? id;
  final int displayOrder;
  final String title;
  final String description;
  final double amount;

  /// 'AUTO_BOQ_ADDON' | 'MANUAL' (string from backend enum)
  final String source;
  final int? boqItemId;

  /// Non-null when this line was sourced from the master DPC Customization
  /// Catalog. Used to hide the "Promote to catalog" affordance on rows that
  /// are already linked.
  final int? customizationCatalogId;

  DpcCustomizationLine({
    this.id,
    required this.displayOrder,
    required this.title,
    required this.description,
    required this.amount,
    required this.source,
    this.boqItemId,
    this.customizationCatalogId,
  });

  bool get isManual => source.toUpperCase() == 'MANUAL';
  bool get isAuto => !isManual;

  factory DpcCustomizationLine.fromJson(Map<String, dynamic> json) {
    int? parseInt(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v);
      return null;
    }

    double parseDouble(dynamic v) {
      if (v == null) return 0.0;
      if (v is double) return v;
      if (v is int) return v.toDouble();
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v) ?? 0.0;
      return 0.0;
    }

    return DpcCustomizationLine(
      id: parseInt(json['id']),
      displayOrder: parseInt(json['displayOrder']) ?? 0,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      amount: parseDouble(json['amount']),
      source: json['source'] as String? ?? 'MANUAL',
      boqItemId: parseInt(json['boqItemId']),
      customizationCatalogId: parseInt(
        json['customizationCatalogId'] ?? json['customization_catalog_id'],
      ),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'displayOrder': displayOrder,
        'title': title,
        'description': description,
        'amount': amount,
        'source': source,
        'boqItemId': boqItemId,
        'customizationCatalogId': customizationCatalogId,
      };
}
