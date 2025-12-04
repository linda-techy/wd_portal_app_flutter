import 'team_member.dart';

class CustomerProject {
  final int? id;
  final String name;
  final String location;
  final DateTime? startDate;
  final DateTime? endDate;
  final double? progress; // 0.0 to 100.0
  final String? createdBy;
  final String? projectPhase;
  final String? state;
  final String? district;
  final double? sqfeet;
  final int? leadId;
  final String? code;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<TeamMember>? teamMembers;
  final List<int>? teamMemberIds;

  CustomerProject({
    this.id,
    required this.name,
    required this.location,
    this.startDate,
    this.endDate,
    this.progress,
    this.createdBy,
    this.projectPhase,
    this.state,
    this.district,
    this.sqfeet,
    this.leadId,
    this.code,
    this.createdAt,
    this.updatedAt,
    this.teamMembers,
    this.teamMemberIds,
  });

  factory CustomerProject.fromJson(Map<String, dynamic> json) {
    return CustomerProject(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id']?.toString() ?? ''),
      name: json['name'] ?? '',
      location: json['location'] ?? '',
      startDate: json['start_date'] != null
          ? DateTime.tryParse(json['start_date'])
          : json['startDate'] != null
              ? DateTime.tryParse(json['startDate'])
              : null,
      endDate: json['end_date'] != null
          ? DateTime.tryParse(json['end_date'])
          : json['endDate'] != null
              ? DateTime.tryParse(json['endDate'])
              : null,
      progress: json['progress'] != null
          ? (json['progress'] is double
              ? json['progress']
              : double.tryParse(json['progress'].toString()))
          : null,
      createdBy: json['created_by'] ?? json['createdBy'],
      projectPhase: json['project_phase'] ?? json['projectPhase'],
      state: json['state'],
      district: json['district'],
      sqfeet: json['sqfeet'] != null
          ? (json['sqfeet'] is double
              ? json['sqfeet']
              : double.tryParse(json['sqfeet'].toString()))
          : null,
      leadId: json['lead_id'] is int
          ? json['lead_id']
          : json['leadId'] is int
              ? json['leadId']
              : int.tryParse(json['lead_id']?.toString() ??
                  json['leadId']?.toString() ??
                  ''),
      code: json['code'],
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : json['createdAt'] != null
              ? DateTime.tryParse(json['createdAt'])
              : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'])
          : json['updatedAt'] != null
              ? DateTime.tryParse(json['updatedAt'])
              : null,
      teamMembers: json['team_members'] != null
          ? (json['team_members'] as List)
              .map((i) => TeamMember.fromJson(i))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'location': location,
      if (startDate != null)
        'start_date': startDate!.toIso8601String().split('T')[0],
      if (endDate != null) 'end_date': endDate!.toIso8601String().split('T')[0],
      if (progress != null) 'progress': progress,
      if (createdBy != null && createdBy!.isNotEmpty) 'created_by': createdBy,
      if (projectPhase != null && projectPhase!.isNotEmpty)
        'project_phase': projectPhase,
      if (state != null && state!.isNotEmpty) 'state': state,
      if (district != null && district!.isNotEmpty) 'district': district,
      if (sqfeet != null) 'sqfeet': sqfeet,
      if (leadId != null) 'lead_id': leadId,
      if (code != null && code!.isNotEmpty) 'code': code,
      if (teamMembers != null)
        'team_members': teamMembers!
            .map((m) => {
                  'id': int.tryParse(m.id ?? ''),
                  'type': m.type,
                })
            .where((m) => m['id'] != null && m['type'] != null)
            .toList(),
    };
  }

  Map<String, dynamic> toCreateJson() {
    return toJson();
  }

  Map<String, dynamic> toUpdateJson() {
    return toJson();
  }

  CustomerProject copyWith({
    int? id,
    String? name,
    String? location,
    DateTime? startDate,
    DateTime? endDate,
    double? progress,
    String? createdBy,
    String? projectPhase,
    String? state,
    String? district,
    double? sqfeet,
    int? leadId,
    String? code,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<TeamMember>? teamMembers,
    List<int>? teamMemberIds,
  }) {
    return CustomerProject(
      id: id ?? this.id,
      name: name ?? this.name,
      location: location ?? this.location,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      progress: progress ?? this.progress,
      createdBy: createdBy ?? this.createdBy,
      projectPhase: projectPhase ?? this.projectPhase,
      state: state ?? this.state,
      district: district ?? this.district,
      sqfeet: sqfeet ?? this.sqfeet,
      leadId: leadId ?? this.leadId,
      code: code ?? this.code,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      teamMembers: teamMembers ?? this.teamMembers,
      teamMemberIds: teamMemberIds ?? this.teamMemberIds,
    );
  }
}
