class Task {
  final int? id;
  final String title;
  final String? description;
  final String status; // PENDING, IN_PROGRESS, COMPLETED, CANCELLED
  final String priority; // LOW, MEDIUM, HIGH, URGENT
  final int? assignedToId;
  final String? assignedToName;
  final int? createdById;
  final String? createdByName;
  final int? leadId;
  final String? leadName;
  final int? projectId;
  final String? projectName;
  final DateTime? dueDate;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Task({
    this.id,
    required this.title,
    this.description,
    this.status = 'PENDING',
    this.priority = 'MEDIUM',
    this.assignedToId,
    this.assignedToName,
    this.createdById,
    this.createdByName,
    this.projectId,
    this.projectName,
    this.leadId,
    this.leadName,
    this.dueDate,
    this.createdAt,
    this.updatedAt,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? ''),
      title: json['title'] ?? '',
      description: json['description'],
      status: json['status'] ?? 'PENDING',
      priority: json['priority'] ?? 'MEDIUM',
      assignedToId: json['assignedTo']?['id'] is int
          ? json['assignedTo']['id']
          : json['assigned_to_id'] is int
              ? json['assigned_to_id']
              : int.tryParse(json['assignedTo']?['id']?.toString() ?? json['assigned_to_id']?.toString() ?? ''),
      assignedToName: json['assignedTo']?['firstName'] != null
          ? '${json['assignedTo']['firstName']} ${json['assignedTo']['lastName']}'
          : json['assigned_to_name'],
      createdById: json['createdBy']?['id'] is int
          ? json['createdBy']['id']
          : json['created_by_id'] is int
              ? json['created_by_id']
              : int.tryParse(json['createdBy']?['id']?.toString() ?? json['created_by_id']?.toString() ?? ''),
      createdByName: json['createdBy']?['firstName'] != null
          ? '${json['createdBy']['firstName']} ${json['createdBy']['lastName']}'
          : json['created_by_name'],
      projectId: json['project']?['id'] is int
          ? json['project']['id']
          : json['project_id'] is int
              ? json['project_id']
              : int.tryParse(json['project']?['id']?.toString() ?? json['project_id']?.toString() ?? ''),
      projectName: json['project']?['projectName'] ?? json['project_name'],
      leadId: json['lead']?['id'] is int
          ? json['lead']['id']
          : json['lead_id'] is int
              ? json['lead_id']
              : int.tryParse(json['lead']?['id']?.toString() ?? json['lead_id']?.toString() ?? ''),
      leadName: json['lead']?['name'] ?? json['lead_name'],
      dueDate: json['due_date'] != null || json['dueDate'] != null
          ? DateTime.tryParse(json['due_date'] ?? json['dueDate'] ?? '')
          : null,
      createdAt: json['created_at'] != null || json['createdAt'] != null
          ? DateTime.tryParse(json['created_at'] ?? json['createdAt'] ?? '')
          : null,
      updatedAt: json['updated_at'] != null || json['updatedAt'] != null
          ? DateTime.tryParse(json['updated_at'] ?? json['updatedAt'] ?? '')
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'description': description,
      'status': status,
      'priority': priority,
      if (assignedToId != null) 'assignedTo': {'id': assignedToId},
      if (projectId != null) 'project': {'id': projectId},
      if (leadId != null) 'lead': {'id': leadId},
      if (dueDate != null) 'dueDate': dueDate!.toIso8601String().split('T')[0],
    };
  }

  Task copyWith({
    int? id,
    String? title,
    String? description,
    String? status,
    String? priority,
    int? assignedToId,
    String? assignedToName,
    int? createdById,
    String? createdByName,
    int? projectId,
    String? projectName,
    int? leadId,
    String? leadName,
    DateTime? dueDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      assignedToId: assignedToId ?? this.assignedToId,
      assignedToName: assignedToName ?? this.assignedToName,
      createdById: createdById ?? this.createdById,
      createdByName: createdByName ?? this.createdByName,
      projectId: projectId ?? this.projectId,
      projectName: projectName ?? this.projectName,
      leadId: leadId ?? this.leadId,
      leadName: leadName ?? this.leadName,
      dueDate: dueDate ?? this.dueDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
