import 'package:flutter/foundation.dart';

/// Top-level envelope returned by GET /api/estimation/options.
@immutable
class EstimationOptions {
  final List<CustomisationCategoryRef> customisationCategories;
  final List<AddonRef> addons;
  final List<SiteFeeRef> siteFees;
  final List<GovtFeeRef> govtFees;

  const EstimationOptions({
    required this.customisationCategories,
    required this.addons,
    required this.siteFees,
    required this.govtFees,
  });

  factory EstimationOptions.fromJson(Map<String, dynamic> json) {
    return EstimationOptions(
      customisationCategories: (json['customisationCategories'] as List<dynamic>? ?? [])
          .map((e) => CustomisationCategoryRef.fromJson(e as Map<String, dynamic>))
          .toList(),
      addons: (json['addons'] as List<dynamic>? ?? [])
          .map((e) => AddonRef.fromJson(e as Map<String, dynamic>))
          .toList(),
      siteFees: (json['siteFees'] as List<dynamic>? ?? [])
          .map((e) => SiteFeeRef.fromJson(e as Map<String, dynamic>))
          .toList(),
      govtFees: (json['govtFees'] as List<dynamic>? ?? [])
          .map((e) => GovtFeeRef.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// A customisation category with its nested options.
@immutable
class CustomisationCategoryRef {
  final String id;
  final String name;
  final String pricingMode;
  final int displayOrder;
  final List<CustomisationOptionRef> options;

  const CustomisationCategoryRef({
    required this.id,
    required this.name,
    required this.pricingMode,
    required this.displayOrder,
    required this.options,
  });

  factory CustomisationCategoryRef.fromJson(Map<String, dynamic> json) {
    return CustomisationCategoryRef(
      id: json['id'] as String,
      name: json['name'] as String,
      pricingMode: json['pricingMode'] as String,
      displayOrder: json['displayOrder'] as int,
      options: (json['options'] as List<dynamic>? ?? [])
          .map((e) => CustomisationOptionRef.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// A single selectable option within a customisation category.
@immutable
class CustomisationOptionRef {
  final String id;
  final String categoryId;
  final String name;
  final double rate;
  final int displayOrder;

  const CustomisationOptionRef({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.rate,
    required this.displayOrder,
  });

  factory CustomisationOptionRef.fromJson(Map<String, dynamic> json) {
    return CustomisationOptionRef(
      id: json['id'] as String,
      categoryId: json['categoryId'] as String,
      name: json['name'] as String,
      rate: (json['rate'] as num).toDouble(),
      displayOrder: json['displayOrder'] as int,
    );
  }
}

/// An optional add-on (e.g. Smart Home package).
@immutable
class AddonRef {
  final String id;
  final String name;
  final String? description;
  final double lumpAmount;

  const AddonRef({
    required this.id,
    required this.name,
    this.description,
    required this.lumpAmount,
  });

  factory AddonRef.fromJson(Map<String, dynamic> json) {
    return AddonRef(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      lumpAmount: (json['lumpAmount'] as num).toDouble(),
    );
  }
}

/// A site-specific fee (e.g. sloped lot surcharge). Either lump or per-sqft.
@immutable
class SiteFeeRef {
  final String id;
  final String name;
  final String mode;
  final double? lumpAmount;
  final double? perSqftRate;

  const SiteFeeRef({
    required this.id,
    required this.name,
    required this.mode,
    this.lumpAmount,
    this.perSqftRate,
  });

  factory SiteFeeRef.fromJson(Map<String, dynamic> json) {
    return SiteFeeRef(
      id: json['id'] as String,
      name: json['name'] as String,
      mode: json['mode'] as String,
      lumpAmount: json['lumpAmount'] == null
          ? null
          : (json['lumpAmount'] as num).toDouble(),
      perSqftRate: json['perSqftRate'] == null
          ? null
          : (json['perSqftRate'] as num).toDouble(),
    );
  }
}

/// A government fee (e.g. building permit). Always a lump amount.
@immutable
class GovtFeeRef {
  final String id;
  final String name;
  final double lumpAmount;

  const GovtFeeRef({
    required this.id,
    required this.name,
    required this.lumpAmount,
  });

  factory GovtFeeRef.fromJson(Map<String, dynamic> json) {
    return GovtFeeRef(
      id: json['id'] as String,
      name: json['name'] as String,
      lumpAmount: (json['lumpAmount'] as num).toDouble(),
    );
  }
}
