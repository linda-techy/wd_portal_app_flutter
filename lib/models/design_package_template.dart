class DesignPackageTemplate {
  final int? id;
  final String code;
  final String name;
  final String? tagline;
  final String? description;
  final double ratePerSqft;
  final double fullPaymentDiscountPct;
  final int revisionsIncluded;
  final String? features;
  final int displayOrder;
  final bool isActive;

  const DesignPackageTemplate({
    this.id,
    required this.code,
    required this.name,
    this.tagline,
    this.description,
    required this.ratePerSqft,
    this.fullPaymentDiscountPct = 0,
    this.revisionsIncluded = 2,
    this.features,
    this.displayOrder = 0,
    this.isActive = true,
  });

  /// Convenience: features stored as newline-separated bullets server-side.
  List<String> get featureList {
    final raw = features;
    if (raw == null || raw.trim().isEmpty) return const [];
    return raw
        .split('\n')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }

  factory DesignPackageTemplate.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic v) {
      if (v == null) return 0;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString()) ?? 0;
    }

    return DesignPackageTemplate(
      id: json['id'] as int?,
      code: (json['code'] ?? '') as String,
      name: (json['name'] ?? '') as String,
      tagline: json['tagline'] as String?,
      description: json['description'] as String?,
      ratePerSqft: parseDouble(json['ratePerSqft']),
      fullPaymentDiscountPct: parseDouble(json['fullPaymentDiscountPct']),
      revisionsIncluded:
          (json['revisionsIncluded'] as num?)?.toInt() ?? 2,
      features: json['features'] as String?,
      displayOrder: (json['displayOrder'] as num?)?.toInt() ?? 0,
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  /// JSON shape the backend's @RequestBody DesignPackageTemplate expects.
  /// `code` is required on create but server-side read-only on update.
  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'code': code,
        'name': name,
        if (tagline != null) 'tagline': tagline,
        if (description != null) 'description': description,
        'ratePerSqft': ratePerSqft,
        'fullPaymentDiscountPct': fullPaymentDiscountPct,
        'revisionsIncluded': revisionsIncluded,
        if (features != null) 'features': features,
        'displayOrder': displayOrder,
        'isActive': isActive,
      };

  DesignPackageTemplate copyWith({
    String? code,
    String? name,
    String? tagline,
    String? description,
    double? ratePerSqft,
    double? fullPaymentDiscountPct,
    int? revisionsIncluded,
    String? features,
    int? displayOrder,
    bool? isActive,
  }) {
    return DesignPackageTemplate(
      id: id,
      code: code ?? this.code,
      name: name ?? this.name,
      tagline: tagline ?? this.tagline,
      description: description ?? this.description,
      ratePerSqft: ratePerSqft ?? this.ratePerSqft,
      fullPaymentDiscountPct:
          fullPaymentDiscountPct ?? this.fullPaymentDiscountPct,
      revisionsIncluded: revisionsIncluded ?? this.revisionsIncluded,
      features: features ?? this.features,
      displayOrder: displayOrder ?? this.displayOrder,
      isActive: isActive ?? this.isActive,
    );
  }
}
