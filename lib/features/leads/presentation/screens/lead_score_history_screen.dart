import 'package:flutter/material.dart';
import '../../data/models/lead.dart';
import 'components/lead_score_history_timeline.dart';

/**
 * Screen displaying lead score history
 * Shows complete audit trail of lead score changes over time
 */
class LeadScoreHistoryScreen extends StatelessWidget {
  final Lead lead;

  const LeadScoreHistoryScreen({super.key, required this.lead});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Score History: ${lead.name}'),
      ),
      body: LeadScoreHistoryTimeline(leadId: lead.leadId),
    );
  }
}
