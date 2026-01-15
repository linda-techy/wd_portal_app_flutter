import 'package:flutter/material.dart';
import '../../data/models/lead.dart';
import 'components/lead_activity_timeline.dart';

class LeadActivityScreen extends StatelessWidget {
  final Lead lead;

  const LeadActivityScreen({super.key, required this.lead});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Activity: ${lead.name}'),
      ),
      body: LeadActivityTimeline(leadId: lead.leadId),
    );
  }
}

