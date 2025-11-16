import 'package:flutter/material.dart';
import '../../../models/lead.dart';
import '../../../models/team_member_simple.dart';
import '../../../services/crm_service.dart';
import '../../../constants/customer_type_constants.dart';
import '../../../constants/lead_status_constants.dart';

class EditLeadController extends ChangeNotifier {
  final Lead _originalLead;
  final CRMService _crmService = CRMService();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  // Form data
  late String name;
  late String email;
  late String phone;
  late String whatsappNumber;
  late LeadSource source;
  late String status;
  late LeadPriority priority;
  late String customerType;
  late String projectType;
  late String projectDescription;
  late String requirements;
  double? budget;
  double? projectSqftArea;
  late String assignedTeam;
  late String state;
  late String district;
  late String location;
  late String address;
  String? notes;
  late int clientRating;
  late int probabilityToWin;
  DateTime? nextFollowUp;
  DateTime? lastContactDate;
  DateTime? dateOfEnquiry;
  String? lostReason;

  bool _isLoading = false;
  String? _errorMessage;
  List<TeamMemberSimple> _teamMembers = [];

  EditLeadController(this._originalLead) {
    _initializeFields();
    _loadTeamMembers();
  }

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<TeamMemberSimple> get teamMembers => _teamMembers;

  Map<String, dynamic> get formData => {
        'name': name,
        'email': email,
        'phone': phone,
        'whatsappNumber': whatsappNumber,
        'source': source,
        'status': status,
        'priority': priority,
        'customerType': customerType,
        'projectType': projectType,
        'projectDescription': projectDescription,
        'requirements': requirements,
        'budget': budget,
        'projectSqftArea': projectSqftArea,
        'assignedTeam': assignedTeam,
        'state': state,
        'district': district,
        'location': location,
        'address': address,
        'notes': notes,
        'clientRating': clientRating,
        'probabilityToWin': probabilityToWin,
        'nextFollowUp': nextFollowUp,
        'lastContactDate': lastContactDate,
        'dateOfEnquiry': dateOfEnquiry,
        'lostReason': lostReason,
      };

  void _initializeFields() {
    final lead = _originalLead;

    // Basic Information
    name = lead.name;
    email = lead.email;
    phone = lead.phone;
    whatsappNumber = lead.whatsappNumber ?? '';
    source = lead.source;
    status = LeadStatusConstants.getValidValue(lead.status);
    priority = lead.priority;

    customerType = CustomerTypeConstants.getValidValue(lead.customerType);

    // Project Information
    projectType = lead.projectType;
    projectDescription = lead.projectDescription;
    requirements = lead.requirements;
    budget = lead.budget;
    projectSqftArea = lead.projectSqftArea;

    // Assignment
    assignedTeam = lead.assignedTeam;

    // Location Information
    state = lead.state;
    district = lead.district;
    location = lead.location;
    address = lead.address;

    // Additional Information
    notes = lead.notes;
    clientRating = lead.clientRating;
    probabilityToWin = lead.probabilityToWin;

    // Dates
    nextFollowUp = lead.nextFollowUp;
    lastContactDate = lead.lastContactDate;
    dateOfEnquiry = lead.dateOfEnquiry;

    // Lost reason
    lostReason = lead.lostReason;
  }

  void updateFormData(String key, dynamic value) {
    switch (key) {
      case 'name':
        name = value;
        break;
      case 'email':
        email = value;
        break;
      case 'phone':
        phone = value;
        break;
      case 'whatsappNumber':
        whatsappNumber = value;
        break;
      case 'source':
        source = value;
        break;
      case 'status':
        status = value;
        break;
      case 'priority':
        priority = value;
        break;
      case 'customerType':
        customerType = value;
        break;
      case 'projectType':
        projectType = value;
        break;
      case 'projectDescription':
        projectDescription = value;
        break;
      case 'requirements':
        requirements = value;
        break;
      case 'budget':
        budget = value;
        break;
      case 'projectSqftArea':
        projectSqftArea = value;
        break;
      case 'assignedTeam':
        assignedTeam = value;
        break;
      case 'state':
        state = value;
        break;
      case 'district':
        district = value;
        break;
      case 'location':
        location = value;
        break;
      case 'address':
        address = value;
        break;
      case 'notes':
        notes = value;
        break;
      case 'clientRating':
        clientRating = value;
        break;
      case 'probabilityToWin':
        probabilityToWin = value;
        break;
      case 'lostReason':
        lostReason = value;
        break;
    }
    notifyListeners();
  }

  void updateDateOfEnquiry(DateTime? date) {
    dateOfEnquiry = date;
    notifyListeners();
  }

  void updateNextFollowUp(DateTime? date) {
    nextFollowUp = date;
    notifyListeners();
  }

  void updateLastContactDate(DateTime? date) {
    lastContactDate = date;
    notifyListeners();
  }

  Future<void> _loadTeamMembers() async {
    try {
      final members = await _crmService.getTeamMembersForAssignment();
      _teamMembers = members;
      notifyListeners();
    } catch (e) {
      print('Error loading team members: $e');
      // Continue without team members - form will show text field instead
    }
  }

  Future<bool> saveLead() async {
    if (!formKey.currentState!.validate()) {
      _errorMessage = 'Please fix the validation errors before saving';
      return false;
    }

    formKey.currentState!.save();
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updatedLead = Lead(
        leadId: _originalLead.leadId,
        name: name,
        email: email,
        phone: phone,
        whatsappNumber: whatsappNumber,
        source: source,
        createdAt: _originalLead.createdAt,
        status: status,
        notes: notes,
        priority: priority,
        nextFollowUp: nextFollowUp,
        customerType: customerType,
        projectType: projectType,
        budget: budget,
        projectSqftArea: projectSqftArea,
        lastContactDate: lastContactDate,
        clientRating: clientRating,
        probabilityToWin: probabilityToWin,
        assignedTeam: assignedTeam,
        projectDescription: projectDescription,
        requirements: requirements,
        state: state,
        district: district,
        location: location,
        address: address,
        dateOfEnquiry: dateOfEnquiry,
        lostReason: lostReason,
      );

      await _crmService.updateLead(updatedLead.leadId, updatedLead);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Error updating lead: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

}
