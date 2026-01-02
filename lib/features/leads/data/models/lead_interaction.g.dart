// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lead_interaction.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LeadInteraction _$LeadInteractionFromJson(Map<String, dynamic> json) =>
    LeadInteraction(
      id: (json['id'] as num?)?.toInt(),
      leadId: (json['leadId'] as num).toInt(),
      interactionType: json['interactionType'] as String,
      interactionDate: DateTime.parse(json['interactionDate'] as String),
      durationMinutes: (json['durationMinutes'] as num?)?.toInt(),
      subject: json['subject'] as String?,
      notes: json['notes'] as String?,
      outcome: json['outcome'] as String?,
      nextAction: json['nextAction'] as String?,
      nextActionDate: json['nextActionDate'] == null
          ? null
          : DateTime.parse(json['nextActionDate'] as String),
      location: json['location'] as String?,
      metadata: json['metadata'] as String?,
    );

Map<String, dynamic> _$LeadInteractionToJson(LeadInteraction instance) =>
    <String, dynamic>{
      'id': instance.id,
      'leadId': instance.leadId,
      'interactionType': instance.interactionType,
      'interactionDate': instance.interactionDate.toIso8601String(),
      'durationMinutes': instance.durationMinutes,
      'subject': instance.subject,
      'notes': instance.notes,
      'outcome': instance.outcome,
      'nextAction': instance.nextAction,
      'nextActionDate': instance.nextActionDate?.toIso8601String(),
      'location': instance.location,
      'metadata': instance.metadata,
    };
