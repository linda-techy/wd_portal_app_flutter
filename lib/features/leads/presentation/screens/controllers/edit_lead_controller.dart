import 'package:flutter/material.dart';
import 'package:admin/features/leads/data/models/lead.dart';
import 'package:admin/models/portal_user.dart';
import 'package:admin/services/user_service.dart';
import 'package:admin/features/leads/data/services/lead_service.dart';
import 'package:admin/constants/customer_type_constants.dart';
import 'package:admin/constants/lead_status_constants.dart';
import 'package:admin/constants/project_type_constants.dart';

class EditLeadController extends ChangeNotifier {
  final Lead _originalLead;
  final LeadService _leadService = LeadService();
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
  int? assignedToId;
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
  List<PortalUser> _teamMembers = [];
  bool _isLoadingTeamMembers = true;
  bool _isInitializing = true; // New: Track initialization state

  EditLeadController(this._originalLead) {
    _initializeAsync();
  }

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<PortalUser> get teamMembers => _teamMembers;
  bool get isLoadingTeamMembers => _isLoadingTeamMembers;
  bool get isInitializing =>
      _isInitializing; // New: Expose initialization state

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
        'assignedToId': assignedToId,
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

  /// Initialize controller asynchronously - loads dropdown data first, then sets form values
  /// This ensures dropdowns have their items available before setting selected values
  Future<void> _initializeAsync() async {
    _isInitializing = true;
    notifyListeners();

    try {
      // Step 1: Load all dropdown data first (team members)
      await _loadTeamMembers();

      // Step 2: Initialize form fields AFTER dropdown data is loaded
      _initializeFields();

      _isInitializing = false;
      notifyListeners();
    } catch (e) {
      print('Error initializing edit lead controller: $e');
      // Still initialize fields even if team members fail to load
      _initializeFields();
      _isInitializing = false;
      notifyListeners();
    }
  }

  void _initializeFields() {
    final lead = _originalLead;

    print('=== EditLeadController._initializeFields ===');
    print('Original lead.assignedToId: ${lead.assignedToId}');
    print('Original lead.assignedTo: ${lead.assignedTo}');
    print('Original lead.assignedTeam: ${lead.assignedTeam}');

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
    // Validate projectType against available options
    projectType = _validateProjectType(lead.projectType);

    projectDescription = lead.projectDescription;
    requirements = lead.requirements;
    budget = lead.budget;
    projectSqftArea = lead.projectSqftArea;

    // Location Information - Initialize BEFORE assignment to prevent late initialization error
    state = lead.state;
    district = lead.district;
    location = lead.location;
    address = lead.address;

    // Assignment - CRITICAL FIX: Always preserve assignedToId from original lead first
    // The validation was already done in _loadTeamMembers() which runs BEFORE this
    assignedTeam = lead.assignedTeam;
    
    // IMPORTANT: Don't re-validate here if team members are loaded
    // The assignedToId was already set correctly in _loadTeamMembers()
    // Only set it if it wasn't already set (shouldn't happen in normal flow)
    if (_teamMembers.isNotEmpty && assignedToId != null) {
      // assignedToId was already validated and set in _loadTeamMembers()
      print('Team members loaded - keeping pre-validated assignedToId: $assignedToId');
    } else {
      // Fallback: directly use the original value
      // This handles edge case where team members failed to load
      assignedToId = lead.assignedToId;
      print('Using original lead.assignedToId directly: $assignedToId');
    }

    print('Final assignedToId after all fields initialized: $assignedToId');

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

    print('=== End _initializeFields ===\n');
  }

  /// Validate and convert assignedToId, ensuring it exists in team members list
  int? _validateAssignedToId(dynamic leadAssignedToId) {
    if (leadAssignedToId == null) {
      return null;
    }

    // Convert to int
    int? parsedId = leadAssignedToId is int
        ? leadAssignedToId as int
        : int.tryParse(leadAssignedToId.toString());

    if (parsedId == null) {
      print(
          '_validateAssignedToId - Could not parse assignedToId: $leadAssignedToId');
      return null;
    }

    // Validate that the ID exists in the team members list
    if (_teamMembers.isNotEmpty) {
      final exists = _teamMembers.any((m) => m.id != null && m.id == parsedId);
      if (!exists) {
        print(
            '_validateAssignedToId - assignedToId $parsedId not found in team members list');
        print(
            'Available IDs: ${_teamMembers.where((m) => m.id != null).map((m) => m.id).toList()}');
        // Return null if not found - dropdown will show "Not Assigned"
        return null;
      }
    } else {
      // If team members not loaded yet, store the ID for later validation
      // It will be validated when team members are loaded
      print(
          '_validateAssignedToId - Team members not loaded yet, storing ID: $parsedId');
    }

    return parsedId;
  }

  /// Validate projectType against available options
  String _validateProjectType(String? leadProjectType) {
    if (leadProjectType == null || leadProjectType.isEmpty) {
      return '';
    }

    // Get all valid project type values
    final validValues = ProjectTypeConstants.formDropdownItems
        .map((item) => item.value)
        .where((value) => value != null)
        .cast<String>()
        .toList();

    // Check if the lead's project type is in the valid list
    if (validValues.contains(leadProjectType)) {
      return leadProjectType;
    }

    // If not found, try to find a match (case-insensitive)
    final match = validValues.firstWhere(
      (value) => value.toLowerCase() == leadProjectType.toLowerCase(),
      orElse: () => '',
    );

    if (match.isNotEmpty) {
      print(
          '_validateProjectType - Found case-insensitive match: $leadProjectType -> $match');
      return match;
    }

    // If no match found, return empty string (will show as unselected)
    print(
        '_validateProjectType - Project type "$leadProjectType" not found in valid values');
    print('Valid values: $validValues');
    return '';
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
      case 'assignedToId':
        assignedToId = value;
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
    _isLoadingTeamMembers = true;
    notifyListeners();

    try {
      // Load users with roles SALES, CRM, EMPLOYEE
      List<PortalUser> members = await UserService.getPortalUsersByRoleCodes(
          ['SALES', 'CRM', 'EMPLOYEE']);

      // Get the assignedToId from the original lead BEFORE initializing fields
      int? originalAssignedToId;
      if (_originalLead.assignedToId != null) {
        originalAssignedToId = _originalLead.assignedToId is int
            ? _originalLead.assignedToId as int
            : int.tryParse(_originalLead.assignedToId.toString());
      }

      // Ensure the currently assigned user is included even if they don't have one of these roles
      if (originalAssignedToId != null) {
        print(
            '_loadTeamMembers - Checking original assignedToId: $originalAssignedToId');

        // Check if assigned user already exists in the filtered list
        final assignedUserExists =
            members.any((m) => m.id != null && m.id == originalAssignedToId);
        print(
            '_loadTeamMembers - Assigned user exists in filtered list: $assignedUserExists');

        if (!assignedUserExists) {
          // Load all users to find the assigned user
          try {
            print(
                '_loadTeamMembers - Loading all users to find assigned user ID: $originalAssignedToId');
            final allUsers = await UserService.getAllPortalUsers();
            final assignedUserIndex = allUsers.indexWhere(
                (u) => u.id != null && u.id == originalAssignedToId);

            if (assignedUserIndex != -1) {
              final assignedUser = allUsers[assignedUserIndex];
              // Add assigned user at the beginning of the list so it's visible
              members.insert(0, assignedUser);
              print(
                  'Added assigned user ${assignedUser.fullName} (ID: ${assignedUser.id}) to team members list');
            } else {
              print(
                  'Assigned user with ID $originalAssignedToId not found in all users');
              print('All user IDs: ${allUsers.map((u) => u.id).toList()}');
            }
          } catch (e) {
            // If we can't find the assigned user, continue with filtered list
            print('Could not load assigned user: $e');
          }
        } else {
          print(
              'Assigned user (ID: $originalAssignedToId) already exists in filtered list');
        }
      } else {
        print(
            '_loadTeamMembers - originalAssignedToId is null, skipping assigned user check');
      }

      _teamMembers = members;
      _isLoadingTeamMembers = false;

      print('_loadTeamMembers - Team members loaded: ${members.length}');
      print(
          '_loadTeamMembers - Team member IDs: ${members.map((m) => m.id).toList()}');

      // After team members are loaded, validate and update the instance variable assignedToId
      // This ensures the assigned user is in the list before form initialization
      if (originalAssignedToId != null) {
        final exists =
            members.any((m) => m.id != null && m.id == originalAssignedToId);
        if (!exists) {
          print(
              '_loadTeamMembers - assignedToId $originalAssignedToId not found after loading, setting to null');
          // Update instance variable - this will be used when _initializeFields() is called
          assignedToId = null;
        } else {
          print(
              '_loadTeamMembers - assignedToId $originalAssignedToId validated successfully');
          // Update instance variable with the validated ID
          assignedToId = originalAssignedToId;
        }
      }

      notifyListeners();
    } catch (e, stackTrace) {
      print('Error loading team members: $e');
      print('Stack trace: $stackTrace');
      // Continue without team members - form will show empty list
      _teamMembers = [];
      _isLoadingTeamMembers = false;
      notifyListeners();
    }
  }

  Future<bool> saveLead() async {
    // Simple validation - only check essential fields
    // Form field validators will handle format validation
    if (!formKey.currentState!.validate()) {
      _errorMessage = 'Please check the form for errors';
      notifyListeners();
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
        assignedToId: assignedToId,
        projectDescription: projectDescription,
        requirements: requirements,
        state: state,
        district: district,
        location: location,
        address: address,
        dateOfEnquiry: dateOfEnquiry,
        lostReason: lostReason,
      );

      // Log the update payload for debugging
      print('=== Updating Lead ${updatedLead.leadId} ===');
      print('Assigned To ID: $assignedToId');
      final updateJson = updatedLead.toUpdateJson();
      print('Update JSON payload: $updateJson');

      await _leadService.updateLead(updatedLead.leadId, updatedLead);
      
      print('Lead ${updatedLead.leadId} updated successfully');
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      print('Error updating lead: $e');
      
      _isLoading = false;
      // Simple error message
      _errorMessage = 'Failed to update lead. Please try again.';
      notifyListeners();
      return false;
    }
  }

  Future<void> convertLead(Map<String, dynamic> requestData) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _leadService.convertLead(_originalLead.leadId, requestData);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Error converting lead: ${e.toString()}';
      notifyListeners();
      rethrow;
    }
  }
}
