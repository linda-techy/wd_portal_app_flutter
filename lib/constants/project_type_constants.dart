import 'package:flutter/material.dart';

/// Define categories that a customer would look for.
enum ProjectType {
  residential('residential_construction', 'New Home Construction'),
  commercial('commercial_construction', 'Commercial / Office Space'),
  industrial('industrial_construction', 'Industrial & Warehouse'),
  interiors('interior_work', 'Interior Design'),
  renovation('renovation_remodeling', 'Renovation & Remodeling'),
  vastu('vastu_consultation', 'Vastu Consultation'),
  smartHome('smart_home_integration', 'Smart Home Solutions');

  final String value;
  final String label;

  // Constructor linking the database value to the UI label
  const ProjectType(this.value, this.label);

  /// Helper to convert a database string back to an Enum
  static ProjectType fromValue(String? value) {
    return ProjectType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => ProjectType.residential, // Safe default
    );
  }
}

class ProjectTypeConstants {
  // Access labels and values directly from the enum properties
  static String getLabel(ProjectType type) => type.label;
  static String getValue(ProjectType type) => type.value;

  /// Used for "Select Project Type" in Forms
  static List<DropdownMenuItem<String>> get formDropdownItems {
    return ProjectType.values.map((type) {
      return DropdownMenuItem<String>(
        value: type.value,
        child: Text(type.label),
      );
    }).toList();
  }

  /// Used for Filters/Search (Includes "All" option)
  /// Note: The value is String? to allow null for "All"
  static List<DropdownMenuItem<String?>> get searchDropdownItems {
    return [
      const DropdownMenuItem<String?>(
        value: null,
        child: Text('All Project Types'),
      ),
      ...ProjectType.values.map((type) {
        return DropdownMenuItem<String?>(
          value: type.value,
          child: Text(type.label),
        );
      }),
    ];
  }

  // Updated Defaults
  static const ProjectType defaultType = ProjectType.residential;
  static const String defaultLabel = 'New Home Construction';
  static const String defaultValue = 'residential_construction';
}
