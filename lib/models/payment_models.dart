/// Models for payment-related data
class DesignPackagePayment {
  final int id;
  final int projectId;
  final String? projectName;
  final String? customerName;
  final String packageName;
  final double ratePerSqft;
  final double totalSqft;
  final double baseAmount;
  final double gstPercentage;
  final double gstAmount;
  final double discountPercentage;
  final double discountAmount;
  final double totalAmount;
  final String paymentType; // 'FULL' or 'INSTALLMENT'
  final String status; // 'PENDING', 'PARTIAL', 'PAID'
  final double totalPaid;
  final double balanceDue;
  final DateTime createdAt;
  final List<PaymentScheduleItem> schedules;

  DesignPackagePayment({
    required this.id,
    required this.projectId,
    this.projectName,
    this.customerName,
    required this.packageName,
    required this.ratePerSqft,
    required this.totalSqft,
    required this.baseAmount,
    required this.gstPercentage,
    required this.gstAmount,
    required this.discountPercentage,
    required this.discountAmount,
    required this.totalAmount,
    required this.paymentType,
    required this.status,
    required this.totalPaid,
    required this.balanceDue,
    required this.createdAt,
    required this.schedules,
  });

  factory DesignPackagePayment.fromJson(Map<String, dynamic> json) {
    return DesignPackagePayment(
      id: json['id'] ?? 0,
      projectId: json['projectId'] ?? 0,
      projectName: json['projectName'],
      customerName: json['customerName'],
      packageName: json['packageName'] ?? '',
      ratePerSqft: (json['ratePerSqft'] ?? 0).toDouble(),
      totalSqft: (json['totalSqft'] ?? 0).toDouble(),
      baseAmount: (json['baseAmount'] ?? 0).toDouble(),
      gstPercentage: (json['gstPercentage'] ?? 18).toDouble(),
      gstAmount: (json['gstAmount'] ?? 0).toDouble(),
      discountPercentage: (json['discountPercentage'] ?? 0).toDouble(),
      discountAmount: (json['discountAmount'] ?? 0).toDouble(),
      totalAmount: (json['totalAmount'] ?? 0).toDouble(),
      paymentType: json['paymentType'] ?? 'FULL',
      status: json['status'] ?? 'PENDING',
      totalPaid: (json['totalPaid'] ?? 0).toDouble(),
      balanceDue: (json['balanceDue'] ?? 0).toDouble(),
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
      schedules: (json['schedules'] as List<dynamic>?)
              ?.map((s) => PaymentScheduleItem.fromJson(s))
              .toList() ??
          [],
    );
  }
}

class PaymentScheduleItem {
  final int id;
  final int installmentNumber;
  final String description;
  final double amount;
  final DateTime? dueDate;
  final String status; // 'PENDING', 'PAID', 'OVERDUE'
  final double paidAmount;
  final DateTime? paidDate;
  final List<PaymentTransactionItem> transactions;

  PaymentScheduleItem({
    required this.id,
    required this.installmentNumber,
    required this.description,
    required this.amount,
    this.dueDate,
    required this.status,
    required this.paidAmount,
    this.paidDate,
    required this.transactions,
  });

  factory PaymentScheduleItem.fromJson(Map<String, dynamic> json) {
    return PaymentScheduleItem(
      id: json['id'] ?? 0,
      installmentNumber: json['installmentNumber'] ?? 1,
      description: json['description'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate']) : null,
      status: json['status'] ?? 'PENDING',
      paidAmount: (json['paidAmount'] ?? 0).toDouble(),
      paidDate: json['paidDate'] != null ? DateTime.parse(json['paidDate']) : null,
      transactions: (json['transactions'] as List<dynamic>?)
              ?.map((t) => PaymentTransactionItem.fromJson(t))
              .toList() ??
          [],
    );
  }

  bool get isPaid => status == 'PAID';
  double get remainingAmount => amount - paidAmount;
}

class PaymentTransactionItem {
  final int id;
  final String? projectName;
  final String? customerName;
  final double amount;
  final String? paymentMethod;
  final String? referenceNumber;
  final DateTime paymentDate;
  final String? notes;
  final int? recordedById;
  final String? receiptNumber;
  final String? status;
  final double tdsPercentage;      // NEW: TDS rate (0-100)
  final double tdsAmount;          // NEW: Calculated TDS deduction
  final double netAmount;          // NEW: Amount after TDS
  final String tdsDeductedBy;      // NEW: Who deducted TDS
  final String paymentCategory;    // NEW: Payment type
  final int? challanId;            // NEW: Linked challan ID
  final String? challanNumber;     // NEW: Linked challan number
  final DateTime createdAt;

  PaymentTransactionItem({
    required this.id,
    this.projectName,
    this.customerName,
    required this.amount,
    this.paymentMethod,
    this.referenceNumber,
    required this.paymentDate,
    this.notes,
    this.recordedById,
    this.receiptNumber,
    this.status,
    this.tdsPercentage = 0.0,
    this.tdsAmount = 0.0,
    required this.netAmount,
    this.tdsDeductedBy = 'CUSTOMER',
    this.paymentCategory = 'PROGRESS',
    this.challanId,
    this.challanNumber,
    required this.createdAt,
  });

  factory PaymentTransactionItem.fromJson(Map<String, dynamic> json) {
    return PaymentTransactionItem(
      id: json['id'] ?? 0,
      projectName: json['projectName'],
      customerName: json['customerName'],
      amount: (json['amount'] ?? 0).toDouble(),
      paymentMethod: json['paymentMethod'],
      referenceNumber: json['referenceNumber'],
      paymentDate: json['paymentDate'] != null 
          ? DateTime.parse(json['paymentDate']) 
          : DateTime.now(),
      notes: json['notes'],
      recordedById: json['recordedById'],
      receiptNumber: json['receiptNumber'],
      status: json['status'],
      tdsPercentage: (json['tdsPercentage'] ?? 0).toDouble(),
      tdsAmount: (json['tdsAmount'] ?? 0).toDouble(),
      netAmount: (json['netAmount'] ?? json['amount'] ?? 0).toDouble(),
      tdsDeductedBy: json['tdsDeductedBy'] ?? 'CUSTOMER',
      paymentCategory: json['paymentCategory'] ?? 'PROGRESS',
      challanId: json['challanId'],
      challanNumber: json['challanNumber'],
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
    );
  }
}

class ChallanItem {
  final int id;
  final int transactionId;
  final String challanNumber;
  final String fy;
  final DateTime transactionDate;
  final double amount;
  final String clientName;
  final String projectName;
  final String status;
  final DateTime generatedAt;

  ChallanItem({
    required this.id,
    required this.transactionId,
    required this.challanNumber,
    required this.fy,
    required this.transactionDate,
    required this.amount,
    required this.clientName,
    required this.projectName,
    required this.status,
    required this.generatedAt,
  });

  factory ChallanItem.fromJson(Map<String, dynamic> json) {
    return ChallanItem(
      id: json['id'] ?? 0,
      transactionId: json['transactionId'] ?? 0,
      challanNumber: json['challanNumber'] ?? '',
      fy: json['fy'] ?? '',
      transactionDate: json['transactionDate'] != null ? DateTime.parse(json['transactionDate']) : DateTime.now(),
      amount: (json['amount'] ?? 0).toDouble(),
      clientName: json['clientName'] ?? '',
      projectName: json['projectName'] ?? '',
      status: json['status'] ?? 'ISSUED',
      generatedAt: json['generatedAt'] != null ? DateTime.parse(json['generatedAt']) : DateTime.now(),
    );
  }
}

/// Request models
class CreateDesignPaymentRequest {
  final int projectId;
  final String packageName;
  final double ratePerSqft;
  final double totalSqft;
  final double? discountPercentage;
  final String paymentType;

  CreateDesignPaymentRequest({
    required this.projectId,
    required this.packageName,
    required this.ratePerSqft,
    required this.totalSqft,
    this.discountPercentage,
    required this.paymentType,
  });

  Map<String, dynamic> toJson() => {
    'projectId': projectId,
    'packageName': packageName,
    'ratePerSqft': ratePerSqft,
    'totalSqft': totalSqft,
    'discountPercentage': discountPercentage ?? 0,
    'paymentType': paymentType,
  };
}

class RecordTransactionRequest {
  final double amount;
  final String? paymentMethod;
  final String? referenceNumber;
  final DateTime? paymentDate;
  final String? notes;
  final double? tdsPercentage;     // NEW: Optional TDS rate
  final String? tdsDeductedBy;     // NEW: Who deducted TDS
  final String? paymentCategory;   // NEW: Payment type

  RecordTransactionRequest({
    required this.amount,
    this.paymentMethod,
    this.referenceNumber,
    this.paymentDate,
    this.notes,
    this.tdsPercentage,
    this.tdsDeductedBy = 'CUSTOMER',
    this.paymentCategory = 'PROGRESS',
  });

  Map<String, dynamic> toJson() => {
    'amount': amount,
    'paymentMethod': paymentMethod,
    'referenceNumber': referenceNumber,
    'paymentDate': paymentDate?.toIso8601String(),
    'notes': notes,
    'tdsPercentage': tdsPercentage,
    'tdsDeductedBy': tdsDeductedBy,
    'paymentCategory': paymentCategory,
  };
}
