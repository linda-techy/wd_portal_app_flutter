import 'dpc_cost_rollup.dart';

/// Master cost summary for a DPC document (mirrors `DpcMasterCostSummaryDto`).
class DpcMasterCostSummary {
  final double totalOriginal;
  final double totalCustomized;
  final double totalVariance;
  final double originalPerSqft;
  final double customizedPerSqft;
  final double sqfeet;
  final List<DpcCostRollup> scopes;

  DpcMasterCostSummary({
    required this.totalOriginal,
    required this.totalCustomized,
    required this.totalVariance,
    required this.originalPerSqft,
    required this.customizedPerSqft,
    required this.sqfeet,
    this.scopes = const [],
  });

  factory DpcMasterCostSummary.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic v) {
      if (v == null) return 0.0;
      if (v is double) return v;
      if (v is int) return v.toDouble();
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v) ?? 0.0;
      return 0.0;
    }

    final rawScopes = json['scopes'] as List? ?? [];

    return DpcMasterCostSummary(
      totalOriginal: parseDouble(json['totalOriginal']),
      totalCustomized: parseDouble(json['totalCustomized']),
      totalVariance: parseDouble(json['totalVariance']),
      originalPerSqft: parseDouble(json['originalPerSqft']),
      customizedPerSqft: parseDouble(json['customizedPerSqft']),
      sqfeet: parseDouble(json['sqfeet']),
      scopes: rawScopes
          .whereType<Map<String, dynamic>>()
          .map(DpcCostRollup.fromJson)
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'totalOriginal': totalOriginal,
        'totalCustomized': totalCustomized,
        'totalVariance': totalVariance,
        'originalPerSqft': originalPerSqft,
        'customizedPerSqft': customizedPerSqft,
        'sqfeet': sqfeet,
        'scopes': scopes.map((s) => s.toJson()).toList(),
      };

  static DpcMasterCostSummary empty() => DpcMasterCostSummary(
        totalOriginal: 0,
        totalCustomized: 0,
        totalVariance: 0,
        originalPerSqft: 0,
        customizedPerSqft: 0,
        sqfeet: 0,
        scopes: const [],
      );
}
