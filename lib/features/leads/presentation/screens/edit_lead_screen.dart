import 'package:flutter/material.dart';
import 'package:admin/constants.dart';
import '../../data/models/lead.dart';
import 'controllers/edit_lead_controller.dart';
import 'components/form_sections.dart';
import 'constants/edit_lead_constants.dart';
import 'package:admin/constants/project_type_constants.dart';
import 'components/lead_activity_timeline.dart';
import 'components/lead_tasks_tab.dart';
import 'components/lead_documents_tab.dart';

class EditLeadScreen extends StatefulWidget {
  final Lead lead;
  const EditLeadScreen({super.key, required this.lead});

  @override
  State<EditLeadScreen> createState() => _EditLeadScreenState();
}

class _EditLeadScreenState extends State<EditLeadScreen> {
  late EditLeadController _controller;

  @override
  void initState() {
    super.initState();
    _controller = EditLeadController(widget.lead);
    _controller.addListener(_onControllerChanged);
    // Controller will initialize asynchronously and notify listeners when ready
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) {
      setState(() {});
    }
  }

// ... class definition ...

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4, // Updated to 4
      child: Scaffold(
        appBar: AppBar(
          title: Text('${EditLeadConstants.appBarTitle}: ${widget.lead.name}'),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Details'),
              Tab(text: 'Tasks'),
              Tab(text: 'Documents'),
              Tab(text: 'History'),
            ],
            labelColor: primaryColor,
            unselectedLabelColor: Colors.grey,
            indicatorColor: primaryColor,
          ),
          actions: [
            // Convert Button (Only for WON status check logic handled inside or visually disabled)
            if (widget.lead.status.toLowerCase() != 'won')
              TextButton.icon(
                onPressed: _showConvertDialog,
                icon: const Icon(Icons.check_circle_outline, color: primaryColor),
                label: const Text("Convert into Customer", style: TextStyle(color: primaryColor)),
              ),
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveLead,
              tooltip: EditLeadConstants.saveTooltip,
            ),
          ],
        ),
        body: TabBarView(
          children: [
            // Tab 1: Details
            _controller.isInitializing || _controller.isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(defaultPadding),
                    child: Form(
                      key: _controller.formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionHeader(EditLeadConstants.basicInfoHeader),
                          FormSections.buildBasicInfoSection(
                            formData: _controller.formData,
                            onChanged: _controller.updateFormData,
                            context: context,
                          ),
                          const SizedBox(height: defaultPadding),
                          _buildSectionHeader(EditLeadConstants.locationHeader),
                          FormSections.buildLocationSection(
                            formData: _controller.formData,
                            onChanged: _controller.updateFormData,
                            context: context,
                          ),
                          const SizedBox(height: defaultPadding),
                          _buildSectionHeader(EditLeadConstants.projectHeader),
                          FormSections.buildProjectSection(
                            context: context,
                            formData: _controller.formData,
                            onChanged: _controller.updateFormData,
                            onDateOfEnquiryChanged: _controller.updateDateOfEnquiry,
                          ),
                          const SizedBox(height: defaultPadding),
                          _buildSectionHeader(EditLeadConstants.salesHeader),
                          FormSections.buildSalesSection(
                            context: context,
                            formData: _controller.formData,
                            onChanged: _controller.updateFormData,
                            onNextFollowUpChanged: _controller.updateNextFollowUp,
                            onLastContactDateChanged:
                                _controller.updateLastContactDate,
                            teamMembers: _controller.teamMembers,
                            isLoadingTeamMembers: _controller.isLoadingTeamMembers,
                          ),
                          const SizedBox(height: defaultPadding),
                          _buildSectionHeader(EditLeadConstants.additionalHeader),
                          FormSections.buildAdditionalSection(
                            context: context,
                            formData: _controller.formData,
                            onChanged: _controller.updateFormData,

                          ),
                          const SizedBox(height: defaultPadding * 2),
                          _buildActionButtons(),
                        ],
                      ),
                    ),
                  ),
            // Tab 2: Tasks
            LeadTasksTab(leadId: widget.lead.leadId),
            // Tab 3: Documents
            LeadDocumentsTab(leadId: widget.lead.leadId),
            // Tab 4: History
            LeadActivityTimeline(leadId: widget.lead.leadId),
          ],
        ),
      ),
    );
  }

  Future<void> _showConvertDialog() async {
    final GlobalKey<FormState> conversionFormKey = GlobalKey<FormState>();
    final TextEditingController projectNameController = TextEditingController(text: '${widget.lead.name} Project');
    final TextEditingController startDateController = TextEditingController(text: DateTime.now().toString().substring(0, 10));
    final TextEditingController locationController = TextEditingController(text: widget.lead.location.isNotEmpty ? widget.lead.location : (widget.lead.district.isNotEmpty ? widget.lead.district : widget.lead.state));

    String projectType = widget.lead.projectType.isNotEmpty ? widget.lead.projectType : ProjectTypeConstants.defaultValue;
    DateTime selectedDate = DateTime.now();

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Convert into Customer"),
          content: SizedBox(
            width: 500,
            child: Form(
              key: conversionFormKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                   Text('Convert "${widget.lead.name}" into a Customer? This will create a Customer account and a Project.', style: TextStyle(color: Colors.grey[700])),
                   const SizedBox(height: 20),
                   TextFormField(
                    controller: projectNameController,
                    decoration: const InputDecoration(labelText: 'Project Name *', border: OutlineInputBorder()),
                    validator: (v) => v?.isNotEmpty == true ? null : 'Required',
                  ),
                   const SizedBox(height: 10),
                   DropdownButtonFormField<String>(
                    value: projectType,
                    decoration: const InputDecoration(labelText: 'Project Type', border: OutlineInputBorder()),
                    items: ProjectTypeConstants.formDropdownItems,
                    onChanged: (v) => projectType = v!,
                  ),
                   const SizedBox(height: 10),
                   TextFormField(
                    controller: locationController,
                    decoration: const InputDecoration(labelText: 'Location / Site Address', border: OutlineInputBorder()),
                  ),
                   const SizedBox(height: 10),
                   TextFormField(
                    controller: startDateController,
                    decoration: const InputDecoration(
                      labelText: 'Start Date', 
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    readOnly: true,
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context, 
                        initialDate: selectedDate, 
                        firstDate: DateTime(2000), 
                        lastDate: DateTime(2100)
                      );
                      if(date != null) {
                        selectedDate = date;
                        startDateController.text = date.toString().substring(0, 10);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                if(conversionFormKey.currentState!.validate()){
                   Navigator.pop(context, {
                    "projectName": projectNameController.text,
                    "projectType": projectType,
                    "startDate": startDateController.text,
                    "location": locationController.text,
                  });
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
              child: const Text("Convert"),
            ),
          ],
        );
      },
    );

    if (result != null) {
      try {
        await _controller.convertLead(result);
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Lead converted into Customer successfully!"), backgroundColor: Colors.green));
           Navigator.pop(context, true); // Go back to list
        }
      } catch (e) {
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
        }
      }
    }
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
            onPressed: _controller.isLoading ? null : _saveLead,
            child: const Text(
              EditLeadConstants.saveButtonText,
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
            onPressed:
                _controller.isLoading ? null : () => Navigator.pop(context),
            child: const Text(EditLeadConstants.cancelButtonText),
          ),
        ),
      ],
    );
  }

  Future<void> _saveLead() async {
    final success = await _controller.saveLead();

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(EditLeadConstants.saveSuccessMessage),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_controller.errorMessage ??
                EditLeadConstants.validationErrorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(
                seconds: EditLeadConstants.errorSnackbarDuration),
          ),
        );
      }
    }
  }
}

