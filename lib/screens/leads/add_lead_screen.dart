import 'package:flutter/material.dart';
import '../../../constants.dart';
import '../../../models/lead.dart';
import '../../../models/team_member_simple.dart';
import '../../../services/crm_service.dart';
import '../../../utils/india_location_data.dart';
import '../../../constants/customer_type_constants.dart';
import '../../../constants/lead_status_constants.dart';
import '../../../constants/priority_constants.dart';

import '../../../constants/project_type_constants.dart';
import 'constants/add_lead_constants.dart';
import 'components/form_sections.dart';

class AddLeadScreen extends StatefulWidget {
  const AddLeadScreen({super.key});

  @override
  State<AddLeadScreen> createState() => _AddLeadScreenState();
}

class _AddLeadScreenState extends State<AddLeadScreen> {
  final _formKey = GlobalKey<FormState>();
  final CRMService _crmService = CRMService();

  // Form data map - similar to edit lead screen
  late Map<String, dynamic> formData;

  // Dates
  DateTime? dateOfEnquiry;
  DateTime? nextFollowUp;
  DateTime? lastContactDate;

  bool isLoading = false;
  List<TeamMemberSimple> teamMembers = [];

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

    // Load team members
    _loadTeamMembers();
  }

  Future<void> _loadTeamMembers() async {
    try {
      final members = await _crmService.getTeamMembersForAssignment();
      setState(() {
        teamMembers = members;
      });
    } catch (e) {
      print('Error loading team members: $e');
      // Continue without team members - form will show text field instead
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
      body: isLoading
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
            child: Text(
              AddLeadConstants.saveButtonText,
              style: const TextStyle(color: Colors.white, fontSize: 16),
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
            child: Text(AddLeadConstants.cancelButtonText),
          ),
        ),
      ],
    );
  }

  Future<void> _saveLead() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() => isLoading = true);

    try {
      // Validate required fields
      final String name = (formData['name'] ?? '').toString().trim();
      if (name.isEmpty) {
        if (mounted) {
          setState(() => isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Name is required')),
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

      await _crmService.createLead(lead);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(AddLeadConstants.saveSuccessMessage),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating lead: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }
}
