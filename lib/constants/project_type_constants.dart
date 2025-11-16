import 'package:flutter/material.dart';

enum ProjectType {
  turnkeyProject,
  residentialConstruction,
  commercialConstruction,
  interiorWork,
  renovationRemodeling,
}

class ProjectTypeConstants {
  static const Map<ProjectType, String> _labels = {
    ProjectType.turnkeyProject: 'Turnkey Project',
    ProjectType.residentialConstruction: 'Residential Construction',
    ProjectType.commercialConstruction: 'Commercial Construction',
    ProjectType.interiorWork: 'Interior Work',
    ProjectType.renovationRemodeling: 'Renovation / Remodeling',
  };

  static const Map<ProjectType, String> _values = {
    ProjectType.turnkeyProject: 'turnkey_project',
    ProjectType.residentialConstruction: 'residential_construction',
    ProjectType.commercialConstruction: 'commercial_construction',
    ProjectType.interiorWork: 'interior_work',
    ProjectType.renovationRemodeling: 'renovation_remodeling',
  };

  static String getLabel(ProjectType type) {
    return _labels[type] ?? type.toString();
  }

  static String getValue(ProjectType type) {
    return _values[type] ?? type.toString();
  }

  static ProjectType fromValue(String value) {
    for (var entry in _values.entries) {
      if (entry.value == value) {
        return entry.key;
      }
    }
    return ProjectType.turnkeyProject; // Default fallback
  }

  static List<DropdownMenuItem<ProjectType>> get dropdownItems {
    return ProjectType.values.map((type) {
      return DropdownMenuItem<ProjectType>(
        value: type,
        child: Text(getLabel(type)),
      );
    }).toList();
  }

  static List<DropdownMenuItem<String>> get searchDropdownItems {
    return [
      const DropdownMenuItem<String>(
        value: null,
        child: Text('All Project Types'),
      ),
      ...ProjectType.values.map((type) {
        return DropdownMenuItem<String>(
          value: getValue(type),
          child: Text(getLabel(type)),
        );
      }),
    ];
  }

  static List<DropdownMenuItem<String>> get formDropdownItems {
    return ProjectType.values.map((type) {
      return DropdownMenuItem<String>(
        value: getValue(type),
        child: Text(getLabel(type)),
      );
    }).toList();
  }

  static const ProjectType defaultType = ProjectType.turnkeyProject;
  static const String defaultLabel = 'Turnkey Project';
  static const String defaultValue = 'turnkey_project';
}
