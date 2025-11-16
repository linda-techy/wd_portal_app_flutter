import 'package:flutter/material.dart';
import '../../models/lead.dart';
import '../../utils/india_location_data.dart';

class LeadForm extends StatefulWidget {
  final Lead? lead;
  final void Function(Lead) onSave;
  const LeadForm({super.key, this.lead, required this.onSave});

  @override
  State<LeadForm> createState() => _LeadFormState();
}

class _LeadFormState extends State<LeadForm> {
  final _formKey = GlobalKey<FormState>();
  late String name,
      email,
      phone,
      customerType,
      projectType,
      status,
      assignedTeam,
      state,
      district,
      location,
      projectDescription,
      requirements;
  late LeadSource source;
  late LeadPriority priority;
  double? budget;
  double? projectSqftArea;
  int clientRating = 0, probabilityToWin = 0;
  DateTime? createdAt, nextFollowUp, lastContactDate, dateOfEnquiry;

  // Location dropdowns
  List<String> availableDistricts = [];

  @override
  void initState() {
    super.initState();
    final l = widget.lead;
    name = l?.name ?? '';
    email = l?.email ?? '';
    phone = l?.phone ?? '';
    customerType = l?.customerType ?? '';
    projectType = l?.projectType ?? '';
    status = l?.status ?? 'New Inquiry';
    assignedTeam = l?.assignedTeam ?? '';
    state = l?.state ?? IndiaLocationData.getDefaultState();
    district = l?.district ?? IndiaLocationData.getDefaultDistrict(state);
    location = l?.location ?? '';
    projectDescription = l?.projectDescription ?? '';
    requirements = l?.requirements ?? '';
    source = l?.source ?? LeadSource.website;
    priority = l?.priority ?? LeadPriority.low;
    budget = l?.budget;
    projectSqftArea = l?.projectSqftArea;
    clientRating = l?.clientRating ?? 0;
    probabilityToWin = l?.probabilityToWin ?? 0;
    createdAt = l?.createdAt ?? DateTime.now();
    nextFollowUp = l?.nextFollowUp;
    lastContactDate = l?.lastContactDate;
    dateOfEnquiry = l?.dateOfEnquiry ?? DateTime.now();

    // Initialize districts based on selected state
    availableDistricts = IndiaLocationData.getDistricts(state);
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          children: [
            TextFormField(
                initialValue: name,
                decoration: const InputDecoration(labelText: 'Name'),
                onSaved: (v) => name = v ?? ''),
            TextFormField(
                initialValue: email,
                decoration: const InputDecoration(labelText: 'Email'),
                onSaved: (v) => email = v ?? ''),
            TextFormField(
                initialValue: phone,
                decoration: const InputDecoration(labelText: 'Phone'),
                onSaved: (v) => phone = v ?? ''),
            TextFormField(
                initialValue: customerType,
                decoration: const InputDecoration(labelText: 'Customer Type'),
                onSaved: (v) => customerType = v ?? ''),
            TextFormField(
                initialValue: projectType,
                decoration: const InputDecoration(labelText: 'Project Type'),
                onSaved: (v) => projectType = v ?? ''),
            TextFormField(
                initialValue: status,
                decoration: const InputDecoration(labelText: 'Status'),
                onSaved: (v) => status = v ?? 'New Inquiry'),
            TextFormField(
                initialValue: assignedTeam,
                decoration: const InputDecoration(labelText: 'Assigned Team'),
                onSaved: (v) => assignedTeam = v ?? ''),
            // Location fields
            DropdownButtonFormField<String>(
              value: state.isNotEmpty ? state : null,
              decoration: const InputDecoration(labelText: 'State'),
              items: IndiaLocationData.getStates()
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  state = value ?? '';
                  availableDistricts = IndiaLocationData.getDistricts(state);
                  district = ''; // Reset district when state changes
                });
              },
            ),
            DropdownButtonFormField<String>(
              value: district.isNotEmpty ? district : null,
              decoration: const InputDecoration(labelText: 'District'),
              items: availableDistricts
                  .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  district = value ?? '';
                });
              },
            ),
            TextFormField(
                initialValue: location,
                decoration: const InputDecoration(labelText: 'Location'),
                onSaved: (v) => location = v ?? ''),
            TextFormField(
                initialValue: projectDescription,
                decoration:
                    const InputDecoration(labelText: 'Project Description'),
                onSaved: (v) => projectDescription = v ?? ''),
            TextFormField(
                initialValue: requirements,
                decoration: const InputDecoration(labelText: 'Requirements'),
                onSaved: (v) => requirements = v ?? ''),
            TextFormField(
                initialValue: projectSqftArea?.toString() ?? '',
                decoration:
                    const InputDecoration(labelText: 'Project Sqft Area'),
                keyboardType: TextInputType.number,
                onSaved: (v) => projectSqftArea = double.tryParse(v ?? '')),
            // Date of Enquiry field
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: dateOfEnquiry ?? DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (picked != null) setState(() => dateOfEnquiry = picked);
              },
              child: InputDecorator(
                decoration: const InputDecoration(labelText: 'Date of Enquiry'),
                child: Text(
                  dateOfEnquiry?.toString().substring(0, 10) ?? 'Select Date',
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                _formKey.currentState?.save();
                widget.onSave(Lead(
                  leadId: widget.lead?.leadId ??
                      DateTime.now().millisecondsSinceEpoch.toString(),
                  name: name,
                  email: email,
                  phone: phone,
                  source: source,
                  createdAt: createdAt ?? DateTime.now(),
                  status: status,
                  notes: widget.lead?.notes,
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
                  state: state,
                  district: district,
                  location: location,
                  projectDescription: projectDescription,
                  requirements: requirements,
                  dateOfEnquiry: dateOfEnquiry ?? DateTime.now(),
                ));
              },
              child: Text(widget.lead == null ? 'Add Lead' : 'Save Changes'),
            ),
          ],
        ),
      ),
    );
  }
}
