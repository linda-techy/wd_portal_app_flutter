import 'package:flutter/material.dart';

class CustomerTypeConstants {
  // Customer type values
  static const String individual = 'individual';
  static const String business = 'business';
  static const String government = 'government';
  static const String institution = 'institution';
  static const String channelPartner = 'channel_partner';
  static const String other = 'other';

  // Customer type labels
  static const String individualLabel = 'Individual / Homeowner';
  static const String businessLabel = 'Business / Corporate Client';
  static const String governmentLabel = 'Government / Public Sector';
  static const String institutionLabel = 'Institution / Organization';
  static const String channelPartnerLabel = 'Channel Partner';
  static const String otherLabel = 'Other';

  // Dropdown items
  static const List<DropdownMenuItem<String>> dropdownItems = [
    DropdownMenuItem(value: individual, child: Text(individualLabel)),
    DropdownMenuItem(value: business, child: Text(businessLabel)),
    DropdownMenuItem(value: government, child: Text(governmentLabel)),
    DropdownMenuItem(value: institution, child: Text(institutionLabel)),
    DropdownMenuItem(value: channelPartner, child: Text(channelPartnerLabel)),
    DropdownMenuItem(value: other, child: Text(otherLabel)),
  ];

  // All valid values
  static const List<String> validValues = [
    individual,
    business,
    government,
    institution,
    channelPartner,
    other,
  ];

  // Default value
  static const String defaultValue = individual;

  // Get label by value
  static String getLabel(String value) {
    switch (value) {
      case individual:
        return individualLabel;
      case business:
        return businessLabel;
      case government:
        return governmentLabel;
      case institution:
        return institutionLabel;
      case channelPartner:
        return channelPartnerLabel;
      case other:
        return otherLabel;
      default:
        return individualLabel;
    }
  }

  // Validate value
  static bool isValid(String value) {
    return validValues.contains(value);
  }

  // Get valid value or default
  static String getValidValue(String value) {
    return isValid(value) ? value : defaultValue;
  }
}
