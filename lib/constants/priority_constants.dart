import 'package:flutter/material.dart';
import '../models/lead.dart';

class PriorityConstants {
  // Priority values (using LeadPriority enum)
  static const LeadPriority low = LeadPriority.low;
  static const LeadPriority medium = LeadPriority.medium;
  static const LeadPriority high = LeadPriority.high;

  // Priority labels
  static const String lowLabel = 'Low';
  static const String mediumLabel = 'Medium';
  static const String highLabel = 'High';

  // Dropdown items
  static const List<DropdownMenuItem<LeadPriority>> dropdownItems = [
    DropdownMenuItem(value: low, child: Text(lowLabel)),
    DropdownMenuItem(value: medium, child: Text(mediumLabel)),
    DropdownMenuItem(value: high, child: Text(highLabel)),
  ];

  // All valid values
  static const List<LeadPriority> validValues = [
    low,
    medium,
    high,
  ];

  // Default value
  static const LeadPriority defaultValue = low;

  // Get label by value
  static String getLabel(LeadPriority value) {
    switch (value) {
      case LeadPriority.low:
        return lowLabel;
      case LeadPriority.medium:
        return mediumLabel;
      case LeadPriority.high:
        return highLabel;
    }
  }

  // Get label by string value
  static String getLabelByString(String value) {
    switch (value.toLowerCase()) {
      case 'low':
        return lowLabel;
      case 'medium':
        return mediumLabel;
      case 'high':
        return highLabel;
      default:
        return lowLabel;
    }
  }

  // Validate value
  static bool isValid(LeadPriority value) {
    return validValues.contains(value);
  }

  // Get valid value or default
  static LeadPriority getValidValue(LeadPriority value) {
    return isValid(value) ? value : defaultValue;
  }
}
