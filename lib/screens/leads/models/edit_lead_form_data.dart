import '../../../models/lead.dart';

/// Form data model for editing leads
/// Encapsulates all form fields and provides validation and conversion methods
class EditLeadFormData {
  // Basic Information
  String name;
  String email;
  String phone;
  String whatsappNumber;
  LeadSource source;
  String status;
  LeadPriority priority;
  String customerType;

  // Project Information
  String projectType;
  String projectDescription;
  String requirements;
  double? budget;
  double? projectSqftArea;

  // Assignment
  String assignedTeam;

  // Location Information
  String state;
  String district;
  String location;

  // Additional Information
  String? notes;
  int clientRating;
  int probabilityToWin;

  // Dates
  DateTime? nextFollowUp;
  DateTime? lastContactDate;
  DateTime? dateOfEnquiry;

  EditLeadFormData({
    required this.name,
    required this.email,
    required this.phone,
    required this.whatsappNumber,
    required this.source,
    required this.status,
    required this.priority,
    required this.customerType,
    required this.projectType,
    required this.projectDescription,
    required this.requirements,
    this.budget,
    this.projectSqftArea,
    required this.assignedTeam,
    required this.state,
    required this.district,
    required this.location,
    this.notes,
    required this.clientRating,
    required this.probabilityToWin,
    this.nextFollowUp,
    this.lastContactDate,
    this.dateOfEnquiry,
  });

  /// Create form data from existing Lead
  factory EditLeadFormData.fromLead(Lead lead) {
    return EditLeadFormData(
      name: lead.name,
      email: lead.email,
      phone: lead.phone,
      whatsappNumber: lead.whatsappNumber ?? '',
      source: lead.source,
      status: lead.status,
      priority: lead.priority,
      customerType: lead.customerType,
      projectType: lead.projectType,
      projectDescription: lead.projectDescription,
      requirements: lead.requirements,
      budget: lead.budget,
      projectSqftArea: lead.projectSqftArea,
      assignedTeam: lead.assignedTeam,
      state: lead.state,
      district: lead.district,
      location: lead.location,
      notes: lead.notes,
      clientRating: lead.clientRating,
      probabilityToWin: lead.probabilityToWin,
      nextFollowUp: lead.nextFollowUp,
      lastContactDate: lead.lastContactDate,
      dateOfEnquiry: lead.dateOfEnquiry,
    );
  }

  /// Convert form data to Lead model
  Lead toLead(String leadId, DateTime createdAt) {
    return Lead(
      leadId: leadId,
      name: name,
      email: email,
      phone: phone,
      whatsappNumber: whatsappNumber.isNotEmpty ? whatsappNumber : null,
      source: source,
      createdAt: createdAt,
      status: status,
      notes: notes?.isNotEmpty == true ? notes : null,
      priority: priority,
      nextFollowUp: nextFollowUp,
      customerType: customerType,
      projectType: projectType,
      budget: budget,
      projectSqftArea: projectSqftArea,
      clientRating: clientRating,
      probabilityToWin: probabilityToWin,
      lastContactDate: lastContactDate,
      assignedTeam: assignedTeam,
      projectDescription: projectDescription,
      requirements: requirements,
      state: state,
      district: district,
      location: location,
      dateOfEnquiry: dateOfEnquiry,
    );
  }

  /// Create a copy with updated values
  EditLeadFormData copyWith({
    String? name,
    String? email,
    String? phone,
    String? whatsappNumber,
    LeadSource? source,
    String? status,
    LeadPriority? priority,
    String? customerType,
    String? projectType,
    String? projectDescription,
    String? requirements,
    double? budget,
    double? projectSqftArea,
    String? assignedTeam,
    String? state,
    String? district,
    String? location,
    String? notes,
    int? clientRating,
    int? probabilityToWin,
    DateTime? nextFollowUp,
    DateTime? lastContactDate,
    DateTime? dateOfEnquiry,
  }) {
    return EditLeadFormData(
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      whatsappNumber: whatsappNumber ?? this.whatsappNumber,
      source: source ?? this.source,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      customerType: customerType ?? this.customerType,
      projectType: projectType ?? this.projectType,
      projectDescription: projectDescription ?? this.projectDescription,
      requirements: requirements ?? this.requirements,
      budget: budget ?? this.budget,
      projectSqftArea: projectSqftArea ?? this.projectSqftArea,
      assignedTeam: assignedTeam ?? this.assignedTeam,
      state: state ?? this.state,
      district: district ?? this.district,
      location: location ?? this.location,
      notes: notes ?? this.notes,
      clientRating: clientRating ?? this.clientRating,
      probabilityToWin: probabilityToWin ?? this.probabilityToWin,
      nextFollowUp: nextFollowUp ?? this.nextFollowUp,
      lastContactDate: lastContactDate ?? this.lastContactDate,
      dateOfEnquiry: dateOfEnquiry ?? this.dateOfEnquiry,
    );
  }
}
