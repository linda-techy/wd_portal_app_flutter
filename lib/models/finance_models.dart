class ProjectInvoice {
  final int? id;
  final int projectId;
  final String? projectName;
  final String? invoiceNumber;
  final String invoiceDate;
  final String? dueDate;
  final double subTotal;
  final double gstPercentage;
  final double gstAmount;
  final double totalAmount;
  final String status;
  final String? notes;

  ProjectInvoice({
    this.id,
    required this.projectId,
    this.projectName,
    this.invoiceNumber,
    required this.invoiceDate,
    this.dueDate,
    required this.subTotal,
    this.gstPercentage = 18.0,
    required this.gstAmount,
    required this.totalAmount,
    this.status = 'DRAFT',
    this.notes,
  });

  factory ProjectInvoice.fromJson(Map<String, dynamic> json) {
    return ProjectInvoice(
      id: json['id'],
      projectId: json['projectId'],
      projectName: json['projectName'],
      invoiceNumber: json['invoiceNumber'],
      invoiceDate: json['invoiceDate'],
      dueDate: json['dueDate'],
      subTotal: (json['subTotal'] as num).toDouble(),
      gstPercentage: (json['gstPercentage'] as num).toDouble(),
      gstAmount: (json['gstAmount'] as num).toDouble(),
      totalAmount: (json['totalAmount'] as num).toDouble(),
      status: json['status'],
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'projectId': projectId,
      'invoiceDate': invoiceDate,
      if (dueDate != null) 'dueDate': dueDate,
      'subTotal': subTotal,
      'gstPercentage': gstPercentage,
      'notes': notes,
    };
  }
}

class PurchaseInvoice {
  final int? id;
  final int vendorId;
  final String? vendorName;
  final int projectId;
  final String? projectName;
  final int? poId;
  final int? grnId;
  final String vendorInvoiceNumber;
  final String invoiceDate;
  final double amount;
  final String status;

  PurchaseInvoice({
    this.id,
    required this.vendorId,
    this.vendorName,
    required this.projectId,
    this.projectName,
    this.poId,
    this.grnId,
    required this.vendorInvoiceNumber,
    required this.invoiceDate,
    required this.amount,
    this.status = 'PENDING',
  });

  factory PurchaseInvoice.fromJson(Map<String, dynamic> json) {
    return PurchaseInvoice(
      id: json['id'],
      vendorId: json['vendorId'],
      vendorName: json['vendorName'],
      projectId: json['projectId'],
      projectName: json['projectName'],
      poId: json['poId'],
      grnId: json['grnId'],
      vendorInvoiceNumber: json['vendorInvoiceNumber'],
      invoiceDate: json['invoiceDate'],
      amount: (json['amount'] as num).toDouble(),
      status: json['status'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'vendorId': vendorId,
      'projectId': projectId,
      if (poId != null) 'poId': poId,
      if (grnId != null) 'grnId': grnId,
      'vendorInvoiceNumber': vendorInvoiceNumber,
      'invoiceDate': invoiceDate,
      'amount': amount,
    };
  }
}

class LabourPayment {
  final int? id;
  final int labourId;
  final String? labourName;
  final int projectId;
  final String? projectName;
  final int? mbEntryId;
  final double amount;
  final String paymentDate;
  final String? paymentMethod;
  final String? notes;

  LabourPayment({
    this.id,
    required this.labourId,
    this.labourName,
    required this.projectId,
    this.projectName,
    this.mbEntryId,
    required this.amount,
    required this.paymentDate,
    this.paymentMethod,
    this.notes,
  });

  factory LabourPayment.fromJson(Map<String, dynamic> json) {
    return LabourPayment(
      id: json['id'],
      labourId: json['labourId'],
      labourName: json['labourName'],
      projectId: json['projectId'],
      projectName: json['projectName'],
      mbEntryId: json['mbEntryId'],
      amount: (json['amount'] as num).toDouble(),
      paymentDate: json['paymentDate'],
      paymentMethod: json['paymentMethod'],
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'labourId': labourId,
      'projectId': projectId,
      if (mbEntryId != null) 'mbEntryId': mbEntryId,
      'amount': amount,
      'paymentDate': paymentDate,
      'paymentMethod': paymentMethod,
      'notes': notes,
    };
  }
}
