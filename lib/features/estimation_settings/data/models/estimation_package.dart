import 'package:flutter/foundation.dart';

@immutable
class EstimationPackage {
  final String id;
  final String internalName;
  final String marketingName;
  final String? tagline;
  final String? description;
  final int displayOrder;
  final bool active;

  const EstimationPackage({
    required this.id,
    required this.internalName,
    required this.marketingName,
    this.tagline,
    this.description,
    required this.displayOrder,
    required this.active,
  });

  factory EstimationPackage.fromJson(Map<String, dynamic> json) {
    return EstimationPackage(
      id: json['id'] as String,
      internalName: json['internalName'] as String,
      marketingName: json['marketingName'] as String,
      tagline: json['tagline'] as String?,
      description: json['description'] as String?,
      displayOrder: json['displayOrder'] as int,
      active: json['active'] as bool,
    );
  }

  /// Create payload — used by POST /api/estimation/packages
  static Map<String, dynamic> createPayload({
    required String internalName,
    required String marketingName,
    String? tagline,
    String? description,
    required int displayOrder,
  }) {
    return {
      'internalName': internalName,
      'marketingName': marketingName,
      if (tagline != null) 'tagline': tagline,
      if (description != null) 'description': description,
      'displayOrder': displayOrder,
    };
  }

  /// Update payload — used by PUT /api/estimation/packages/{id}
  /// Note: internalName is intentionally excluded (immutable post-creation).
  Map<String, dynamic> updatePayload({
    required String marketingName,
    String? tagline,
    String? description,
    required int displayOrder,
    required bool active,
  }) {
    return {
      'marketingName': marketingName,
      if (tagline != null) 'tagline': tagline,
      if (description != null) 'description': description,
      'displayOrder': displayOrder,
      'active': active,
    };
  }
}
