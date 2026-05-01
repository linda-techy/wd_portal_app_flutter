import 'package:flutter/foundation.dart';

/// Project types accepted by the backend (matches `com.wd.api.estimation.domain.enums.ProjectType`).
/// Hard-coded — these enum values do not change at runtime and the backend rejects unknown
/// values with a CHECK-constraint 500 (see V89 — only NEW_BUILD and COMMERCIAL are seeded
/// and constraint-allowed today).
enum ProjectType { NEW_BUILD, COMMERCIAL, RENOVATION, INTERIOR, COMPOUND }

@immutable
class PackageRateVersion {
  final String id;
  final String packageId;
  final ProjectType projectType;
  final num materialRate;
  final num labourRate;
  final num overheadRate;
  final DateTime effectiveFrom;
  final DateTime? effectiveTo;

  const PackageRateVersion({
    required this.id,
    required this.packageId,
    required this.projectType,
    required this.materialRate,
    required this.labourRate,
    required this.overheadRate,
    required this.effectiveFrom,
    required this.effectiveTo,
  });

  /// True when `effectiveTo` is null — the open-ended row is the currently-active version.
  bool get isActive => effectiveTo == null;

  /// Convenience: sum of the three rate components in ₹/sqft.
  num get totalRate => materialRate + labourRate + overheadRate;

  factory PackageRateVersion.fromJson(Map<String, dynamic> json) {
    return PackageRateVersion(
      id: json['id'] as String,
      packageId: json['packageId'] as String,
      projectType: ProjectType.values.byName(json['projectType'] as String),
      materialRate: json['materialRate'] as num,
      labourRate: json['labourRate'] as num,
      overheadRate: json['overheadRate'] as num,
      effectiveFrom: DateTime.parse(json['effectiveFrom'] as String),
      effectiveTo: json['effectiveTo'] != null
          ? DateTime.parse(json['effectiveTo'] as String)
          : null,
    );
  }

  /// Create payload — used by POST /api/estimation/rate-versions.
  /// `effectiveFrom` is optional — backend defaults to today if omitted.
  static Map<String, dynamic> createPayload({
    required String packageId,
    required ProjectType projectType,
    required num materialRate,
    required num labourRate,
    required num overheadRate,
    DateTime? effectiveFrom,
  }) {
    return {
      'packageId': packageId,
      'projectType': projectType.name,
      'materialRate': materialRate,
      'labourRate': labourRate,
      'overheadRate': overheadRate,
      if (effectiveFrom != null)
        'effectiveFrom': effectiveFrom.toIso8601String().substring(0, 10),
    };
  }
}
