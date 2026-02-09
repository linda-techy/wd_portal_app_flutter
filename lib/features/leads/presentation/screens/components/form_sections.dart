import 'package:flutter/material.dart';
import 'package:admin/constants.dart';
import 'package:admin/features/leads/data/models/lead.dart';
import 'package:admin/models/portal_user.dart';
import 'package:admin/constants/customer_type_constants.dart';
import 'package:admin/constants/lead_status_constants.dart';
import 'package:admin/constants/priority_constants.dart';
import 'package:admin/constants/lead_source_constants.dart';
import 'package:admin/constants/project_type_constants.dart';
import 'package:admin/utils/india_location_data.dart';
import 'package:admin/responsive.dart';
import 'package:admin/config/app_config.dart';

class FormSections {
  /// Helper method to validate dropdown value exists in items list
  /// Returns the value if it exists, null otherwise
  static T? _validateDropdownValue<T>(
    dynamic value,
    List<DropdownMenuItem<T>> items,
  ) {
    if (value == null) {
      return null;
    }

    // Check if value exists in items
    final exists = items.any((item) => item.value == value);
    if (exists) {
      return value as T;
    }

    // Value not found in items - return null to avoid Flutter error
    return null;
  }

  // Helper method to build Assigned To field with proper loading state
  static Widget _buildAssignedToField({
    required bool isLoading,
    List<PortalUser>? teamMembers,
    required Map<String, dynamic> formData,
    required Function(String, dynamic) onChanged,
  }) {
    // Show loading indicator while team members are being fetched
    if (isLoading) {
      return const InputDecorator(
        decoration: InputDecoration(
          labelText: 'Assigned To',
          border: OutlineInputBorder(),
          prefixIcon: Padding(
            padding: EdgeInsets.all(12.0),
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
        child: Text('Loading team members...'),
      );
    }

    // Show dropdown only when team members are loaded
    if (teamMembers != null && teamMembers.isNotEmpty) {
      // Parse assignedToId value properly
      int? selectedValue;
      final assignedToIdValue = formData['assignedToId'];

      if (assignedToIdValue is int) {
        selectedValue = assignedToIdValue;
      } else if (assignedToIdValue != null) {
        selectedValue = int.tryParse(assignedToIdValue.toString());
      }

      // Verify the selected value exists in the team members list
      if (selectedValue != null) {
        final exists =
            teamMembers.any((m) => m.id != null && m.id == selectedValue);
        if (!exists) {
          // Try to find by comparing as strings as well
          final existsAsString = teamMembers
              .any((m) => m.id?.toString() == selectedValue.toString());
          if (existsAsString) {
            // Find the actual user and use their ID
            final matchingUser = teamMembers.firstWhere(
              (m) => m.id?.toString() == selectedValue.toString(),
              orElse: () => teamMembers.first,
            );
            selectedValue = matchingUser.id;
          }
        }
      }

      // Ensure selectedValue matches an item in the dropdown
      // If selectedValue doesn't match any item, set it to null to avoid Flutter error
      int? finalSelectedValue = selectedValue;
      if (selectedValue != null) {
        final hasMatchingItem =
            teamMembers.any((m) => m.id != null && m.id == selectedValue);
        if (!hasMatchingItem) {
          finalSelectedValue = null;
        }
      }

      return DropdownButtonFormField<int>(
        decoration: const InputDecoration(
          labelText: 'Assigned To',
          border: OutlineInputBorder(),
        ),
        value: finalSelectedValue,
        items: [
          const DropdownMenuItem<int>(
            value: null,
            child: Text('-- Not Assigned --'),
          ),
          ...teamMembers.where((m) => m.id != null).map((member) {
            final isSelected = member.id == finalSelectedValue;
            return DropdownMenuItem<int>(
              value: member.id,
              child: Text(member.fullName),
            );
          }),
        ],
        onChanged: (value) {
          onChanged('assignedToId', value);
        },
        onSaved: (value) {
          onChanged('assignedToId', value);
        },
      );
    }

    // If no team members loaded and not loading, show empty state
    return DropdownButtonFormField<int>(
      decoration: const InputDecoration(
        labelText: 'Assigned To',
        border: OutlineInputBorder(),
        helperText: 'No team members available',
      ),
      value: null,
      items: const [
        DropdownMenuItem<int>(
          value: null,
          child: Text('-- Not Assigned --'),
        ),
      ],
      onChanged: (value) {
        onChanged('assignedToId', value);
      },
    );
  }

  // Helper method to create responsive row/column
  static Widget _responsiveRow(
    BuildContext context,
    List<Widget> children, {
    bool forceColumn = false,
  }) {
    if (forceColumn || Responsive.isMobile(context)) {
      // Expanded/Flexible cannot be inside a Column within a scroll view
      // Unwrap Expanded to its child for mobile/column layout
      final List<Widget> columnChildren =
          children.map((w) => w is Expanded ? w.child : w).toList();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: columnChildren
            .expand(
                (widget) => [widget, const SizedBox(height: defaultPadding)])
            .toList()
          ..removeLast(),
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
                    onChanged: (value) => onChanged('name', value),
                    onSaved: (value) => onChanged('name', value),
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
                    onChanged: (value) => onChanged('email', value),
                    onSaved: (value) => onChanged('email', value),
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
                    onChanged: (value) => onChanged('phone', value),
                    onSaved: (value) => onChanged('phone', value),
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
                    onChanged: (value) => onChanged('whatsappNumber', value),
                    onSaved: (value) => onChanged('whatsappNumber', value),
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
                    // Validate value exists in items before setting
                    value: _validateDropdownValue<String>(
                      formData['customerType'],
                      CustomerTypeConstants.dropdownItems,
                    ),
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
                    // Validate value exists in items before setting
                    value: _validateDropdownValue<LeadSource>(
                      formData['source'],
                      LeadSourceConstants.dropdownItems,
                    ),
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
                    // Validate value exists in items before setting
                    value: _validateDropdownValue<String>(
                      formData['state']?.isNotEmpty == true
                          ? formData['state']
                          : null,
                      IndiaLocationData.getStates()
                          .map((state) => DropdownMenuItem(
                                value: state,
                                child: Text(state),
                              ))
                          .toList(),
                    ),
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
                        return 'State is required';
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
                    // Get district items based on state
                    items: formData['state']?.isNotEmpty == true
                        ? IndiaLocationData.getDistricts(formData['state'])
                            .map((district) => DropdownMenuItem(
                                  value: district,
                                  child: Text(district),
                                ))
                            .toList()
                        : [],
                    // Validate value exists in items before setting (only if state is set)
                    value: formData['state']?.isNotEmpty == true
                        ? _validateDropdownValue<String>(
                            formData['district']?.isNotEmpty == true
                                ? formData['district']
                                : null,
                            IndiaLocationData.getDistricts(formData['state'])
                                .map((district) => DropdownMenuItem(
                                      value: district,
                                      child: Text(district),
                                    ))
                                .toList(),
                          )
                        : null,
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
                        return 'District is required';
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
                    onChanged: (value) => onChanged('location', value),
                    onSaved: (value) => onChanged('location', value),
                  ),
                ),
                Expanded(
                  child: TextFormField(
                    initialValue: formData['address'],
                    decoration: const InputDecoration(
                      labelText: 'Address',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) => onChanged('address', value),
                    onSaved: (value) => onChanged('address', value),
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
                    // Validate value exists in items before setting
                    value: _validateDropdownValue<String>(
                      formData['projectType']?.isNotEmpty == true
                          ? formData['projectType']
                          : null,
                      ProjectTypeConstants.formDropdownItems,
                    ),
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
                        firstDate: AppConfig.datePickerFirstDate,
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
              onChanged: (value) => onChanged('projectDescription', value),
            ),
            const SizedBox(height: defaultPadding),
            TextFormField(
              initialValue: formData['requirements'],
              decoration: const InputDecoration(
                labelText: 'Requirements',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              onChanged: (value) => onChanged('requirements', value),
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
                      if (value.isNotEmpty) {
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
                      if (value.isNotEmpty) {
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
    List<PortalUser>? teamMembers, // Use PortalUser
    bool isLoadingTeamMembers = false, // Loading state
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
                    // Validate value exists in items before setting
                    value: _validateDropdownValue<String>(
                      formData['status'],
                      LeadStatusConstants.dropdownItems,
                    ),
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
                    // Validate value exists in items before setting
                    value: _validateDropdownValue<LeadPriority>(
                      formData['priority'],
                      PriorityConstants.dropdownItems,
                    ),
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
                    onSaved: (value) => onChanged('lostReason', value),
                  ),
                  const SizedBox(height: defaultPadding),
                ],
              ),
            Responsive.isMobile(context)
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildAssignedToField(
                        isLoading: isLoadingTeamMembers,
                        teamMembers: teamMembers,
                        formData: formData,
                        onChanged: onChanged,
                      ),
                      const SizedBox(height: defaultPadding),
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 4,
                        runSpacing: 4,
                        children: [
                          const Text('Client Rating:'),
                          ...List.generate(
                            5,
                            (index) => IconButton(
                              icon: Icon(
                                index < (formData['clientRating'] as int)
                                    ? Icons.star
                                    : Icons.star_border,
                                color: Colors.amber,
                                size: 22,
                              ),
                              padding: const EdgeInsets.all(2),
                              constraints: const BoxConstraints(),
                              onPressed: () =>
                                  onChanged('clientRating', index + 1),
                            ),
                          ),
                        ],
                      ),
                    ],
                  )
                : Wrap(
                    spacing: defaultPadding,
                    runSpacing: defaultPadding,
                    crossAxisAlignment: WrapCrossAlignment.start,
                    children: [
                      SizedBox(
                        width: 380,
                        child: _buildAssignedToField(
                          isLoading: isLoadingTeamMembers,
                          teamMembers: teamMembers,
                          formData: formData,
                          onChanged: onChanged,
                        ),
                      ),
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          const Text('Client Rating:'),
                          ...List.generate(
                            5,
                            (index) => IconButton(
                              icon: Icon(
                                index < (formData['clientRating'] as int)
                                    ? Icons.star
                                    : Icons.star_border,
                                color: Colors.amber,
                                size: 26,
                              ),
                              onPressed: () =>
                                  onChanged('clientRating', index + 1),
                            ),
                          ),
                        ],
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
                        firstDate: AppConfig.datePickerFirstDate,
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
