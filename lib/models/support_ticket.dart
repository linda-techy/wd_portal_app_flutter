class PortalSupportTicket {
  final int id;
  final String ticketNumber;
  final String subject;
  final String? description;
  final String category;
  final String priority;
  final String status;
  final int? customerUserId;
  final String? customerName;
  final String? customerEmail;
  final int? projectId;
  final String? projectName;
  final int? assignedTo;
  final String? assignedToName;
  final String createdAt;
  final String updatedAt;
  final List<PortalTicketReply> replies;

  const PortalSupportTicket({
    required this.id,
    required this.ticketNumber,
    required this.subject,
    this.description,
    required this.category,
    required this.priority,
    required this.status,
    this.customerUserId,
    this.customerName,
    this.customerEmail,
    this.projectId,
    this.projectName,
    this.assignedTo,
    this.assignedToName,
    required this.createdAt,
    required this.updatedAt,
    this.replies = const [],
  });

  factory PortalSupportTicket.fromJson(Map<String, dynamic> json) {
    final repliesJson = json['replies'] as List<dynamic>? ?? [];
    return PortalSupportTicket(
      id: json['id'] as int,
      ticketNumber: json['ticketNumber'] as String? ?? '',
      subject: json['subject'] as String? ?? '',
      description: json['description'] as String?,
      category: json['category'] as String? ?? 'GENERAL',
      priority: json['priority'] as String? ?? 'MEDIUM',
      status: json['status'] as String? ?? 'OPEN',
      customerUserId: json['customerUserId'] as int?,
      customerName: json['customerName'] as String?,
      customerEmail: json['customerEmail'] as String?,
      projectId: json['projectId'] as int?,
      projectName: json['projectName'] as String?,
      assignedTo: json['assignedTo'] as int?,
      assignedToName: json['assignedToName'] as String?,
      createdAt: json['createdAt'] as String? ?? '',
      updatedAt: json['updatedAt'] as String? ?? '',
      replies: repliesJson
          .map((r) => PortalTicketReply.fromJson(r as Map<String, dynamic>))
          .toList(),
    );
  }
}

class PortalTicketReply {
  final int id;
  final int userId;
  final String userType;
  final String? userName;
  final String message;
  final String? attachmentUrl;
  final String createdAt;

  const PortalTicketReply({
    required this.id,
    required this.userId,
    required this.userType,
    this.userName,
    required this.message,
    this.attachmentUrl,
    required this.createdAt,
  });

  bool get isStaff => userType == 'STAFF';

  factory PortalTicketReply.fromJson(Map<String, dynamic> json) {
    return PortalTicketReply(
      id: json['id'] as int,
      userId: json['userId'] as int? ?? 0,
      userType: json['userType'] as String? ?? 'CUSTOMER',
      userName: json['userName'] as String?,
      message: json['message'] as String? ?? '',
      attachmentUrl: json['attachmentUrl'] as String?,
      createdAt: json['createdAt'] as String? ?? '',
    );
  }
}
