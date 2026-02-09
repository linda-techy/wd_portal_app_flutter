import 'package:flutter/material.dart';
import 'package:admin/constants.dart';
import '../../data/models/lead.dart';
import 'package:admin/models/portal_user.dart';
import 'package:admin/services/user_service.dart';
import '../../data/services/lead_service.dart';
import 'package:admin/utils/india_location_data.dart';
import 'package:admin/constants/customer_type_constants.dart';
import 'package:admin/constants/lead_status_constants.dart';
import 'package:admin/constants/priority_constants.dart';
import 'package:admin/constants/project_type_constants.dart';
import 'constants/add_lead_constants.dart';
import 'components/form_sections.dart';
import 'package:provider/provider.dart';
import 'package:admin/providers/portal_auth_provider.dart';
import 'package:admin/utils/error_handler.dart';

class AddLeadScreen extends StatefulWidget {
  const AddLeadScreen({super.key});

  @override
  State<AddLeadScreen> createState() => _AddLeadScreenState();
}

class _AddLeadScreenState extends State<AddLeadScreen> {
  final _formKey = GlobalKey<FormState>();
  final LeadService _leadService = LeadService();

  // Form data map - similar to edit lead screen
  late Map<String, dynamic> formData;

  // Dates
  DateTime? dateOfEnquiry;
  DateTime? nextFollowUp;
  DateTime? lastContactDate;

  bool isLoading = false;
  bool isInitializing = true; // Track initialization state
  List<PortalUser> teamMembers = [];
  bool isLoadingTeamMembers = true; // Track team members loading state

  @override
  void initState() {
    super.initState();
    // Initialize form data with default values
    formData = {
      'name': '',
      'email': '',
      'phone': '',
      'whatsappNumber': '',
      'source': LeadSource.website,
      'status': LeadStatusConstants.defaultValue,
      'priority': PriorityConstants.defaultValue,
      'customerType': CustomerTypeConstants.defaultValue,
      'projectType': ProjectTypeConstants.defaultValue,
      'projectDescription': '',
      'requirements': '',
      'budget': null,
      'projectSqftArea': null,
      'assignedTeam': '',
      'assignedToId': null, // Added assignedToId
      'state': IndiaLocationData.getDefaultState(),
      'district': IndiaLocationData.getDefaultDistrict(
          IndiaLocationData.getDefaultState()),
      'location': '',
      'address': '',
      'notes': '',
      'clientRating': 3,
      'probabilityToWin': 50,
      'lostReason': '',
    };

    // Initialize with current date for date of enquiry
    dateOfEnquiry = DateTime.now();

    // Load dropdown data first, then initialize form
    _initializeAsync();
  }

  /// Initialize controller asynchronously - loads dropdown data first, then initializes form
  /// This ensures dropdowns have their items available before form is displayed
  Future<void> _initializeAsync() async {
    isInitializing = true;
    if (mounted) setState(() {});

    try {
      // Step 1: Verify authentication
      final authProvider = Provider.of<PortalAuthProvider>(context, listen: false);
      
      if (!authProvider.isAuthenticated) {
        if (mounted) {
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              Navigator.of(context).pushReplacementNamed('/login');
            }
          });
        }
        return;
      }
      
      // Step 2: Load all dropdown data first (team members)
      await _loadTeamMembers();

      // Step 3: Form is ready - initialization complete
      isInitializing = false;
      if (mounted) setState(() {});
    } catch (e) {
      // Still allow form to be shown even if team members fail to load
      isInitializing = false;
      if (mounted) setState(() {});
    }
  }

  Future<void> _loadTeamMembers() async {
    isLoadingTeamMembers = true;
    if (mounted) setState(() {});

    try {
      // Load users with roles SALES, CRM, EMPLOYEE
      final members = await UserService.getPortalUsersByRoleCodes(['SALES', 'CRM', 'EMPLOYEE']);
      if (mounted) {
        setState(() {
          teamMembers = members;
          isLoadingTeamMembers = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          teamMembers = [];
          isLoadingTeamMembers = false;
        });
        await ErrorHandler.handleApiError(context, e, defaultMessage: 'Error loading team members', showToast: false);
      }
    }
  }

  void _updateFormData(String key, dynamic value) {
    setState(() {
      formData[key] = value;
    });
  }

  void _updateDateOfEnquiry(DateTime? date) {
    setState(() {
      dateOfEnquiry = date;
      formData['dateOfEnquiry'] = date;
    });
  }

  void _updateNextFollowUp(DateTime? date) {
    setState(() {
      nextFollowUp = date;
      formData['nextFollowUp'] = date;
    });
  }

  void _updateLastContactDate(DateTime? date) {
    setState(() {
      lastContactDate = date;
      formData['lastContactDate'] = date;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AddLeadConstants.appBarTitle),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
      ),
      body: isInitializing || isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(defaultPadding),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader(AddLeadConstants.basicInfoHeader),
                    FormSections.buildBasicInfoSection(
                      formData: formData,
                      onChanged: _updateFormData,
                      context: context,
                    ),
                    const SizedBox(height: defaultPadding),
                    _buildSectionHeader(AddLeadConstants.locationHeader),
                    FormSections.buildLocationSection(
                      formData: formData,
                      onChanged: _updateFormData,
                      context: context,
                    ),
                    const SizedBox(height: defaultPadding),
                    _buildSectionHeader(AddLeadConstants.projectHeader),
                    FormSections.buildProjectSection(
                      context: context,
                      formData: formData,
                      onChanged: _updateFormData,
                      onDateOfEnquiryChanged: _updateDateOfEnquiry,
                    ),
                    const SizedBox(height: defaultPadding),
                    _buildSectionHeader(AddLeadConstants.salesHeader),
                    FormSections.buildSalesSection(
                      context: context,
                      formData: formData,
                      onChanged: _updateFormData,
                      onNextFollowUpChanged: _updateNextFollowUp,
                      onLastContactDateChanged: _updateLastContactDate,
                      teamMembers: teamMembers,
                      isLoadingTeamMembers: isLoadingTeamMembers,
                    ),
                    const SizedBox(height: defaultPadding),
                    _buildSectionHeader(AddLeadConstants.additionalHeader),
                    FormSections.buildAdditionalSection(
                      context: context,
                      formData: formData,
                      onChanged: _updateFormData,
                    ),
                    const SizedBox(height: defaultPadding * 2),
                    _buildActionButtons(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      margin: const EdgeInsets.only(bottom: defaultPadding),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: primaryColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: primaryColor,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              padding: const EdgeInsets.symmetric(vertical: defaultPadding),
            ),
            onPressed: _saveLead,
            child: const Text(
              AddLeadConstants.saveButtonText,
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ),
        const SizedBox(width: defaultPadding),
        Expanded(
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: defaultPadding),
            ),
            onPressed: () => Navigator.pop(context),
            child: const Text(AddLeadConstants.cancelButtonText),
          ),
        ),
      ],
    );
  }

  Future<void> _saveLead() async {
    // First validate the form
    if (!_formKey.currentState!.validate()) {
      // Show generic message if form validation fails
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please fix the errors in the form'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      }
      return;
    }
    
    _formKey.currentState!.save();

    setState(() => isLoading = true);

    try {
      // Validate required fields with detailed messages
      final String name = (formData['name'] ?? '').toString().trim();
      if (name.isEmpty) {
        if (mounted) {
          setState(() => isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Name is required - please enter lead name'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
        }
        return;
      }

      final String phone = (formData['phone'] ?? '').toString().trim();
      if (phone.isEmpty) {
        if (mounted) {
          setState(() => isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Phone number is required'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
        }
        return;
      }

      final String state = (formData['state'] ?? '').toString().trim();
      if (state.isEmpty) {
        if (mounted) {
          setState(() => isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ State is required - please select a state'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
        }
        return;
      }

      final String district = (formData['district'] ?? '').toString().trim();
      if (district.isEmpty) {
        if (mounted) {
          setState(() => isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ District is required - please select a district'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
        }
        return;
      }

      final lead = Lead(
        leadId: '', // Let the API generate UUID
        name: name,
        email: (formData['email'] ?? '').toString().trim(),
        phone: (formData['phone'] ?? '').toString().trim(),
        whatsappNumber: formData['whatsappNumber'] ?? '',
        source: formData['source'] ?? LeadSource.website,
        createdAt: DateTime.now(),
        status: formData['status'] ?? LeadStatusConstants.defaultValue,
        notes: formData['notes']?.isNotEmpty == true ? formData['notes'] : null,
        priority: formData['priority'] ?? PriorityConstants.defaultValue,
        nextFollowUp: nextFollowUp,
        customerType:
            formData['customerType'] ?? CustomerTypeConstants.defaultValue,
        projectType:
            formData['projectType'] ?? ProjectTypeConstants.defaultValue,
        budget: formData['budget'],
        projectSqftArea: formData['projectSqftArea'],
        clientRating: formData['clientRating'] ?? 3,
        probabilityToWin: formData['probabilityToWin'] ?? 50,
        lastContactDate: lastContactDate,
        assignedTeam: formData['assignedTeam'] ?? '',
        assignedToId: formData['assignedToId'], // Add assignedToId
        state: formData['state'] ?? IndiaLocationData.getDefaultState(),
        district: formData['district'] ?? '',
        location: formData['location'] ?? '',
        address: formData['address'] ?? '',
        projectDescription: formData['projectDescription'] ?? '',
        requirements: formData['requirements'] ?? '',
        dateOfEnquiry: dateOfEnquiry ?? DateTime.now(),
        lostReason: formData['lostReason']?.isNotEmpty == true
            ? formData['lostReason']
            : null,
      );

      await _leadService.createLead(lead);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(AddLeadConstants.saveSuccessMessage),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e, stackTrace) {
      if (mounted) {
        await ErrorHandler.handleApiError(context, e, defaultMessage: 'Error creating lead');
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }
}

