/// Models for payment-related data
class DesignPackagePayment {
  final int id;
  final int projectId;
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
  final DateTime createdAt;

  PaymentTransactionItem({
    required this.id,
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
    required this.createdAt,
  });

  factory PaymentTransactionItem.fromJson(Map<String, dynamic> json) {
    return PaymentTransactionItem(
      id: json['id'] ?? 0,
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
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
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
