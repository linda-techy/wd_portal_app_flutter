import 'package:flutter/material.dart';
import '../../models/lead.dart';
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
              child: LeadTable(
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}
