/// Master-catalog row for a reusable DPC customization (e.g.
/// "Pooja room joinery" — ₹95,000 lump-sum).
///
/// Mirrors `DpcCustomizationCatalogItemDto` on the backend.
class DpcCustomizationCatalogItem {
  final int id;
  final String code;
  final String name;
  final String? description;
  final String? category;
  final String? unit;
  final double defaultAmount;
  final int timesUsed;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  DpcCustomizationCatalogItem({
    required this.id,
    required this.code,
    required this.name,
    this.description,
    this.category,
    this.unit,
    required this.defaultAmount,
    this.timesUsed = 0,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  factory DpcCustomizationCatalogItem.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic v) {
      if (v == null) return 0;
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v) ?? 0;
      return 0;
    }

    int parseInt(dynamic v) {
      if (v == null) return 0;
      if (v is int) return v;
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v) ?? 0;
      return 0;
    }

    DateTime? parseDate(dynamic v) {
      if (v == null) return null;
      if (v is String) return DateTime.tryParse(v);
      return null;
    }

    return DpcCustomizationCatalogItem(
      id: parseInt(json['id']),
      code: json['code'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      category: json['category'] as String?,
      unit: json['unit'] as String?,
      defaultAmount: parseDouble(json['defaultAmount']),
      timesUsed: parseInt(json['timesUsed']),
      isActive: json['isActive'] as bool? ?? true,
      createdAt: parseDate(json['createdAt']),
      updatedAt: parseDate(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'code': code,
        'name': name,
        'description': description,
        'category': category,
        'unit': unit,
        'defaultAmount': defaultAmount,
        'timesUsed': timesUsed,
        'isActive': isActive,
      };
}
