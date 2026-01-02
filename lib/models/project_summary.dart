import 'package:admin/models/customer_project.dart';

class ProjectSummary {
  final CustomerProject project;
  final List<ProjectMemberDTO> teamMembers;
  final ProjectExecutionStats executionStats;
  final FinancialSnapshot financialSnapshot;
  final List<ActivityFeedDTO> recentActivities;

  ProjectSummary({
    required this.project,
    required this.teamMembers,
    required this.executionStats,
    required this.financialSnapshot,
    required this.recentActivities,
  });

  factory ProjectSummary.fromJson(Map<String, dynamic> json) {
    return ProjectSummary(
      project: CustomerProject.fromJson(json['project']),
      teamMembers: (json['teamMembers'] as List)
          .map((e) => ProjectMemberDTO.fromJson(e))
          .toList(),
      executionStats: ProjectExecutionStats.fromJson(json['executionStats']),
      financialSnapshot: FinancialSnapshot.fromJson(json['financialSnapshot']),
      recentActivities: (json['recentActivities'] as List)
          .map((e) => ActivityFeedDTO.fromJson(e))
          .toList(),
    );
  }
}

class ProjectMemberDTO {
  final int userId;
  final String? name; // Nullable as backend might just send ID
  final String role;
  final String? email;

  ProjectMemberDTO({
    required this.userId,
    this.name,
    required this.role,
    this.email,
  });

  factory ProjectMemberDTO.fromJson(Map<String, dynamic> json) {
    return ProjectMemberDTO(
      userId: json['userId'],
      name: json['name'],
      role: json['role'] ?? 'MEMBER',
      email: json['email'],
    );
  }
}

class ProjectExecutionStats {
  final int totalTasks;
  final int completedTasks;
  final int overdueTasks;
  final int activeDelays;

  ProjectExecutionStats({
    required this.totalTasks,
    required this.completedTasks,
    required this.overdueTasks,
    required this.activeDelays,
  });

  factory ProjectExecutionStats.fromJson(Map<String, dynamic> json) {
    return ProjectExecutionStats(
      totalTasks: json['totalTasks'] ?? 0,
      completedTasks: json['completedTasks'] ?? 0,
      overdueTasks: json['overdueTasks'] ?? 0,
      activeDelays: json['activeDelays'] ?? 0,
    );
  }
}

class FinancialSnapshot {
  final double totalBudget;
  final double totalInvoiced;
  final double totalPaid;
  final double pendingPayments;

  FinancialSnapshot({
    required this.totalBudget,
    required this.totalInvoiced,
    required this.totalPaid,
    required this.pendingPayments,
  });

  factory FinancialSnapshot.fromJson(Map<String, dynamic> json) {
    return FinancialSnapshot(
      totalBudget: (json['totalBudget'] ?? 0).toDouble(),
      totalInvoiced: (json['totalInvoiced'] ?? 0).toDouble(),
      totalPaid: (json['totalPaid'] ?? 0).toDouble(),
      pendingPayments: (json['pendingPayments'] ?? 0).toDouble(),
    );
  }
}

class ActivityFeedDTO {
  final int id;
  final String title;
  final String description;
  final String? createdByName;
  final DateTime createdAt;

  ActivityFeedDTO({
    required this.id,
    required this.title,
    required this.description,
    this.createdByName,
    required this.createdAt,
  });

  factory ActivityFeedDTO.fromJson(Map<String, dynamic> json) {
    return ActivityFeedDTO(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      createdByName: json['createdByName'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}
