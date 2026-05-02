import 'package:flutter/foundation.dart';

/// Stable list of the 7 commodity keys the backend expects.
/// Order matches the V90 schema columns and the V101 seed.
const List<String> kMarketIndexCommodities = [
  'steel', 'cement', 'sand', 'aggregate', 'tiles', 'electrical', 'paints',
];

@immutable
class MarketIndexSnapshot {
  final String id;
  final DateTime snapshotDate;
  final double steelRate;
  final double cementRate;
  final double sandRate;
  final double aggregateRate;
  final double tilesRate;
  final double electricalRate;
  final double paintsRate;
  /// Per-commodity weight as decimal (e.g. {"steel": "0.30", ...}). Stringly-
  /// typed values come straight from the JSON response (server stores them as
  /// strings in the JSONB column for BigDecimal precision). Use [weightFor]
  /// for typed access.
  final Map<String, String> weights;
  /// Server-computed: Σ((current[i] / baseline[i]) × weight[i]). 1.0000 for the
  /// first snapshot ever. Persisted at scale 4.
  final double compositeIndex;
  final bool active;

  const MarketIndexSnapshot({
    required this.id,
    required this.snapshotDate,
    required this.steelRate,
    required this.cementRate,
    required this.sandRate,
    required this.aggregateRate,
    required this.tilesRate,
    required this.electricalRate,
    required this.paintsRate,
    required this.weights,
    required this.compositeIndex,
    required this.active,
  });

  /// Typed accessor for a commodity's weight as `double`. Returns 0.0 if the
  /// key is missing (backend always emits all 7 in V101 seed, but a robust
  /// default keeps the UI safe).
  double weightFor(String commodity) {
    final raw = weights[commodity];
    if (raw == null) return 0.0;
    return double.tryParse(raw) ?? 0.0;
  }

  /// Map of commodity → rate, in the V90 schema column order.
  Map<String, double> get ratesByCommodity => {
        'steel': steelRate,
        'cement': cementRate,
        'sand': sandRate,
        'aggregate': aggregateRate,
        'tiles': tilesRate,
        'electrical': electricalRate,
        'paints': paintsRate,
      };

  factory MarketIndexSnapshot.fromJson(Map<String, dynamic> json) {
    final rawWeights = json['weights'] as Map<String, dynamic>? ?? const {};
    return MarketIndexSnapshot(
      id: json['id'] as String,
      snapshotDate: DateTime.parse(json['snapshotDate'] as String),
      steelRate: (json['steelRate'] as num).toDouble(),
      cementRate: (json['cementRate'] as num).toDouble(),
      sandRate: (json['sandRate'] as num).toDouble(),
      aggregateRate: (json['aggregateRate'] as num).toDouble(),
      tilesRate: (json['tilesRate'] as num).toDouble(),
      electricalRate: (json['electricalRate'] as num).toDouble(),
      paintsRate: (json['paintsRate'] as num).toDouble(),
      weights: rawWeights.map((k, v) => MapEntry(k, v.toString())),
      compositeIndex: (json['compositeIndex'] as num).toDouble(),
      active: json['active'] as bool,
    );
  }

  /// Create payload — used by POST /api/estimation/market-index.
  /// `snapshotDate` optional (backend defaults to today). All 7 rates required.
  /// Weights are sent as a Map<String, String> to preserve precision.
  static Map<String, dynamic> createPayload({
    required double steelRate,
    required double cementRate,
    required double sandRate,
    required double aggregateRate,
    required double tilesRate,
    required double electricalRate,
    required double paintsRate,
    required Map<String, double> weights,
    DateTime? snapshotDate,
  }) {
    return {
      'steelRate': steelRate,
      'cementRate': cementRate,
      'sandRate': sandRate,
      'aggregateRate': aggregateRate,
      'tilesRate': tilesRate,
      'electricalRate': electricalRate,
      'paintsRate': paintsRate,
      'weights': weights.map((k, v) => MapEntry(k, v.toStringAsFixed(2))),
      if (snapshotDate != null)
        'snapshotDate': snapshotDate.toIso8601String().substring(0, 10),
    };
  }
}
