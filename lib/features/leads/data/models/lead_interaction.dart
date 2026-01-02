
import 'package:json_annotation/json_annotation.dart';

part 'lead_interaction.g.dart';

@JsonSerializable()
class LeadInteraction {
  final int? id;
  final int leadId;
  final String interactionType; // CALL, EMAIL, MEETING, SITE_VISIT, WHATSAPP, OTHER
  final DateTime interactionDate;
  final int? durationMinutes;
  final String? subject;
  final String? notes;
  final String? outcome; // SCHEDULED_FOLLOWUP, QUOTE_SENT, NEEDS_INFO, NOT_INTERESTED, CONVERTED, OTHER
  final String? nextAction;
  final DateTime? nextActionDate;
  final String? location;
  final String? metadata;

  LeadInteraction({
    this.id,
    required this.leadId,
    required this.interactionType,
    required this.interactionDate,
    this.durationMinutes,
    this.subject,
    this.notes,
    this.outcome,
    this.nextAction,
    this.nextActionDate,
    this.location,
    this.metadata,
  });

  factory LeadInteraction.fromJson(Map<String, dynamic> json) => _$LeadInteractionFromJson(json);
  Map<String, dynamic> toJson() => _$LeadInteractionToJson(this);
}
