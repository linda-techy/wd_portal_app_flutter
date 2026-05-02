import 'package:flutter/foundation.dart';

enum SubResourceType {
  inclusion,
  exclusion,
  assumption,
  paymentMilestone;

  String toApiPath() {
    switch (this) {
      case SubResourceType.inclusion:
        return 'inclusions';
      case SubResourceType.exclusion:
        return 'exclusions';
      case SubResourceType.assumption:
        return 'assumptions';
      case SubResourceType.paymentMilestone:
        return 'payment-milestones';
    }
  }

  String toDisplayLabel() {
    switch (this) {
      case SubResourceType.inclusion:
        return 'Inclusions';
      case SubResourceType.exclusion:
        return 'Exclusions';
      case SubResourceType.assumption:
        return 'Assumptions';
      case SubResourceType.paymentMilestone:
        return 'Payment Milestones';
    }
  }
}

@immutable
class EstimationSubResource {
  final String id;
  final String estimationId;
  final String label;
  final String? description;
  final int displayOrder;
  final double? percentage;

  const EstimationSubResource({
    required this.id,
    required this.estimationId,
    required this.label,
    this.description,
    required this.displayOrder,
    this.percentage,
  });

  factory EstimationSubResource.fromJson(Map<String, dynamic> json) {
    return EstimationSubResource(
      id: json['id'] as String,
      estimationId: json['estimationId'] as String,
      label: json['label'] as String,
      description: json['description'] as String?,
      displayOrder: (json['displayOrder'] as num).toInt(),
      percentage: json['percentage'] != null
          ? (json['percentage'] as num).toDouble()
          : null,
    );
  }

  /// Build the POST / PUT body. Omits null optional fields.
  static Map<String, dynamic> createPayload({
    required String label,
    String? description,
    int? displayOrder,
    double? percentage,
  }) {
    return {
      'label': label,
      if (description != null) 'description': description,
      if (displayOrder != null) 'displayOrder': displayOrder,
      if (percentage != null) 'percentage': percentage,
    };
  }
}
