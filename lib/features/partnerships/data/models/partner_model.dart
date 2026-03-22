class PartnerSummary {
  final int id;
  final String fullName;
  final String email;
  final String phone;
  final String? designation;
  final String partnershipType;
  final String status;
  final String? firmName;
  final String? location;
  final DateTime? createdAt;
  final DateTime? approvedAt;
  final DateTime? lastLogin;
  final int totalReferrals;
  final int convertedReferrals;

  PartnerSummary({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    this.designation,
    required this.partnershipType,
    required this.status,
    this.firmName,
    this.location,
    this.createdAt,
    this.approvedAt,
    this.lastLogin,
    this.totalReferrals = 0,
    this.convertedReferrals = 0,
  });

  factory PartnerSummary.fromJson(Map<String, dynamic> json) {
    return PartnerSummary(
      id: _parseInt(json['id']),
      fullName: json['fullName'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      designation: json['designation'],
      partnershipType: json['partnershipType'] ?? '',
      status: json['status'] ?? 'pending',
      firmName: json['firmName'],
      location: json['location'],
      createdAt: _parseDate(json['createdAt']),
      approvedAt: _parseDate(json['approvedAt']),
      lastLogin: _parseDate(json['lastLogin']),
      totalReferrals: _parseInt(json['totalReferrals']),
      convertedReferrals: _parseInt(json['convertedReferrals']),
    );
  }

  String get displayName => firmName?.isNotEmpty == true ? '$fullName · $firmName' : fullName;

  double get conversionRate =>
      totalReferrals > 0 ? (convertedReferrals / totalReferrals) * 100 : 0;
}

class PartnerDetail {
  final int id;
  final String fullName;
  final String email;
  final String phone;
  final String? designation;
  final String partnershipType;
  final String status;
  // Business
  final String? firmName;
  final String? companyName;
  final String? businessName;
  final String? gstNumber;
  final String? licenseNumber;
  final String? reraNumber;
  final String? cinNumber;
  final String? ifscCode;
  final String? employeeId;
  // Professional
  final int? experience;
  final int? yearsOfPractice;
  final String? specialization;
  final String? portfolioLink;
  final String? certifications;
  // Operational
  final String? location;
  final String? areaOfOperation;
  final String? areasCovered;
  final String? areaServed;
  final String? landTypes;
  final String? materialsSupplied;
  final String? businessSize;
  final String? industry;
  final String? projectType;
  final String? projectScale;
  final String? timeline;
  // Additional
  final String? additionalContact;
  final String? message;
  // Timestamps
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? approvedAt;
  final DateTime? lastLogin;
  final String? createdBy;
  final String? updatedBy;
  // Stats
  final Map<String, dynamic> stats;

  PartnerDetail({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    this.designation,
    required this.partnershipType,
    required this.status,
    this.firmName,
    this.companyName,
    this.businessName,
    this.gstNumber,
    this.licenseNumber,
    this.reraNumber,
    this.cinNumber,
    this.ifscCode,
    this.employeeId,
    this.experience,
    this.yearsOfPractice,
    this.specialization,
    this.portfolioLink,
    this.certifications,
    this.location,
    this.areaOfOperation,
    this.areasCovered,
    this.areaServed,
    this.landTypes,
    this.materialsSupplied,
    this.businessSize,
    this.industry,
    this.projectType,
    this.projectScale,
    this.timeline,
    this.additionalContact,
    this.message,
    this.createdAt,
    this.updatedAt,
    this.approvedAt,
    this.lastLogin,
    this.createdBy,
    this.updatedBy,
    this.stats = const {},
  });

  factory PartnerDetail.fromJson(Map<String, dynamic> json) {
    return PartnerDetail(
      id: _parseInt(json['id']),
      fullName: json['fullName'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      designation: json['designation'],
      partnershipType: json['partnershipType'] ?? '',
      status: json['status'] ?? 'pending',
      firmName: json['firmName'],
      companyName: json['companyName'],
      businessName: json['businessName'],
      gstNumber: json['gstNumber'],
      licenseNumber: json['licenseNumber'],
      reraNumber: json['reraNumber'],
      cinNumber: json['cinNumber'],
      ifscCode: json['ifscCode'],
      employeeId: json['employeeId'],
      experience: _parseIntOrNull(json['experience']),
      yearsOfPractice: _parseIntOrNull(json['yearsOfPractice']),
      specialization: json['specialization'],
      portfolioLink: json['portfolioLink'],
      certifications: json['certifications'],
      location: json['location'],
      areaOfOperation: json['areaOfOperation'],
      areasCovered: json['areasCovered'],
      areaServed: json['areaServed'],
      landTypes: json['landTypes'],
      materialsSupplied: json['materialsSupplied'],
      businessSize: json['businessSize'],
      industry: json['industry'],
      projectType: json['projectType'],
      projectScale: json['projectScale'],
      timeline: json['timeline'],
      additionalContact: json['additionalContact'],
      message: json['message'],
      createdAt: _parseDate(json['createdAt']),
      updatedAt: _parseDate(json['updatedAt']),
      approvedAt: _parseDate(json['approvedAt']),
      lastLogin: _parseDate(json['lastLogin']),
      createdBy: json['createdBy'],
      updatedBy: json['updatedBy'],
      stats: (json['stats'] as Map<String, dynamic>?) ?? {},
    );
  }

  String get displayFirmName => firmName ?? companyName ?? businessName ?? '';
}

class PartnerReferral {
  final int leadId;
  final String? clientName;
  final String? clientPhone;
  final String? clientEmail;
  final String? projectType;
  final String status;
  final String? priority;
  final String? location;
  final String? budget;
  final String? dateOfEnquiry;
  final String? createdAt;

  PartnerReferral({
    required this.leadId,
    this.clientName,
    this.clientPhone,
    this.clientEmail,
    this.projectType,
    required this.status,
    this.priority,
    this.location,
    this.budget,
    this.dateOfEnquiry,
    this.createdAt,
  });

  factory PartnerReferral.fromJson(Map<String, dynamic> json) {
    return PartnerReferral(
      leadId: _parseInt(json['leadId']),
      clientName: json['clientName'],
      clientPhone: json['clientPhone'],
      clientEmail: json['clientEmail'],
      projectType: json['projectType'],
      status: json['status'] ?? 'new_inquiry',
      priority: json['priority'],
      location: json['location'],
      budget: json['budget']?.toString(),
      dateOfEnquiry: json['dateOfEnquiry']?.toString(),
      createdAt: json['createdAt']?.toString(),
    );
  }
}

// ── Helpers ────────────────────────────────────────────────────────────────

int _parseInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  return int.tryParse(value.toString()) ?? 0;
}

int? _parseIntOrNull(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  return int.tryParse(value.toString());
}

DateTime? _parseDate(dynamic value) {
  if (value == null) return null;
  if (value is String) return DateTime.tryParse(value);
  return null;
}
