/// DTO for a master quotation-catalog row.
///
/// Mirrors `QuotationCatalogItemDto` on the backend. Immutable; use [copyWith]
/// to build edited variants.
class QuotationCatalogItem {
  final int id;
  final String code;
  final String name;
  final String? description;
  final String? category;
  final String? unit;
  final double defaultUnitPrice;
  final int timesUsed;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const QuotationCatalogItem({
    required this.id,
    required this.code,
    required this.name,
    this.description,
    this.category,
    this.unit,
    required this.defaultUnitPrice,
    this.timesUsed = 0,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  factory QuotationCatalogItem.fromJson(Map<String, dynamic> json) {
    int? parseInt(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v);
      return null;
    }

    double parseDouble(dynamic v) {
      if (v == null) return 0.0;
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v) ?? 0.0;
      return 0.0;
    }

    DateTime? parseDate(dynamic v) {
      if (v == null) return null;
      if (v is String && v.isNotEmpty) {
        try {
          return DateTime.parse(v);
        } catch (_) {
          return null;
        }
      }
      return null;
    }

    return QuotationCatalogItem(
      id: parseInt(json['id']) ?? 0,
      code: (json['code'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      description: json['description'] as String?,
      category: json['category'] as String?,
      unit: json['unit'] as String?,
      defaultUnitPrice: parseDouble(json['defaultUnitPrice']),
      timesUsed: parseInt(json['timesUsed']) ?? 0,
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
        'defaultUnitPrice': defaultUnitPrice,
        'timesUsed': timesUsed,
        'isActive': isActive,
        'createdAt': createdAt?.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
      };

  QuotationCatalogItem copyWith({
    int? id,
    String? code,
    String? name,
    String? description,
    String? category,
    String? unit,
    double? defaultUnitPrice,
    int? timesUsed,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return QuotationCatalogItem(
      id: id ?? this.id,
      code: code ?? this.code,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      unit: unit ?? this.unit,
      defaultUnitPrice: defaultUnitPrice ?? this.defaultUnitPrice,
      timesUsed: timesUsed ?? this.timesUsed,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
