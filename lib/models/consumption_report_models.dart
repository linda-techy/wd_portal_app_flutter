
class MaterialConsumptionReport {
  final int materialId;
  final String materialName;
  final String unit;
  final double totalPurchased;
  final double currentStock;
  final double totalWastage;
  final double totalTheft;
  final double totalDamage;
  final double impliedConsumption;

  MaterialConsumptionReport({
    required this.materialId,
    required this.materialName,
    required this.unit,
    required this.totalPurchased,
    required this.currentStock,
    required this.totalWastage,
    required this.totalTheft,
    required this.totalDamage,
    required this.impliedConsumption,
  });

  factory MaterialConsumptionReport.fromJson(Map<String, dynamic> json) {
    return MaterialConsumptionReport(
      materialId: json['materialId'],
      materialName: json['materialName'],
      unit: json['unit'],
      totalPurchased: (json['totalPurchased'] as num?)?.toDouble() ?? 0.0,
      currentStock: (json['currentStock'] as num?)?.toDouble() ?? 0.0,
      totalWastage: (json['totalWastage'] as num?)?.toDouble() ?? 0.0,
      totalTheft: (json['totalTheft'] as num?)?.toDouble() ?? 0.0,
      totalDamage: (json['totalDamage'] as num?)?.toDouble() ?? 0.0,
      impliedConsumption: (json['impliedConsumption'] as num?)?.toDouble() ?? 0.0,
    );
  }

  // Helper getters
  double get totalVariance => totalWastage + totalTheft + totalDamage;
  bool get hasVariance => totalVariance > 0;
}
