import 'package:flutter/material.dart';
import '../../../constants.dart';
import '../../../models/lead.dart';
import '../../../models/team_member_simple.dart';
import '../../../constants/customer_type_constants.dart';
import '../../../constants/lead_status_constants.dart';
import '../../../constants/priority_constants.dart';
import '../../../constants/lead_source_constants.dart';
import '../../../constants/project_type_constants.dart';
import '../../../utils/india_location_data.dart';
import '../../../responsive.dart';

class FormSections {
  // Helper method to create responsive row/column
  static Widget _responsiveRow(
    BuildContext context,
    List<Widget> children, {
    bool forceColumn = false,
  }) {
    if (forceColumn || Responsive.isMobile(context)) {
      return Column(
        children: children
            .expand(
                (widget) => [widget, const SizedBox(height: defaultPadding)])
            .toList()
          ..removeLast(), // Remove last spacing
      );
    } else {
      return Row(
        children: children
            .expand((widget) => [widget, const SizedBox(width: defaultPadding)])
            .toList()
          ..removeLast(), // Remove last spacing
      );
    }
  }

  static Widget buildBasicInfoSection({
    required Map<String, dynamic> formData,
    required Function(String, dynamic) onChanged,
    required BuildContext context,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(defaultPadding),
        child: Column(
          children: [
            _responsiveRow(
              context,
              [
                Expanded(
                  child: TextFormField(
                    initialValue: formData['name'],
                    decoration: const InputDecoration(
                      labelText: 'Full Name *',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) =>
                        value?.isEmpty == true ? 'Name is required' : null,
                    onChanged: (value) => onChanged('name', value ?? ''),
                    onSaved: (value) => onChanged('name', value ?? ''),
                  ),
                ),
                Expanded(
                  child: TextFormField(
                    initialValue: formData['email'],
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value?.isNotEmpty == true) {
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                            .hasMatch(value!)) {
                          return 'Enter a valid email';
                        }
                      }
                      return null;
                    },
                    onChanged: (value) => onChanged('email', value ?? ''),
                    onSaved: (value) => onChanged('email', value ?? ''),
                  ),
                ),
              ],
            ),
            const SizedBox(height: defaultPadding),
            _responsiveRow(
              context,
              [
                Expanded(
                  child: TextFormField(
                    initialValue: formData['phone'],
                    decoration: const InputDecoration(
                      labelText: 'Phone Number *',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value?.isEmpty == true) {
                        return 'Phone is required';
                      }
                      if (value != null && value.length < 10) {
                        return 'Phone number must be at least 10 digits';
                      }
                      return null;
                    },
                    onChanged: (value) => onChanged('phone', value ?? ''),
                    onSaved: (value) => onChanged('phone', value ?? ''),
                  ),
                ),
                Expanded(
                  child: TextFormField(
                    initialValue: formData['whatsappNumber'],
                    decoration: const InputDecoration(
                      labelText: 'WhatsApp Number',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value?.isNotEmpty == true && value!.length < 10) {
                        return 'WhatsApp number must be at least 10 digits';
                      }
                      return null;
                    },
                    onChanged: (value) =>
                        onChanged('whatsappNumber', value ?? ''),
                    onSaved: (value) =>
                        onChanged('whatsappNumber', value ?? ''),
                  ),
                ),
              ],
            ),
            const SizedBox(height: defaultPadding),
            _responsiveRow(
              context,
              [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Customer Type *',
                      border: OutlineInputBorder(),
                    ),
                    isExpanded: true,
                    value: formData['customerType'],
                    items: CustomerTypeConstants.dropdownItems,
                    onChanged: (val) => onChanged('customerType',
                        val ?? CustomerTypeConstants.defaultValue),
                    onSaved: (value) => onChanged('customerType',
                        value ?? CustomerTypeConstants.defaultValue),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select a customer type';
                      }
                      return null;
                    },
                  ),
                ),
                Expanded(
                  child: DropdownButtonFormField<LeadSource>(
                    decoration: const InputDecoration(
                      labelText: 'Lead Source *',
                      border: OutlineInputBorder(),
                    ),
                    isExpanded: true,
                    value: formData['source'],
                    items: LeadSourceConstants.dropdownItems,
                    onChanged: (val) =>
                        onChanged('source', val ?? LeadSource.website),
                    onSaved: (value) =>
                        onChanged('source', value ?? LeadSource.website),
                    validator: (value) {
                      if (value == null) {
                        return 'Please select a lead source';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static Widget buildLocationSection({
    required Map<String, dynamic> formData,
    required Function(String, dynamic) onChanged,
    required BuildContext context,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(defaultPadding),
        child: Column(
          children: [
            _responsiveRow(
              context,
              [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'State *',
                      border: OutlineInputBorder(),
                    ),
                    isExpanded: true,
                    value: formData['state']?.isNotEmpty == true
                        ? formData['state']
                        : null,
                    items: IndiaLocationData.getStates()
                        .map((state) => DropdownMenuItem(
                              value: state,
                              child: Text(state),
                            ))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        // Update state
                        onChanged('state', value);
                        // Reset district when state changes
                        onChanged('district', '');
                      }
                    },
                    onSaved: (value) {
                      if (value != null) {
                        onChanged('state', value);
                      }
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select a state';
                      }
                      return null;
                    },
                  ),
                ),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'District *',
                      border: OutlineInputBorder(),
                    ),
                    isExpanded: true,
                    value: formData['district']?.isNotEmpty == true
                        ? formData['district']
                        : null,
                    items: formData['state']?.isNotEmpty == true
                        ? IndiaLocationData.getDistricts(formData['state'])
                            .map((district) => DropdownMenuItem(
                                  value: district,
                                  child: Text(district),
                                ))
                            .toList()
                        : [],
                    onChanged: (value) {
                      if (value != null) {
                        onChanged('district', value);
                      }
                    },
                    onSaved: (value) {
                      if (value != null) {
                        onChanged('district', value);
                      }
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select a district';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: defaultPadding),
            _responsiveRow(
              context,
              [
                Expanded(
                  child: TextFormField(
                    initialValue: formData['location'],
                    decoration: const InputDecoration(
                      labelText: 'Location',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) => onChanged('location', value ?? ''),
                    onSaved: (value) => onChanged('location', value ?? ''),
                  ),
                ),
                Expanded(
                  child: TextFormField(
                    initialValue: formData['address'],
                    decoration: const InputDecoration(
                      labelText: 'Address',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) => onChanged('address', value ?? ''),
                    onSaved: (value) => onChanged('address', value ?? ''),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static Widget buildProjectSection({
    required BuildContext context,
    required Map<String, dynamic> formData,
    required Function(String, dynamic) onChanged,
    required Function(DateTime?) onDateOfEnquiryChanged,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(defaultPadding),
        child: Column(
          children: [
            _responsiveRow(
              context,
              [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Project Type',
                      border: OutlineInputBorder(),
                    ),
                    isExpanded: true,
                    value: formData['projectType']?.isNotEmpty == true
                        ? formData['projectType']
                        : null,
                    items: ProjectTypeConstants.formDropdownItems,
                    onChanged: (val) => onChanged('projectType', val ?? ''),
                    onSaved: (value) => onChanged('projectType', value ?? ''),
                  ),
                ),
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate:
                            formData['dateOfEnquiry'] ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) onDateOfEnquiryChanged(picked);
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Date of Enquiry',
                        border: OutlineInputBorder(),
                      ),
                      child: Text(
                        formData['dateOfEnquiry']
                                ?.toString()
                                .substring(0, 10) ??
                            'Select Date',
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: defaultPadding),
            TextFormField(
              initialValue: formData['projectDescription'],
              decoration: const InputDecoration(
                labelText: 'Project Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              onChanged: (value) =>
                  onChanged('projectDescription', value ?? ''),
            ),
            const SizedBox(height: defaultPadding),
            TextFormField(
              initialValue: formData['requirements'],
              decoration: const InputDecoration(
                labelText: 'Requirements',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              onChanged: (value) => onChanged('requirements', value ?? ''),
            ),
            const SizedBox(height: defaultPadding),
            _responsiveRow(
              context,
              [
                Expanded(
                  child: TextFormField(
                    initialValue: formData['budget']?.toString() ?? '',
                    decoration: const InputDecoration(
                      labelText: 'Budget (₹)',
                      border: OutlineInputBorder(),
                      prefixText: '₹ ',
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      if (value != null && value.isNotEmpty) {
                        onChanged('budget', double.tryParse(value) ?? 0.0);
                      }
                    },
                    onSaved: (value) {
                      if (value != null && value.isNotEmpty) {
                        onChanged('budget', double.tryParse(value) ?? 0.0);
                      }
                    },
                  ),
                ),
                Expanded(
                  child: TextFormField(
                    initialValue: formData['projectSqftArea']?.toString() ?? '',
                    decoration: const InputDecoration(
                      labelText: 'Project Area (sq ft)',
                      border: OutlineInputBorder(),
                      suffixText: 'sq ft',
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      if (value != null && value.isNotEmpty) {
                        onChanged(
                            'projectSqftArea', double.tryParse(value) ?? 0.0);
                      }
                    },
                    onSaved: (value) {
                      if (value != null && value.isNotEmpty) {
                        onChanged(
                            'projectSqftArea', double.tryParse(value) ?? 0.0);
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static Widget buildSalesSection({
    required BuildContext context,
    required Map<String, dynamic> formData,
    required Function(String, dynamic) onChanged,
    required Function(DateTime?) onNextFollowUpChanged,
    required Function(DateTime?) onLastContactDateChanged,
    List<TeamMemberSimple>? teamMembers,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(defaultPadding),
        child: Column(
          children: [
            _responsiveRow(
              context,
              [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Lead Status *',
                      border: OutlineInputBorder(),
                    ),
                    isExpanded: true,
                    value: formData['status'],
                    items: LeadStatusConstants.dropdownItems,
                    onChanged: (val) => onChanged(
                        'status', val ?? LeadStatusConstants.defaultValue),
                    onSaved: (value) => onChanged(
                        'status', value ?? LeadStatusConstants.defaultValue),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select a status';
                      }
                      return null;
                    },
                  ),
                ),
                Expanded(
                  child: DropdownButtonFormField<LeadPriority>(
                    decoration: const InputDecoration(
                      labelText: 'Priority *',
                      border: OutlineInputBorder(),
                    ),
                    value: formData['priority'],
                    items: PriorityConstants.dropdownItems,
                    onChanged: (val) => onChanged(
                        'priority', val ?? PriorityConstants.defaultValue),
                    onSaved: (value) => onChanged(
                        'priority', value ?? PriorityConstants.defaultValue),
                    validator: (value) {
                      if (value == null) {
                        return 'Please select a priority';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: defaultPadding),
            // Conditionally show lost reason field when status is 'lost'
            if (formData['status'] == 'lost')
              Column(
                children: [
                  TextFormField(
                    initialValue: formData['lostReason'],
                    decoration: const InputDecoration(
                      labelText: 'Lost Reason *',
                      border: OutlineInputBorder(),
                      hintText: 'Please specify why this lead was lost',
                    ),
                    maxLines: 2,
                    validator: (value) {
                      if (formData['status'] == 'lost' &&
                          (value == null || value.trim().isEmpty)) {
                        return 'Lost reason is required when status is Lost';
                      }
                      return null;
                    },
                    onChanged: (value) => onChanged('lostReason', value),
                    onSaved: (value) => onChanged('lostReason', value ?? ''),
                  ),
                  const SizedBox(height: defaultPadding),
                ],
              ),
            Responsive.isMobile(context)
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      teamMembers != null && teamMembers.isNotEmpty
                          ? DropdownButtonFormField<String>(
                              decoration: const InputDecoration(
                                labelText: 'Assigned Team Member',
                                border: OutlineInputBorder(),
                              ),
                              value: formData['assignedTeam']
                                          ?.toString()
                                          .isNotEmpty ==
                                      true
                                  ? formData['assignedTeam'].toString()
                                  : null,
                              items: [
                                const DropdownMenuItem<String>(
                                  value: '',
                                  child: Text('-- Not Assigned --'),
                                ),
                                ...teamMembers
                                    .map((member) => DropdownMenuItem<String>(
                                          value: member.id.toString(),
                                          child: Text(member.fullName),
                                        )),
                              ],
                              onChanged: (value) =>
                                  onChanged('assignedTeam', value ?? ''),
                              onSaved: (value) =>
                                  onChanged('assignedTeam', value ?? ''),
                            )
                          : TextFormField(
                              initialValue: formData['assignedTeam'],
                              decoration: const InputDecoration(
                                labelText: 'Assigned Team',
                                border: OutlineInputBorder(),
                              ),
                              onChanged: (value) =>
                                  onChanged('assignedTeam', value ?? ''),
                            ),
                      const SizedBox(height: defaultPadding),
                      Row(
                        children: [
                          const Text('Client Rating: '),
                          ...List.generate(
                            5,
                            (index) => IconButton(
                              icon: Icon(
                                index < (formData['clientRating'] as int)
                                    ? Icons.star
                                    : Icons.star_border,
                                color: Colors.amber,
                                size: 24,
                              ),
                              padding: const EdgeInsets.all(4),
                              constraints: const BoxConstraints(),
                              onPressed: () =>
                                  onChanged('clientRating', index + 1),
                            ),
                          ),
                        ],
                      ),
                    ],
                  )
                : Row(
                    children: [
                      Expanded(
                        child: teamMembers != null && teamMembers.isNotEmpty
                            ? DropdownButtonFormField<String>(
                                decoration: const InputDecoration(
                                  labelText: 'Assigned Team Member',
                                  border: OutlineInputBorder(),
                                ),
                                value: formData['assignedTeam']
                                            ?.toString()
                                            .isNotEmpty ==
                                        true
                                    ? formData['assignedTeam'].toString()
                                    : null,
                                items: [
                                  const DropdownMenuItem<String>(
                                    value: '',
                                    child: Text('-- Not Assigned --'),
                                  ),
                                  ...teamMembers
                                      .map((member) => DropdownMenuItem<String>(
                                            value: member.id.toString(),
                                            child: Text(member.fullName),
                                          )),
                                ],
                                onChanged: (value) =>
                                    onChanged('assignedTeam', value ?? ''),
                                onSaved: (value) =>
                                    onChanged('assignedTeam', value ?? ''),
                              )
                            : TextFormField(
                                initialValue: formData['assignedTeam'],
                                decoration: const InputDecoration(
                                  labelText: 'Assigned Team',
                                  border: OutlineInputBorder(),
                                ),
                                onChanged: (value) =>
                                    onChanged('assignedTeam', value ?? ''),
                              ),
                      ),
                      const SizedBox(width: defaultPadding),
                      Expanded(
                        child: Row(
                          children: [
                            const Text('Client Rating: '),
                            ...List.generate(
                              5,
                              (index) => IconButton(
                                icon: Icon(
                                  index < (formData['clientRating'] as int)
                                      ? Icons.star
                                      : Icons.star_border,
                                  color: Colors.amber,
                                  size: 28,
                                ),
                                onPressed: () =>
                                    onChanged('clientRating', index + 1),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
            const SizedBox(height: defaultPadding),
            _responsiveRow(
              context,
              [
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: formData['nextFollowUp'] ?? DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) onNextFollowUpChanged(picked);
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Next Follow-up',
                        border: OutlineInputBorder(),
                      ),
                      child: Text(
                        formData['nextFollowUp']?.toString().substring(0, 10) ??
                            'Select Date',
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate:
                            formData['lastContactDate'] ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) onLastContactDateChanged(picked);
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Last Contact Date',
                        border: OutlineInputBorder(),
                      ),
                      child: Text(
                        formData['lastContactDate']
                                ?.toString()
                                .substring(0, 10) ??
                            'Select Date',
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: defaultPadding),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: (formData['probabilityToWin'] as int).toDouble(),
                    min: 0,
                    max: 100,
                    divisions: 20,
                    label: '${formData['probabilityToWin']}%',
                    onChanged: (value) =>
                        onChanged('probabilityToWin', value.round()),
                  ),
                ),
                const SizedBox(width: defaultPadding),
                Text('Win Probability: ${formData['probabilityToWin']}%'),
              ],
            ),
            const SizedBox(height: defaultPadding),
          ],
        ),
      ),
    );
  }

  static Widget buildAdditionalSection({
    required BuildContext context,
    required Map<String, dynamic> formData,
    required Function(String, dynamic) onChanged,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(defaultPadding),
        child: Column(
          children: [
            TextFormField(
              initialValue: formData['notes'],
              decoration: const InputDecoration(
                labelText: 'Notes',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              onChanged: (value) => onChanged('notes', value),
              onSaved: (value) => onChanged('notes', value),
            ),
            const SizedBox(height: defaultPadding),
          ],
        ),
      ),
    );
  }
}
