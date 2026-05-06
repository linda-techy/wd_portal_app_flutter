class PendingApprovalRow {
  final int taskId;
  final String taskTitle;
  final int projectId;
  final String projectName;
  final DateTime? markedCompleteOn;
  final String? completionPhotoUrl;

  const PendingApprovalRow({
    required this.taskId,
    required this.taskTitle,
    required this.projectId,
    required this.projectName,
    this.markedCompleteOn,
    this.completionPhotoUrl,
  });

  factory PendingApprovalRow.fromJson(Map<String, dynamic> json) {
    return PendingApprovalRow(
      taskId: json['taskId'] as int,
      taskTitle: json['taskTitle'] as String,
      projectId: json['projectId'] as int,
      projectName: json['projectName'] as String,
      markedCompleteOn: json['markedCompleteOn'] != null
          ? DateTime.parse(json['markedCompleteOn'] as String)
          : null,
      completionPhotoUrl: json['completionPhotoUrl'] as String?,
    );
  }
}
