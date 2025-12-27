import 'package:intl/intl.dart';

/// Task status enum
enum TaskStatus {
  pending,
  inProgress,
  completed,
  cancelled;

  String get displayName {
    switch (this) {
      case TaskStatus.pending:
        return 'Pending';
      case TaskStatus.inProgress:
        return 'In Progress';
      case TaskStatus.completed:
        return 'Completed';
      case TaskStatus.cancelled:
        return 'Cancelled';
    }
  }

  static TaskStatus fromString(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return TaskStatus.pending;
      case 'IN_PROGRESS':
        return TaskStatus.inProgress;
      case 'COMPLETED':
        return TaskStatus.completed;
      case 'CANCELLED':
        return TaskStatus.cancelled;
      default:
        return TaskStatus.pending;
    }
  }

  String toApiString() {
    return toString().split('.').last.toUpperCase();
  }
}

/// Task priority enum
enum TaskPriority {
  low,
  medium,
  high,
  urgent;

  String get displayName {
    switch (this) {
      case TaskPriority.low:
        return 'Low';
      case TaskPriority.medium:
        return 'Medium';
      case TaskPriority.high:
        return 'High';
      case TaskPriority.urgent:
        return 'Urgent';
    }
  }

  static TaskPriority fromString(String priority) {
    switch (priority.toUpperCase()) {
      case 'LOW':
        return TaskPriority.low;
      case 'MEDIUM':
        return TaskPriority.medium;
      case 'HIGH':
        return TaskPriority.high;
      case 'URGENT':
        return TaskPriority.urgent;
      default:
        return TaskPriority.medium;
    }
  }

  String toApiString() {
    return toString().split('.').last.toUpperCase();
  }
}

/// Task model with RBAC permission flags
class TaskModel {
  final int id;
  final String title;
  final String description;
  final TaskStatus status;
  final TaskPriority priority;
  final DateTime? dueDate;
  final DateTime createdAt;
  final DateTime? updatedAt;

  // Creator info
  final int? createdById;
  final String? createdByName;

  // Assignment info
  final int? assignedToId;
  final String? assignedToName;

  // Project info
  final int? projectId;
  final String? projectName;

  // CRITICAL: Permission flags from backend
  final bool canEdit;
  final bool canDelete;
  final bool canView;

  TaskModel({
    required this.id,
    required this.title,
    this.description = '',
    required this.status,
    required this.priority,
    this.dueDate,
    required this.createdAt,
    this.updatedAt,
    this.createdById,
    this.createdByName,
    this.assignedToId,
    this.assignedToName,
    this.projectId,
    this.projectName,
    this.canEdit = false,
    this.canDelete = false,
    this.canView = true,
  });

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['id'],
      title: json['title'],
      description: json['description'] ?? '',
      status: TaskStatus.fromString(json['status']),
      priority: TaskPriority.fromString(json['priority']),
      dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate']) : null,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
      createdById: json['createdBy']?['id'],
      createdByName: json['createdBy'] != null
          ? '${json['createdBy']['firstName'] ?? ''} ${json['createdBy']['lastName'] ?? ''}'.trim()
          : null,
      assignedToId: json['assignedTo']?['id'],
      assignedToName: json['assignedTo'] != null
          ? '${json['assignedTo']['firstName'] ?? ''} ${json['assignedTo']['lastName'] ?? ''}'.trim()
          : null,
      projectId: json['project']?['id'],
      projectName: json['project']?['name'],
      canEdit: json['canEdit'] ?? false,
      canDelete: json['canDelete'] ?? false,
      canView: json['canView'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'status': status.toApiString(),
      'priority': priority.toApiString(),
      'dueDate': dueDate?.toIso8601String(),
      if (assignedToId != null) 'assignedTo': {'id': assignedToId},
      if (projectId != null) 'project': {'id': projectId},
    };
  }

  String get statusColor {
    switch (status) {
      case TaskStatus.pending:
        return '#FFA726'; // Orange
      case TaskStatus.inProgress:
        return '#42A5F5'; // Blue
      case TaskStatus.completed:
        return '#66BB6A'; // Green
      case TaskStatus.cancelled:
        return '#EF5350'; // Red
    }
  }

  String get priorityColor {
    switch (priority) {
      case TaskPriority.low:
        return '#9E9E9E'; // Grey
      case TaskPriority.medium:
        return '#FFA726'; // Orange
      case TaskPriority.high:
        return '#FF7043'; // Deep Orange
      case TaskPriority.urgent:
        return '#EF5350'; // Red
    }
  }

  String get dueDateFormatted {
    if (dueDate == null) return 'No due date';
    final now = DateTime.now();
    final difference = dueDate!.difference(now);

    if (difference.isNegative) {
      return 'Overdue by ${difference.inDays.abs()} days';
    } else if (difference.inDays == 0) {
      return 'Due today';
    } else if (difference.inDays == 1) {
      return 'Due tomorrow';
    } else if (difference.inDays < 7) {
      return 'Due in ${difference.inDays} days';
    } else {
      return DateFormat('MMM dd, yyyy').format(dueDate!);
    }
  }
}

/// Create Task Request DTO
class CreateTaskRequest {
  final String title;
  final String description;
  final String status;
  final String priority;
  final String? dueDate;
  final int? assignedToId;
  final int? projectId;

  CreateTaskRequest({
    required this.title,
    this.description = '',
    this.status = 'PENDING',
    this.priority = 'MEDIUM',
    this.dueDate,
    this.assignedToId,
    this.projectId,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'status': status,
      'priority': priority,
      if (dueDate != null) 'dueDate': dueDate,
      if (assignedToId != null) 'assignedTo': {'id': assignedToId},
      if (projectId != null) 'project': {'id': projectId},
    };
  }
}

/// Update Task Request DTO
class UpdateTaskRequest {
  final String? title;
  final String? description;
  final String? status;
  final String? priority;
  final String? dueDate;
  final int? assignedToId;
  final int? projectId;

  UpdateTaskRequest({
    this.title,
    this.description,
    this.status,
    this.priority,
    this.dueDate,
    this.assignedToId,
    this.projectId,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    if (title != null) data['title'] = title;
    if (description != null) data['description'] = description;
    if (status != null) data['status'] = status;
    if (priority != null) data['priority'] = priority;
    if (dueDate != null) data['dueDate'] = dueDate;
    if (assignedToId != null) data['assignedTo'] = {'id': assignedToId};
    if (projectId != null) data['project'] = {'id': projectId};
    return data;
  }
}

/// Task Assignment History Model
class TaskAssignmentHistoryModel {
  final int id;
  final int taskId;
  final int? assignedFromId;
  final String? assignedFromName;
  final int? assignedToId;
  final String? assignedToName;
  final int assignedById;
  final String assignedByName;
  final DateTime assignedAt;
  final String? notes;

  TaskAssignmentHistoryModel({
    required this.id,
    required this.taskId,
    this.assignedFromId,
    this.assignedFromName,
    this.assignedToId,
    this.assignedToName,
    required this.assignedById,
    required this.assignedByName,
    required this.assignedAt,
    this.notes,
  });

  factory TaskAssignmentHistoryModel.fromJson(Map<String, dynamic> json) {
    return TaskAssignmentHistoryModel(
      id: json['id'],
      taskId: json['taskId'],
      assignedFromId: json['assignedFrom']?['id'],
      assignedFromName: json['assignedFrom'] != null
          ? '${json['assignedFrom']['firstName'] ?? ''} ${json['assignedFrom']['lastName'] ?? ''}'.trim()
          : null,
      assignedToId: json['assignedTo']?['id'],
      assignedToName: json['assignedTo'] != null
          ? '${json['assignedTo']['firstName'] ?? ''} ${json['assignedTo']['lastName'] ?? ''}'.trim()
          : null,
      assignedById: json['assignedBy']['id'],
      assignedByName:
          '${json['assignedBy']['firstName'] ?? ''} ${json['assignedBy']['lastName'] ?? ''}'.trim(),
      assignedAt: DateTime.parse(json['assignedAt']),
      notes: json['notes'],
    );
  }

  String get changeDescription {
    final from = assignedFromName ?? 'Unassigned';
    final to = assignedToName ?? 'Unassigned';
    return '$from → $to';
  }
}
