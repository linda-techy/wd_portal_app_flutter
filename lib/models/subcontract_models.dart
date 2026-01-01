import 'package:json_annotation/json_annotation.dart';

part 'subcontract_models.g.dart';

/// Subcontract Work Order Model
/// Represents piece-rate and lump-sum contractor agreements
@JsonSerializable()
class SubcontractWorkOrder {
  final int? id;
  final String workOrderNumber;
  final int projectId;
  final String? projectName;
  final int vendorId;
  final String? vendorName;
  final int? boqItemId;
  final String scopeDescription;
  final String measurementBasis; // LUMPSUM, UNIT_RATE
  final double negotiatedAmount;
  final String? unit;
  final double? rate;
  final DateTime? startDate;
  final DateTime? targetCompletionDate;
  final DateTime? actualCompletionDate;
  final String? paymentTerms;
  final double? advancePercentage;
  final double? advancePaid;
  final String status; // DRAFT, ISSUED, IN_PROGRESS, COMPLETED, TERMINATED
  final String? notes;
  final String? terminationReason;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  SubcontractWorkOrder({
    this.id,
    required this.workOrderNumber,
    required this.projectId,
    this.projectName,
    required this.vendorId,
    this.vendorName,
    this.boqItemId,
    required this.scopeDescription,
    required this.measurementBasis,
    required this.negotiatedAmount,
    this.unit,
    this.rate,
    this.startDate,
    this.targetCompletionDate,
    this.actualCompletionDate,
    this.paymentTerms,
    this.advancePercentage,
    this.advancePaid,
    required this.status,
    this.notes,
    this.terminationReason,
    this.createdAt,
    this.updatedAt,
  });

  factory SubcontractWorkOrder.fromJson(Map<String, dynamic> json) =>
      _$SubcontractWorkOrderFromJson(json);

  Map<String, dynamic> toJson() => _$SubcontractWorkOrderToJson(this);

  bool get isUnitRate => measurementBasis == 'UNIT_RATE';
  bool get isLumpsum => measurementBasis == 'LUMPSUM';
  bool get isActive => status == 'ISSUED' || status == 'IN_PROGRESS';
  bool get isCompleted => status == 'COMPLETED';
  bool get isDraft => status == 'DRAFT';

  String get statusDisplay {
    switch (status) {
      case 'DRAFT':
        return 'Draft';
      case 'ISSUED':
        return 'Issued';
      case 'IN_PROGRESS':
        return 'In Progress';
      case 'COMPLETED':
        return 'Completed';
      case 'TERMINATED':
        return 'Terminated';
      default:
        return status;
    }
  }

  String get measurementBasisDisplay {
    return measurementBasis == 'LUMPSUM' ? 'Lump Sum' : 'Unit Rate';
  }
}

/// Subcontract Measurement Model
/// Progress measurement for unit-rate contracts
@JsonSerializable()
class SubcontractMeasurement {
  final int? id;
  final int workOrderId;
  final DateTime measurementDate;
  final String description;
  final double quantity;
  final String unit;
  final double rate;
  final double amount;
  final String? billNumber;
  final String status; // PENDING, APPROVED, REJECTED
  final int? approvedById;
  final String? approvedByName;
  final DateTime? approvedAt;
  final String? rejectionReason;
  final int? measuredById;
  final String? measuredByName;
  final DateTime? createdAt;

  SubcontractMeasurement({
    this.id,
    required this.workOrderId,
    required this.measurementDate,
    required this.description,
    required this.quantity,
    required this.unit,
    required this.rate,
    required this.amount,
    this.billNumber,
    required this.status,
    this.approvedById,
    this.approvedByName,
    this.approvedAt,
    this.rejectionReason,
    this.measuredById,
    this.measuredByName,
    this.createdAt,
  });

  factory SubcontractMeasurement.fromJson(Map<String, dynamic> json) =>
      _$SubcontractMeasurementFromJson(json);

  Map<String, dynamic> toJson() => _$SubcontractMeasurementToJson(this);

  bool get isPending => status == 'PENDING';
  bool get isApproved => status == 'APPROVED';
  bool get isRejected => status == 'REJECTED';

  String get statusDisplay {
    switch (status) {
      case 'PENDING':
        return 'Pending Approval';
      case 'APPROVED':
        return 'Approved';
      case 'REJECTED':
        return 'Rejected';
      default:
        return status;
    }
  }
}

/// Subcontract Payment Model
/// Payment record with TDS calculation
@JsonSerializable()
class SubcontractPayment {
  final int? id;
  final int workOrderId;
  final DateTime paymentDate;
  final double grossAmount;
  final double tdsPercentage;
  final double tdsAmount;
  final double? otherDeductions;
  final double netAmount;
  final String paymentMode; // CASH, CHEQUE, NEFT, RTGS, UPI
  final String? transactionReference;
  final String? chequeNumber;
  final String? bankName;
  final String? milestoneDescription;
  final double? milestonePercentage;
  final bool? isAdvancePayment;
  final List<int>? measurementIds;
  final String? notes;
  final DateTime? createdAt;

  SubcontractPayment({
    this.id,
    required this.workOrderId,
    required this.paymentDate,
    required this.grossAmount,
    required this.tdsPercentage,
    required this.tdsAmount,
    this.otherDeductions,
    required this.netAmount,
    required this.paymentMode,
    this.transactionReference,
    this.chequeNumber,
    this.bankName,
    this.milestoneDescription,
    this.milestonePercentage,
    this.isAdvancePayment,
    this.measurementIds,
    this.notes,
    this.createdAt,
  });

  factory SubcontractPayment.fromJson(Map<String, dynamic> json) =>
      _$SubcontractPaymentFromJson(json);

  Map<String, dynamic> toJson() => _$SubcontractPaymentToJson(this);

  String get paymentModeDisplay {
    switch (paymentMode) {
      case 'CASH':
        return 'Cash';
      case 'CHEQUE':
        return 'Cheque';
      case 'NEFT':
        return 'NEFT';
      case 'RTGS':
        return 'RTGS';
      case 'UPI':
        return 'UPI';
      default:
        return paymentMode;
    }
  }
}

/// Subcontract Summary DTO
/// Financial overview of a work order
@JsonSerializable()
class SubcontractSummary {
  final int workOrderId;
  final String workOrderNumber;
  final int projectId;
  final String? projectName;
  final int vendorId;
  final String? vendorName;
  final String scopeDescription;
  final String measurementBasis;
  final String status;
  final double totalContractAmount;
  final double? totalMeasuredAmount;
  final double totalPaid;
  final double totalTds;
  final double balanceDue;
  final int? totalMeasurements;
  final int? approvedMeasurements;
  final int? pendingMeasurements;
  final int? totalPayments;
  final double? percentageCompleted;
  final double? percentagePaid;

  SubcontractSummary({
    required this.workOrderId,
    required this.workOrderNumber,
    required this.projectId,
    this.projectName,
    required this.vendorId,
    this.vendorName,
    required this.scopeDescription,
    required this.measurementBasis,
    required this.status,
    required this.totalContractAmount,
    this.totalMeasuredAmount,
    required this.totalPaid,
    required this.totalTds,
    required this.balanceDue,
    this.totalMeasurements,
    this.approvedMeasurements,
    this.pendingMeasurements,
    this.totalPayments,
    this.percentageCompleted,
    this.percentagePaid,
  });

  factory SubcontractSummary.fromJson(Map<String, dynamic> json) =>
      _$SubcontractSummaryFromJson(json);

  Map<String, dynamic> toJson() => _$SubcontractSummaryToJson(this);

  bool get isFullyPaid => balanceDue <= 0;
  bool get hasPendingApprovals => (pendingMeasurements ?? 0) > 0;
}
