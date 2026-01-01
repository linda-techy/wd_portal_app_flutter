import 'package:json_annotation/json_annotation.dart';

part 'vendor_payment_models.g.dart';

/// Vendor Payment Model
/// Tracks payments made to vendors against purchase invoices
@JsonSerializable()
class VendorPayment {
  final int? id;
  final int invoiceId;
  final DateTime paymentDate;
  final double amountPaid;
  final double? tdsDeducted;
  final double? otherDeductions;
  final double netPaid;
  final String paymentMode; // CASH, CHEQUE, NEFT, RTGS, UPI
  final String? transactionReference;
  final String? chequeNumber;
  final String? bankName;
  final String? notes;
  final DateTime? createdAt;

  VendorPayment({
    this.id,
    required this.invoiceId,
    required this.paymentDate,
    required this.amountPaid,
    this.tdsDeducted,
    this.otherDeductions,
    required this.netPaid,
    required this.paymentMode,
    this.transactionReference,
    this.chequeNumber,
    this.bankName,
    this.notes,
    this.createdAt,
  });

  factory VendorPayment.fromJson(Map<String, dynamic> json) =>
      _$VendorPaymentFromJson(json);

  Map<String, dynamic> toJson() => _$VendorPaymentToJson(this);
}

/// Accounts Payable Aging DTO
/// Summary of vendor outstanding balances by aging buckets
@JsonSerializable()
class AccountsPayableAging {
  final double totalOutstanding;
  final double due_0_30_days;
  final double due_31_60_days;
  final double overdue;
  final int? totalVendors;
  final int? totalInvoices;
  final int? overdueInvoiceCount;
  final List<VendorAgingDetail>? vendorBreakdown;

  AccountsPayableAging({
    required this.totalOutstanding,
    required this.due_0_30_days,
    required this.due_31_60_days,
    required this.overdue,
    this.totalVendors,
    this.totalInvoices,
    this.overdueInvoiceCount,
    this.vendorBreakdown,
  });

  factory AccountsPayableAging.fromJson(Map<String, dynamic> json) =>
      _$AccountsPayableAgingFromJson(json);

  Map<String, dynamic> toJson() => _$AccountsPayableAgingToJson(this);

  bool get hasOverduePayments => overdue > 0;
  
  double get overduePercentage {
    if (totalOutstanding == 0) return 0;
    return (overdue / totalOutstanding) * 100;
  }
}

/// Vendor Aging Detail
/// Breakdown for a single vendor in AP aging
@JsonSerializable()
class VendorAgingDetail {
  final int vendorId;
  final String vendorName;
  final int? invoiceCount;
  final double totalOutstanding;
  final double due_0_30_days;
  final double due_31_60_days;
  final double overdue;
  final int? overdueInvoiceCount;

  VendorAgingDetail({
    required this.vendorId,
    required this.vendorName,
    this.invoiceCount,
    required this.totalOutstanding,
    required this.due_0_30_days,
    required this.due_31_60_days,
    required this.overdue,
    this.overdueInvoiceCount,
  });

  factory VendorAgingDetail.fromJson(Map<String, dynamic> json) =>
      _$VendorAgingDetailFromJson(json);

  Map<String, dynamic> toJson() => _$VendorAgingDetailToJson(this);
}

/// Vendor Outstanding DTO
/// Summary of outstanding balance for a specific vendor
@JsonSerializable()
class VendorOutstanding {
  final int vendorId;
  final String vendorName;
  final String? vendorGstin;
  final String? contactPerson;
  final String? phone;
  final int? totalInvoices;
  final double? totalInvoiced;
  final double? totalPaid;
  final double totalOutstanding;
  final int? overdueInvoiceCount;
  final double? overdueAmount;
  final DateTime? oldestDueDate;
  final int? unpaidInvoiceCount;
  final int? partiallyPaidInvoiceCount;

  VendorOutstanding({
    required this.vendorId,
    required this.vendorName,
    this.vendorGstin,
    this.contactPerson,
    this.phone,
    this.totalInvoices,
    this.totalInvoiced,
    this.totalPaid,
    required this.totalOutstanding,
    this.overdueInvoiceCount,
    this.overdueAmount,
    this.oldestDueDate,
    this.unpaidInvoiceCount,
    this.partiallyPaidInvoiceCount,
  });

  factory VendorOutstanding.fromJson(Map<String, dynamic> json) =>
      _$VendorOutstandingFromJson(json);

  Map<String, dynamic> toJson() => _$VendorOutstandingToJson(this);

  bool get hasOverduePayments => (overdueAmount ?? 0) > 0;

  String get paymentHealthStatus {
    if (hasOverduePayments) return 'OVERDUE';
    if ((unpaidInvoiceCount ?? 0) > 0) return 'DUE';
    if ((partiallyPaidInvoiceCount ?? 0) > 0) return 'PARTIAL';
    return 'CLEAR';
  }

  double get paymentPercentage {
    if (totalInvoiced == null || totalInvoiced == 0) return 0;
    return ((totalPaid ?? 0) / totalInvoiced!) * 100;
  }
}
