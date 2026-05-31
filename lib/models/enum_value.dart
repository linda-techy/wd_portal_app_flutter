import 'package:flutter/foundation.dart';

@immutable
class EnumValue {
  final String value;
  final String displayName;
  final String? description;
  final int? order;

  const EnumValue({
    required this.value,
    required this.displayName,
    this.description,
    this.order,
  });

  factory EnumValue.fromJson(Map<String, dynamic> json) {
    return EnumValue(
      value: json['value'] ?? '',
      displayName: json['display_name'] ?? json['displayName'] ?? '',
      description: json['description'],
      order: json['order'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'value': value,
      'display_name': displayName,
      if (description != null) 'description': description,
      if (order != null) 'order': order,
    };
  }

  @override
  String toString() => displayName;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EnumValue &&
          runtimeType == other.runtimeType &&
          value == other.value;

  @override
  int get hashCode => value.hashCode;
}
