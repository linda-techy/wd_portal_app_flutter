import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/models/lead.dart';
import '../../data/services/lead_service.dart';
import 'lead_form.dart';
import 'lead_table.dart';

class LeadCRMPage extends StatefulWidget {
  const LeadCRMPage({super.key});

  @override
  State<LeadCRMPage> createState() => _LeadCRMPageState();
}

class _LeadCRMPageState extends State<LeadCRMPage> {
  List<Lead> leads = [];
  Lead? editingLead;

  void _addOrEditLead(Lead lead) {
    setState(() {
      if (editingLead != null) {
        final idx = leads.indexWhere((l) => l.leadId == lead.leadId);
        if (idx != -1) leads[idx] = lead;
        editingLead = null;
      } else {
        leads.add(lead);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Construction CRM - Lead Management')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: () {
                setState(() => editingLead = null);
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    content: SizedBox(
                      width: 500,
                      child: LeadForm(
                        onSave: (lead) {
                          Navigator.of(ctx).pop();
                          _addOrEditLead(lead);
                        },
                      ),
                    ),
                  ),
                );
              },
              child: const Text('Add New Lead'),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: LeadsTable(
                leads: leads,
                onEdit: (lead) {
                  setState(() => editingLead = lead);
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      content: SizedBox(
                        width: 500,
                        child: LeadForm(
                          lead: lead,
                          onSave: (updated) {
                            Navigator.of(ctx).pop();
                            _addOrEditLead(updated);
                          },
                        ),
                      ),
                    ),
                  );
                },
                onDelete: (lead) {
                   setState(() => leads.removeWhere((l) => l.leadId == lead.leadId));
                },
                onConvert: (lead) async {
                  // Capture ScaffoldMessenger before async gap
                  final scaffoldMessenger = ScaffoldMessenger.of(context);
                  
                  // Show conversion dialog
                  final result = await showDialog<Map<String, dynamic>>(
                    context: context,
                    builder: (ctx) => _LeadConversionDialog(lead: lead),
                  );
                  
                  if (result != null && mounted) {
                    try {
                      final leadService = LeadService();
                      await leadService.convertLead(
                        lead.leadId,
                        {
                          'projectName': result['projectName'] ?? '${lead.name} Project',
                          'startDate': result['startDate']?.toIso8601String().split('T')[0],
                          'location': result['location'] ?? lead.location ?? '',
                          'projectType': result['projectType'] ?? lead.projectType,
                        },
                      );
                      
                      if (mounted) {
                        scaffoldMessenger.showSnackBar(
                          const SnackBar(
                            content: Text('Lead converted to project successfully'),
                            backgroundColor: Colors.green,
                          ),
                        );
                        // Remove lead from list after conversion
                        setState(() => leads.removeWhere((l) => l.leadId == lead.leadId));
                      }
                    } catch (e) {
                      if (mounted) {
                        scaffoldMessenger.showSnackBar(
                          SnackBar(
                            content: Text('Conversion failed: ${e.toString()}'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LeadConversionDialog extends StatefulWidget {
  final Lead lead;

  const _LeadConversionDialog({required this.lead});

  @override
  State<_LeadConversionDialog> createState() => _LeadConversionDialogState();
}

class _LeadConversionDialogState extends State<_LeadConversionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _projectNameController = TextEditingController();
  final _locationController = TextEditingController();
  DateTime? _startDate;
  String? _projectType;

  @override
  void initState() {
    super.initState();
    _projectNameController.text = '${widget.lead.name} Project';
    _locationController.text = widget.lead.location;
    _projectType = widget.lead.projectType;
    _startDate = DateTime.now();
  }

  @override
  void dispose() {
    _projectNameController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Convert Lead to Project'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Converting: ${widget.lead.name}'),
              const SizedBox(height: 16),
              TextFormField(
                controller: _projectNameController,
                decoration: const InputDecoration(
                  labelText: 'Project Name *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Project name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Location',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _projectType,
                decoration: const InputDecoration(
                  labelText: 'Project Type',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'RESIDENTIAL', child: Text('Residential')),
                  DropdownMenuItem(value: 'COMMERCIAL', child: Text('Commercial')),
                  DropdownMenuItem(value: 'INDUSTRIAL', child: Text('Industrial')),
                  DropdownMenuItem(value: 'MIXED_USE', child: Text('Mixed Use')),
                ],
                onChanged: (value) {
                  setState(() => _projectType = value);
                },
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _startDate ?? DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
                  );
                  if (date != null) {
                    setState(() => _startDate = date);
                  }
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Start Date *',
                    border: OutlineInputBorder(),
                  ),
                  child: Text(
                    _startDate != null
                        ? DateFormat.yMMMd().format(_startDate!)
                        : 'Select date',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.of(context).pop({
                'projectName': _projectNameController.text.trim(),
                'location': _locationController.text.trim(),
                'projectType': _projectType,
                'startDate': _startDate,
              });
            }
          },
          child: const Text('Convert'),
        ),
      ],
    );
  }
}
