import 'package:flutter/material.dart';
import '../models/lead.dart';

class LeadSourceConstants {
  // Lead source values (using LeadSource enum)
  static const LeadSource website = LeadSource.website;
  static const LeadSource googleBusinessProfile =
      LeadSource.googleBusinessProfile;
  static const LeadSource referralClient = LeadSource.referralClient;
  static const LeadSource referralArchitect = LeadSource.referralArchitect;
  static const LeadSource socialMedia = LeadSource.socialMedia;
  static const LeadSource whatsappBusiness = LeadSource.whatsappBusiness;
  static const LeadSource onlineAds = LeadSource.onlineAds;
  static const LeadSource directWalkin = LeadSource.directWalkin;
  static const LeadSource eventTradeShow = LeadSource.eventTradeShow;
  static const LeadSource printAdvertising = LeadSource.printAdvertising;

  // Lead source labels
  static const String websiteLabel = 'Website';
  static const String googleBusinessProfileLabel = 'Google Business Profile';
  static const String referralClientLabel = 'Referral (Client)';
  static const String referralArchitectLabel =
      'Referral (Architect/Designer/Other)';
  static const String socialMediaLabel = 'Social Media (Facebook/Instagram)';
  static const String whatsappBusinessLabel = 'WhatsApp Business';
  static const String onlineAdsLabel = 'Online Ads (PPC)';
  static const String directWalkinLabel = 'Direct Walk-in';
  static const String eventTradeShowLabel = 'Event/Trade Show';
  static const String printAdvertisingLabel = 'Print Advertising';

  // Dropdown items
  static const List<DropdownMenuItem<LeadSource>> dropdownItems = [
    DropdownMenuItem(value: website, child: Text(websiteLabel)),
    DropdownMenuItem(
        value: googleBusinessProfile, child: Text(googleBusinessProfileLabel)),
    DropdownMenuItem(value: referralClient, child: Text(referralClientLabel)),
    DropdownMenuItem(
        value: referralArchitect, child: Text(referralArchitectLabel)),
    DropdownMenuItem(value: socialMedia, child: Text(socialMediaLabel)),
    DropdownMenuItem(
        value: whatsappBusiness, child: Text(whatsappBusinessLabel)),
    DropdownMenuItem(value: onlineAds, child: Text(onlineAdsLabel)),
    DropdownMenuItem(value: directWalkin, child: Text(directWalkinLabel)),
    DropdownMenuItem(value: eventTradeShow, child: Text(eventTradeShowLabel)),
    DropdownMenuItem(
        value: printAdvertising, child: Text(printAdvertisingLabel)),
  ];

  // Search dropdown items (includes null for 'All')
  static const List<DropdownMenuItem<LeadSource?>> searchDropdownItems = [
    DropdownMenuItem(value: null, child: Text('All Sources')),
    DropdownMenuItem(value: LeadSource.website, child: Text('Website')),
    DropdownMenuItem(
        value: LeadSource.googleBusinessProfile,
        child: Text('Google Business Profile')),
    DropdownMenuItem(
        value: LeadSource.referralClient, child: Text('Referral (Client)')),
    DropdownMenuItem(
        value: LeadSource.referralArchitect,
        child: Text('Referral (Architect/Designer/Other)')),
    DropdownMenuItem(
        value: LeadSource.socialMedia,
        child: Text('Social Media (Facebook/Instagram)')),
    DropdownMenuItem(
        value: LeadSource.whatsappBusiness, child: Text('WhatsApp Business')),
    DropdownMenuItem(
        value: LeadSource.onlineAds, child: Text('Online Ads (PPC)')),
    DropdownMenuItem(
        value: LeadSource.directWalkin, child: Text('Direct Walk-in')),
    DropdownMenuItem(
        value: LeadSource.eventTradeShow, child: Text('Event/Trade Show')),
    DropdownMenuItem(
        value: LeadSource.printAdvertising, child: Text('Print Advertising')),
  ];

  // All valid values
  static const List<LeadSource> validValues = [
    website,
    googleBusinessProfile,
    referralClient,
    referralArchitect,
    socialMedia,
    whatsappBusiness,
    onlineAds,
    directWalkin,
    eventTradeShow,
    printAdvertising,
  ];

  // Default value
  static const LeadSource defaultValue = website;

  // Get display name by value
  static String getDisplayName(LeadSource source) {
    switch (source) {
      case LeadSource.website:
        return websiteLabel;
      case LeadSource.googleBusinessProfile:
        return googleBusinessProfileLabel;
      case LeadSource.referralClient:
        return referralClientLabel;
      case LeadSource.referralArchitect:
        return referralArchitectLabel;
      case LeadSource.socialMedia:
        return socialMediaLabel;
      case LeadSource.whatsappBusiness:
        return whatsappBusinessLabel;
      case LeadSource.onlineAds:
        return onlineAdsLabel;
      case LeadSource.directWalkin:
        return directWalkinLabel;
      case LeadSource.eventTradeShow:
        return eventTradeShowLabel;
      case LeadSource.printAdvertising:
        return printAdvertisingLabel;
    }
  }

  // Get source name for charts/reports
  static String getSourceName(LeadSource source) {
    switch (source) {
      case LeadSource.website:
        return 'Website';
      case LeadSource.googleBusinessProfile:
        return 'Google Business Profile';
      case LeadSource.referralClient:
        return 'Referral (Client)';
      case LeadSource.referralArchitect:
        return 'Referral (Architect/Designer/Other)';
      case LeadSource.socialMedia:
        return 'Social Media (Facebook/Instagram)';
      case LeadSource.whatsappBusiness:
        return 'WhatsApp Business';
      case LeadSource.onlineAds:
        return 'Online Ads (PPC)';
      case LeadSource.directWalkin:
        return 'Direct Walk-in';
      case LeadSource.eventTradeShow:
        return 'Event/Trade Show';
      case LeadSource.printAdvertising:
        return 'Print Advertising';
    }
  }

  // Get color for charts
  static Color getSourceColor(LeadSource source) {
    switch (source) {
      case LeadSource.website:
        return Colors.blue;
      case LeadSource.googleBusinessProfile:
        return Colors.red;
      case LeadSource.referralClient:
        return Colors.green;
      case LeadSource.referralArchitect:
        return Colors.purple;
      case LeadSource.socialMedia:
        return Colors.pink;
      case LeadSource.whatsappBusiness:
        return Colors.teal;
      case LeadSource.onlineAds:
        return Colors.orange;
      case LeadSource.directWalkin:
        return Colors.brown;
      case LeadSource.eventTradeShow:
        return Colors.indigo;
      case LeadSource.printAdvertising:
        return Colors.amber;
    }
  }

  // Validate value
  static bool isValid(LeadSource value) {
    return validValues.contains(value);
  }

  // Get valid value or default
  static LeadSource getValidValue(LeadSource value) {
    return isValid(value) ? value : defaultValue;
  }
}
