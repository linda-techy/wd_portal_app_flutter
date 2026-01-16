
import 'package:json_annotation/json_annotation.dart';

part 'lead_interaction.g.dart';

@JsonSerializable()
class LeadInteraction {
  final int? id;
  @JsonKey(name: 'leadId')
  final int leadId;
  @JsonKey(name: 'interactionType')
  final String interactionType; // CALL, EMAIL, MEETING, SITE_VISIT, WHATSAPP, OTHER
  @JsonKey(name: 'interactionDate')
  final DateTime interactionDate;
  @JsonKey(name: 'durationMinutes')
  final int? durationMinutes;
  final String? subject;
  final String? notes;
  final String? outcome; // SCHEDULED_FOLLOWUP, QUOTE_SENT, NEEDS_INFO, NOT_INTERESTED, CONVERTED, OTHER
  @JsonKey(name: 'nextAction')
  final String? nextAction;
  @JsonKey(name: 'nextActionDate')
  final DateTime? nextActionDate;
  @JsonKey(name: 'createdById')
  final int? createdById;
  @JsonKey(name: 'createdAt')
  final DateTime? createdAt;

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
    this.createdById,
    this.createdAt,
  });

  factory LeadInteraction.fromJson(Map<String, dynamic> json) => _$LeadInteractionFromJson(json);
  Map<String, dynamic> toJson() => _$LeadInteractionToJson(this);
}
