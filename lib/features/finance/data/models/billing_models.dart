class ProjectMilestone {
  final int? id;
  final int projectId;
  final String name;
  final String? description;
  final double? milestonePercentage;
  final double amount;
  final String status;
  final DateTime? dueDate;
  final DateTime? completedDate;
  final int? invoiceId;

  ProjectMilestone({
    this.id,
    required this.projectId,
    required this.name,
    this.description,
    this.milestonePercentage,
    required this.amount,
    this.status = 'PENDING',
    this.dueDate,
    this.completedDate,
    this.invoiceId,
  });

  factory ProjectMilestone.fromJson(Map<String, dynamic> json) {
    return ProjectMilestone(
      id: json['id'],
      projectId: json['project'] != null ? json['project']['id'] : json['projectId'], 
      name: json['name'],
      description: json['description'],
      milestonePercentage: json['milestonePercentage']?.toDouble(),
      amount: json['amount']?.toDouble() ?? 0.0,
      status: json['status'] ?? 'PENDING',
      dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate']) : null,
      completedDate: json['completedDate'] != null ? DateTime.parse(json['completedDate']) : null,
      invoiceId: json['invoice'] != null ? json['invoice']['id'] : json['invoiceId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'project': {'id': projectId}, // Send as object for backend
      'name': name,
      'description': description,
      'milestonePercentage': milestonePercentage,
      'amount': amount,
      'status': status,
      'dueDate': dueDate?.toIso8601String().split('T').first,
      'completedDate': completedDate?.toIso8601String().split('T').first,
      'invoiceId': invoiceId,
    };
  }
}

class Receipt {
  final int? id;
  final int projectId;
  final int? invoiceId;
  final String receiptNumber;
  final double amount;
  final DateTime paymentDate;
  final String? paymentMethod;
  final String? transactionReference;
  final String? notes;

  Receipt({
    this.id,
    required this.projectId,
    this.invoiceId,
    required this.receiptNumber,
    required this.amount,
    required this.paymentDate,
    this.paymentMethod,
    this.transactionReference,
    this.notes,
  });

  factory Receipt.fromJson(Map<String, dynamic> json) {
    return Receipt(
      id: json['id'],
      projectId: json['project'] != null ? json['project']['id'] : json['projectId'],
      invoiceId: json['invoice'] != null ? json['invoice']['id'] : json['invoiceId'],
      receiptNumber: json['receiptNumber'],
      amount: json['amount']?.toDouble() ?? 0.0,
      paymentDate: DateTime.parse(json['paymentDate']),
      paymentMethod: json['paymentMethod'],
      transactionReference: json['transactionReference'],
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'project': {'id': projectId},
      'invoice': invoiceId != null ? {'id': invoiceId} : null,
      'receiptNumber': receiptNumber,
      'amount': amount,
      'paymentDate': paymentDate.toIso8601String().split('T').first,
      'paymentMethod': paymentMethod,
      'transactionReference': transactionReference,
      'notes': notes,
    };
  }
}
