
import 'package:flutter/material.dart';
import 'package:admin/utils/error_handler.dart';
import '../../../data/models/lead_interaction.dart';
import '../../../data/services/lead_service.dart';
import 'package:intl/intl.dart';

class AddInteractionDialog extends StatefulWidget {
  final int leadId;
  final VoidCallback onSave;

  const AddInteractionDialog({
    super.key,
    required this.leadId,
    required this.onSave,
  });

  @override
  State<AddInteractionDialog> createState() => _AddInteractionDialogState();
}

class _AddInteractionDialogState extends State<AddInteractionDialog> {
  final _formKey = GlobalKey<FormState>();
  final LeadService _leadService = LeadService();

  String _interactionType = 'CALL';
  DateTime _interactionDate = DateTime.now();
  TimeOfDay _interactionTime = TimeOfDay.now();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _subjectController = TextEditingController();
  String _outcome = 'SCHEDULED_FOLLOWUP';

  bool _isLoading = false;

  final List<String> _types = [
    'CALL',
    'EMAIL',
    'MEETING',
    'SITE_VISIT',
    'WHATSAPP',
    'OTHER'
  ];

  final List<String> _outcomes = [
    'SCHEDULED_FOLLOWUP',
    'QUOTE_SENT',
    'NEEDS_INFO',
    'NOT_INTERESTED',
    'CONVERTED',
    'COLD_LEAD',
    'HOT_LEAD'
  ];

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _interactionDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _interactionDate) {
      setState(() {
        _interactionDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _interactionTime,
    );
    if (picked != null && picked != _interactionTime) {
      setState(() {
        _interactionTime = picked;
      });
    }
  }

  Future<void> _saveInteraction() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final dateTime = DateTime(
        _interactionDate.year,
        _interactionDate.month,
        _interactionDate.day,
        _interactionTime.hour,
        _interactionTime.minute,
      );

      final interaction = LeadInteraction(
        leadId: widget.leadId,
        interactionType: _interactionType,
        interactionDate: dateTime,
        notes: _notesController.text,
        subject: _subjectController.text.isNotEmpty ? _subjectController.text : 'Logged $_interactionType',
        outcome: _outcome,
      );

      await _leadService.createInteraction(interaction);
      widget.onSave();
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ErrorHandler.showErrorSnackBar(context, e);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Log Activity / Site Visit'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: _interactionType,
                decoration: const InputDecoration(labelText: 'Type'),
                items: _types.map((String type) {
                  return DropdownMenuItem<String>(
                    value: type,
                    child: Text(type.replaceAll('_', ' ')),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _interactionType = newValue!;
                  });
                },
              ),
              const SizedBox(height: 16),
              if (_interactionType == 'SITE_VISIT' || _interactionType == 'MEETING') ...[
                 TextFormField(
                  controller: _locationController,
                  decoration: const InputDecoration(
                    labelText: 'Location',
                    hintText: 'e.g. 123 Main St, Site Office',
                  ),
                  validator: (value) {
                    if ((_interactionType == 'SITE_VISIT' || _interactionType == 'MEETING') && (value == null || value.isEmpty)) {
                      return 'Please enter location';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
              ],
              TextFormField(
                controller: _subjectController,
                decoration: const InputDecoration(labelText: 'Subject'),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectDate(context),
                      child: InputDecorator(
                        decoration: const InputDecoration(labelText: 'Date'),
                        child: Text(DateFormat('MMM d, y').format(_interactionDate)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectTime(context),
                      child: InputDecorator(
                        decoration: const InputDecoration(labelText: 'Time'),
                        child: Text(_interactionTime.format(context)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _outcome,
                decoration: const InputDecoration(labelText: 'Outcome'),
                items: _outcomes.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value.replaceAll('_', ' ')),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _outcome = newValue!;
                  });
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(labelText: 'Notes'),
                maxLines: 3,
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
          onPressed: _isLoading ? null : _saveInteraction,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }
}
