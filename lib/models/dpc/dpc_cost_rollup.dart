/// Per-scope cost rollup row (DTO for `DpcCostRollupDto`).
class DpcCostRollup {
  final String scopeCode;
  final String scopeTitle;
  final double originalAmount;
  final double customizedAmount;
  final double variance;
  final double? originalPerSqft;
  final double? customizedPerSqft;

  DpcCostRollup({
    required this.scopeCode,
    required this.scopeTitle,
    required this.originalAmount,
    required this.customizedAmount,
    required this.variance,
    this.originalPerSqft,
    this.customizedPerSqft,
  });

  factory DpcCostRollup.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic v) {
      if (v == null) return 0.0;
      if (v is double) return v;
      if (v is int) return v.toDouble();
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v) ?? 0.0;
      return 0.0;
    }

    double? parseDoubleNullable(dynamic v) {
      if (v == null) return null;
      if (v is double) return v;
      if (v is int) return v.toDouble();
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v);
      return null;
    }

    return DpcCostRollup(
      scopeCode: json['scopeCode'] as String? ?? '',
      scopeTitle: json['scopeTitle'] as String? ?? '',
      originalAmount: parseDouble(json['originalAmount']),
      customizedAmount: parseDouble(json['customizedAmount']),
      variance: parseDouble(json['variance']),
      originalPerSqft: parseDoubleNullable(json['originalPerSqft']),
      customizedPerSqft: parseDoubleNullable(json['customizedPerSqft']),
    );
  }

  Map<String, dynamic> toJson() => {
        'scopeCode': scopeCode,
        'scopeTitle': scopeTitle,
        'originalAmount': originalAmount,
        'customizedAmount': customizedAmount,
        'variance': variance,
        'originalPerSqft': originalPerSqft,
        'customizedPerSqft': customizedPerSqft,
      };
}
