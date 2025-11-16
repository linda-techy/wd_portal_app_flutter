import 'package:flutter/material.dart';
import '../constants/lead_status_constants.dart';
import '../constants/customer_type_constants.dart';

enum LeadSource {
  website,
  googleBusinessProfile,
  referralClient,
  referralArchitect,
  socialMedia,
  whatsappBusiness,
  onlineAds,
  directWalkin,
  eventTradeShow,
  printAdvertising
}

enum LeadPriority { low, medium, high }

class Lead {
  final String leadId;
  final String name;
  final String email;
  final String phone;
  final String? whatsappNumber;
  final LeadSource source;
  final DateTime createdAt;
  final String status;
  final String? notes;
  final LeadPriority priority;
  final DateTime? nextFollowUp;
  final String customerType; // Individual, Business, Architect, Govt, etc.
  final String projectType;
  final double? budget;
  final double? projectSqftArea;
  final int clientRating; // 1-5 stars
  final int probabilityToWin; // 0-100
  final DateTime? lastContactDate;
  final String assignedTeam;
  final String state;
  final String district;
  final String location;
  final String address;
  final String projectDescription;
  final String requirements;
  final DateTime? dateOfEnquiry;
  final String? lostReason;

  Lead({
    required this.leadId,
    required this.name,
    required this.email,
    required this.phone,
    this.whatsappNumber,
    required this.source,
    required this.createdAt,
    this.status = LeadStatusConstants.defaultValue,
    this.notes,
    this.priority = LeadPriority.low,
    this.nextFollowUp,
    this.customerType = CustomerTypeConstants.defaultValue,
    this.projectType = '',
    this.budget,
    this.projectSqftArea,
    this.clientRating = 0,
    this.probabilityToWin = 0,
    this.lastContactDate,
    this.assignedTeam = '',
    this.state = '',
    this.district = '',
    this.location = '',
    this.address = '',
    this.projectDescription = '',
    this.requirements = '',
    this.dateOfEnquiry,
    this.lostReason,
  });

  Color get sourceColor {
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

  String get sourceString {
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

  // Map frontend enum to backend-accepted values (snake_case)
  String get sourceForApi {
    return Lead.getSourceApiValue(source);
  }

  // Static method to convert LeadSource enum to API value (snake_case)
  static String getSourceApiValue(LeadSource source) {
    switch (source) {
      case LeadSource.website:
        return 'website';
      case LeadSource.googleBusinessProfile:
        return 'google_business_profile';
      case LeadSource.referralClient:
        return 'referral_client';
      case LeadSource.referralArchitect:
        return 'referral_architect';
      case LeadSource.socialMedia:
        return 'social_media';
      case LeadSource.whatsappBusiness:
        return 'whatsapp_business';
      case LeadSource.onlineAds:
        return 'online_ads';
      case LeadSource.directWalkin:
        return 'direct_walkin';
      case LeadSource.eventTradeShow:
        return 'event_trade_show';
      case LeadSource.printAdvertising:
        return 'print_advertising';
    }
  }

  String get priorityString {
    switch (priority) {
      case LeadPriority.low:
        return 'Low';
      case LeadPriority.medium:
        return 'Medium';
      case LeadPriority.high:
        return 'High';
    }
  }

  // Convert Lead to JSON for API calls
  Map<String, dynamic> toJson() {
    return {
      'lead_id': leadId,
      'name': name,
      'email': email,
      'phone': phone,
      'whatsapp_number':
          whatsappNumber?.isNotEmpty == true ? whatsappNumber : null,
      'lead_source': sourceForApi,
      'created_at': createdAt.toIso8601String(),
      'lead_status': status,
      'notes': notes?.isNotEmpty == true ? notes : null,
      'priority': priorityString.toLowerCase(),
      'next_follow_up': nextFollowUp?.toIso8601String(),
      'customer_type': customerType.isNotEmpty ? customerType : null,
      'project_type': projectType.isNotEmpty ? projectType : null,
      'project_description':
          projectDescription.isNotEmpty ? projectDescription : null,
      'requirements': requirements.isNotEmpty ? requirements : null,
      'budget': budget,
      'project_sqft_area': projectSqftArea,
      'client_rating': clientRating,
      'probability_to_win': probabilityToWin,
      'last_contact_date': lastContactDate?.toIso8601String(),
      'assigned_team': assignedTeam.isNotEmpty ? assignedTeam : null,
      'state': state.isNotEmpty ? state : null,
      'district': district.isNotEmpty ? district : null,
      'location': location.isNotEmpty ? location : null,
      'address': address.isNotEmpty ? address : null,
      'date_of_enquiry': dateOfEnquiry
          ?.toIso8601String()
          .substring(0, 10), // Send only date part (YYYY-MM-DD)
      'lost_reason': lostReason?.isNotEmpty == true ? lostReason : null,
    };
  }

  // JSON for create API (omit server-generated fields like id)
  Map<String, dynamic> toCreateJson() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'whatsapp_number':
          whatsappNumber?.isNotEmpty == true ? whatsappNumber : null,
      'lead_source': sourceForApi,
      'lead_status': status,
      'notes': notes?.isNotEmpty == true ? notes : null,
      'priority': priorityString.toLowerCase(),
      'next_follow_up': nextFollowUp?.toIso8601String(),
      'customer_type': customerType.isNotEmpty ? customerType : null,
      'project_type': projectType.isNotEmpty ? projectType : null,
      'project_description':
          projectDescription.isNotEmpty ? projectDescription : null,
      'requirements': requirements.isNotEmpty ? requirements : null,
      'budget': budget,
      'project_sqft_area': projectSqftArea,
      'client_rating': clientRating,
      'probability_to_win': probabilityToWin,
      'last_contact_date': lastContactDate?.toIso8601String(),
      'assigned_team': assignedTeam.isNotEmpty ? assignedTeam : null,
      'state': state.isNotEmpty ? state : null,
      'district': district.isNotEmpty ? district : null,
      'location': location.isNotEmpty ? location : null,
      'address': address.isNotEmpty ? address : null,
      'date_of_enquiry': dateOfEnquiry
          ?.toIso8601String()
          .substring(0, 10), // Send only date part (YYYY-MM-DD)
      'lost_reason': lostReason?.isNotEmpty == true ? lostReason : null,
    };
  }

  // JSON for update API (omit lead_id as it's in URL path)
  Map<String, dynamic> toUpdateJson() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'whatsapp_number':
          whatsappNumber?.isNotEmpty == true ? whatsappNumber : null,
      'lead_source': sourceForApi,
      'lead_status': status,
      'notes': notes?.isNotEmpty == true ? notes : null,
      'priority': priorityString.toLowerCase(),
      'next_follow_up': nextFollowUp?.toIso8601String(),
      'customer_type': customerType.isNotEmpty ? customerType : null,
      'project_type': projectType.isNotEmpty ? projectType : null,
      'project_description':
          projectDescription.isNotEmpty ? projectDescription : null,
      'requirements': requirements.isNotEmpty ? requirements : null,
      'budget': budget,
      'project_sqft_area': projectSqftArea,
      'client_rating': clientRating,
      'probability_to_win': probabilityToWin,
      'last_contact_date': lastContactDate?.toIso8601String(),
      'assigned_team': assignedTeam.isNotEmpty ? assignedTeam : null,
      'state': state.isNotEmpty ? state : null,
      'district': district.isNotEmpty ? district : null,
      'location': location.isNotEmpty ? location : null,
      'address': address.isNotEmpty ? address : null,
      'date_of_enquiry': dateOfEnquiry
          ?.toIso8601String()
          .substring(0, 10), // Send only date part (YYYY-MM-DD)
      'lost_reason': lostReason?.isNotEmpty == true ? lostReason : null,
    };
  }

  // Create Lead from JSON (API response)
  factory Lead.fromJson(Map<String, dynamic> json) {
    // Try multiple possible ID field names
    String leadId = json['lead_id'] ?? json['leadId'] ?? '';
    return Lead(
      leadId: leadId,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      whatsappNumber: json['whatsapp_number'],
      source: _parseSource(json['lead_source'] ?? json['source'] ?? ''),
      createdAt:
          DateTime.tryParse(json['created_at'] ?? json['createdAt'] ?? '') ??
              DateTime.now(),
      status: json['lead_status'] ?? json['status'] ?? 'New Inquiry',
      notes: json['notes'],
      priority: _parsePriority(json['priority'] ?? 'low'),
      nextFollowUp: json['next_follow_up'] != null
          ? DateTime.tryParse(json['next_follow_up'])
          : json['nextFollowUp'] != null
              ? DateTime.tryParse(json['nextFollowUp'])
              : null,
      customerType: json['customer_type'] ?? json['customerType'] ?? '',
      projectType: json['project_type'] ?? json['projectType'] ?? '',
      budget: json['budget']?.toDouble(),
      projectSqftArea: json['project_sqft_area']?.toDouble(),
      clientRating: json['client_rating'] ?? json['clientRating'] ?? 0,
      probabilityToWin:
          json['probability_to_win'] ?? json['probabilityToWin'] ?? 0,
      lastContactDate: json['last_contact_date'] != null
          ? DateTime.tryParse(json['last_contact_date'])
          : json['lastContactDate'] != null
              ? DateTime.tryParse(json['lastContactDate'])
              : null,
      assignedTeam: json['assigned_team'] ?? json['assignedTeam'] ?? '',
      state: json['state'] ?? '',
      district: json['district'] ?? '',
      location: json['location'] ?? '',
      address: json['address'] ?? '',
      projectDescription:
          json['project_description'] ?? json['projectDescription'] ?? '',
      requirements: json['requirements'] ?? '',
      dateOfEnquiry: json['date_of_enquiry'] != null
          ? DateTime.tryParse(json['date_of_enquiry'])
          : json['dateOfEnquiry'] != null
              ? DateTime.tryParse(json['dateOfEnquiry'])
              : null,
      lostReason: json['lost_reason'] ?? json['lostReason'],
    );
  }

  static LeadSource _parseSource(String source) {
    switch (source.toLowerCase()) {
      case 'website':
        return LeadSource.website;
      case 'googlebusinessprofile':
      case 'google_business_profile':
        return LeadSource.googleBusinessProfile;
      case 'referralclient':
      case 'referral_client':
        return LeadSource.referralClient;
      case 'referralarchitect':
      case 'referral_architect':
        return LeadSource.referralArchitect;
      case 'socialmedia':
      case 'social_media':
        return LeadSource.socialMedia;
      case 'whatsappbusiness':
      case 'whatsapp_business':
        return LeadSource.whatsappBusiness;
      case 'onlineads':
      case 'online_ads':
        return LeadSource.onlineAds;
      case 'directwalkin':
      case 'direct_walkin':
        return LeadSource.directWalkin;
      case 'eventtradeshow':
      case 'event_trade_show':
        return LeadSource.eventTradeShow;
      case 'printadvertising':
      case 'print_advertising':
        return LeadSource.printAdvertising;
      default:
        return LeadSource.website;
    }
  }

  static LeadPriority _parsePriority(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return LeadPriority.high;
      case 'medium':
        return LeadPriority.medium;
      case 'low':
        return LeadPriority.low;
      default:
        return LeadPriority.low;
    }
  }
}
