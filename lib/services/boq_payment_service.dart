import 'package:admin/services/api_service.dart';

// ─── Models ──────────────────────────────────────────────────────────────────

class BoqDocumentModel {
  final int id;
  final int projectId;
  final String status;
  final double totalValueExGst;
  final double gstRate;
  final double totalGstAmount;
  final double totalValueInclGst;
  final int revisionNumber;
  final DateTime? submittedAt;
  final DateTime? approvedAt;
  final DateTime? customerApprovedAt;
  final DateTime? rejectedAt;
  final String? rejectionReason;
  final DateTime? createdAt;

  const BoqDocumentModel({
    required this.id,
    required this.projectId,
    required this.status,
    required this.totalValueExGst,
    required this.gstRate,
    required this.totalGstAmount,
    required this.totalValueInclGst,
    required this.revisionNumber,
    this.submittedAt,
    this.approvedAt,
    this.customerApprovedAt,
    this.rejectedAt,
    this.rejectionReason,
    this.createdAt,
  });

  factory BoqDocumentModel.fromJson(Map<String, dynamic> j) => BoqDocumentModel(
        id: j['id'],
        projectId: j['projectId'] ?? 0,
        status: j['status'] ?? '',
        totalValueExGst: _d(j['totalValueExGst']),
        gstRate: _d(j['gstRate']),
        totalGstAmount: _d(j['totalGstAmount']),
        totalValueInclGst: _d(j['totalValueInclGst']),
        revisionNumber: j['revisionNumber'] ?? 1,
        submittedAt: _dt(j['submittedAt']),
        approvedAt: _dt(j['approvedAt']),
        customerApprovedAt: _dt(j['customerApprovedAt']),
        rejectedAt: _dt(j['rejectedAt']),
        rejectionReason: j['rejectionReason'],
        createdAt: _dt(j['createdAt']),
      );

  bool get isApproved => status == 'APPROVED';
  bool get isPendingApproval => status == 'PENDING_APPROVAL';
}

class PaymentStageModel {
  final int id;
  final int stageNumber;
  final String stageName;
  final double stagePercentage;
  final double stageAmountExGst;
  final double gstAmount;
  final double stageAmountInclGst;
  final double appliedCreditAmount;
  final double netPayableAmount;
  final double paidAmount;
  final String status;
  final DateTime? dueDate;
  final String? milestoneDescription;
  final DateTime? paidAt;
  final int? invoiceId;

  const PaymentStageModel({
    required this.id,
    required this.stageNumber,
    required this.stageName,
    required this.stagePercentage,
    required this.stageAmountExGst,
    required this.gstAmount,
    required this.stageAmountInclGst,
    required this.appliedCreditAmount,
    required this.netPayableAmount,
    required this.paidAmount,
    required this.status,
    this.dueDate,
    this.milestoneDescription,
    this.paidAt,
    this.invoiceId,
  });

  factory PaymentStageModel.fromJson(Map<String, dynamic> j) =>
      PaymentStageModel(
        id: j['id'],
        stageNumber: j['stageNumber'] ?? 0,
        stageName: j['stageName'] ?? '',
        stagePercentage: _d(j['stagePercentage']),
        stageAmountExGst: _d(j['stageAmountExGst']),
        gstAmount: _d(j['gstAmount']),
        stageAmountInclGst: _d(j['stageAmountInclGst']),
        appliedCreditAmount: _d(j['appliedCreditAmount']),
        netPayableAmount: _d(j['netPayableAmount']),
        paidAmount: _d(j['paidAmount']),
        status: j['status'] ?? 'UPCOMING',
        dueDate: _dt(j['dueDate']),
        milestoneDescription: j['milestoneDescription'],
        paidAt: _dt(j['paidAt']),
        invoiceId: j['invoiceId'],
      );
}

class ChangeOrderModel {
  final int id;
  final String referenceNumber;
  final String coType;
  final String status;
  final String title;
  final String? description;
  final String? justification;
  final double netAmountExGst;
  final double gstAmount;
  final double netAmountInclGst;
  final DateTime? submittedAt;
  final DateTime? approvedAt;
  final DateTime? rejectedAt;
  final String? rejectionReason;
  final DateTime? createdAt;
  final List<Map<String, dynamic>> lineItems;

  const ChangeOrderModel({
    required this.id,
    required this.referenceNumber,
    required this.coType,
    required this.status,
    required this.title,
    this.description,
    this.justification,
    required this.netAmountExGst,
    required this.gstAmount,
    required this.netAmountInclGst,
    this.submittedAt,
    this.approvedAt,
    this.rejectedAt,
    this.rejectionReason,
    this.createdAt,
    this.lineItems = const [],
  });

  factory ChangeOrderModel.fromJson(Map<String, dynamic> j) => ChangeOrderModel(
        id: j['id'],
        referenceNumber: j['referenceNumber'] ?? '',
        coType: j['coType'] ?? '',
        status: j['status'] ?? '',
        title: j['title'] ?? '',
        description: j['description'],
        justification: j['justification'],
        netAmountExGst: _d(j['netAmountExGst']),
        gstAmount: _d(j['gstAmount']),
        netAmountInclGst: _d(j['netAmountInclGst']),
        submittedAt: _dt(j['submittedAt']),
        approvedAt: _dt(j['approvedAt']),
        rejectedAt: _dt(j['rejectedAt']),
        rejectionReason: j['rejectionReason'],
        createdAt: _dt(j['createdAt']),
        lineItems: (j['lineItems'] as List<dynamic>?)
                ?.cast<Map<String, dynamic>>() ??
            [],
      );

  bool get isReduction =>
      coType.contains('REDUCTION') || coType.contains('DEC');
  bool get isAddition => !isReduction;
}

class BoqInvoiceModel {
  final int id;
  final String invoiceType;
  final String invoiceNumber;
  final String status;
  final double subtotalExGst;
  final double gstAmount;
  final double totalInclGst;
  final double totalCreditApplied;
  final double netAmountDue;
  final DateTime? issueDate;
  final DateTime? dueDate;
  final DateTime? paidAt;
  final String? paymentReference;

  const BoqInvoiceModel({
    required this.id,
    required this.invoiceType,
    required this.invoiceNumber,
    required this.status,
    required this.subtotalExGst,
    required this.gstAmount,
    required this.totalInclGst,
    required this.totalCreditApplied,
    required this.netAmountDue,
    this.issueDate,
    this.dueDate,
    this.paidAt,
    this.paymentReference,
  });

  factory BoqInvoiceModel.fromJson(Map<String, dynamic> j) => BoqInvoiceModel(
        id: j['id'],
        invoiceType: j['invoiceType'] ?? '',
        invoiceNumber: j['invoiceNumber'] ?? '',
        status: j['status'] ?? '',
        subtotalExGst: _d(j['subtotalExGst']),
        gstAmount: _d(j['gstAmount']),
        totalInclGst: _d(j['totalInclGst']),
        totalCreditApplied: _d(j['totalCreditApplied']),
        netAmountDue: _d(j['netAmountDue']),
        issueDate: _dt(j['issueDate']),
        dueDate: _dt(j['dueDate']),
        paidAt: _dt(j['paidAt']),
        paymentReference: j['paymentReference'],
      );

  bool get isPaid => status == 'PAID';
  bool get isStageInvoice => invoiceType == 'STAGE_INVOICE';
}

// ─── Stage Template ───────────────────────────────────────────────────────────

/// One row in the per-project payment-stage template.
///
/// [percentageFraction] is stored/sent as a decimal fraction (0.10 = 10%).
/// The editor converts to/from percent at the UI boundary.
class StageTemplateRow {
  final int stageNumber;
  final String name;
  final double percentageFraction;
  final String? milestoneDescription;

  const StageTemplateRow({
    required this.stageNumber,
    required this.name,
    required this.percentageFraction,
    this.milestoneDescription,
  });

  factory StageTemplateRow.fromJson(Map<String, dynamic> j) => StageTemplateRow(
        stageNumber: j['stageNumber'] ?? 0,
        name: j['name'] ?? '',
        percentageFraction: _d(j['percentage']),
        milestoneDescription: j['milestoneDescription'],
      );

  Map<String, dynamic> toJson() => {
        'stageNumber': stageNumber,
        'name': name,
        'percentage': percentageFraction,
        if (milestoneDescription != null)
          'milestoneDescription': milestoneDescription,
      };

  StageTemplateRow copyWith({
    int? stageNumber,
    String? name,
    double? percentageFraction,
    String? milestoneDescription,
  }) =>
      StageTemplateRow(
        stageNumber: stageNumber ?? this.stageNumber,
        name: name ?? this.name,
        percentageFraction: percentageFraction ?? this.percentageFraction,
        milestoneDescription: milestoneDescription ?? this.milestoneDescription,
      );
}

// ─── Service ─────────────────────────────────────────────────────────────────

class BoqPaymentService {
  final _api = ApiService();

  // ---- BOQ Document ----

  Future<BoqDocumentModel> getApprovedDocument(int projectId) async {
    final res = await _api.dio
        .get('/api/boq-documents/project/$projectId/approved');
    _checkSuccess(res.data, 'Failed to load BOQ document');
    return BoqDocumentModel.fromJson(res.data['data']);
  }

  Future<List<BoqDocumentModel>> getProjectDocuments(int projectId) async {
    final res =
        await _api.dio.get('/api/boq-documents/project/$projectId');
    _checkSuccess(res.data, 'Failed to load BOQ documents');
    return (res.data['data'] as List)
        .map((j) => BoqDocumentModel.fromJson(j))
        .toList();
  }

  /// Alias for [getProjectDocuments] — matches the naming used by the
  /// document-management screen.
  Future<List<BoqDocumentModel>> listForProject(int projectId) =>
      getProjectDocuments(projectId);

  /// Create a new DRAFT BoQ document for [projectId]. Backend rejects with
  /// 409 if a DRAFT already exists for the project.
  Future<BoqDocumentModel> createDocument(int projectId) async {
    final res = await _api.dio
        .post('/api/boq-documents', data: {'projectId': projectId});
    _checkSuccess(res.data, 'Failed to create BOQ document');
    return BoqDocumentModel.fromJson(res.data['data']);
  }

  /// Fetch a single BoQ document by id.
  Future<BoqDocumentModel> getDocument(int id) async {
    final res = await _api.dio.get('/api/boq-documents/$id');
    _checkSuccess(res.data, 'Failed to load BOQ document');
    return BoqDocumentModel.fromJson(res.data['data']);
  }

  Future<BoqDocumentModel> submitDocument(int documentId) async {
    final res =
        await _api.dio.patch('/api/boq-documents/$documentId/submit');
    _checkSuccess(res.data, 'Failed to submit BOQ document');
    return BoqDocumentModel.fromJson(res.data['data']);
  }

  Future<BoqDocumentModel> approveDocumentInternally(int documentId) async {
    final res = await _api.dio
        .patch('/api/boq-documents/$documentId/approve-internal');
    _checkSuccess(res.data, 'Failed to approve BOQ document');
    return BoqDocumentModel.fromJson(res.data['data']);
  }

  /// Reject a BoQ document with a free-text reason. Allowed for DRAFT and
  /// PENDING_APPROVAL statuses.
  Future<BoqDocumentModel> rejectDocument(int id, String reason) async {
    final res = await _api.dio
        .patch('/api/boq-documents/$id/reject', data: {'reason': reason});
    _checkSuccess(res.data, 'Failed to reject BOQ document');
    return BoqDocumentModel.fromJson(res.data['data']);
  }

  /// Customer-approve the document. [stages] is a list of `(name, percentage)`
  /// records where `percentage` is a fraction (e.g. 0.10 for 10%) and the sum
  /// MUST equal 1.0. Backend auto-generates payment stages on success and
  /// flips status to APPROVED.
  Future<BoqDocumentModel> customerApproveDocument(
    int id,
    int customerSignedById,
    List<({String name, double percentage})> stages,
  ) async {
    final body = {
      'customerSignedById': customerSignedById,
      'stages': stages
          .map((s) => {'name': s.name, 'percentage': s.percentage})
          .toList(),
    };
    final res = await _api.dio
        .patch('/api/boq-documents/$id/customer-approve', data: body);
    _checkSuccess(res.data, 'Failed to customer-approve BOQ document');
    return BoqDocumentModel.fromJson(res.data['data']);
  }

  // ---- Payment Schedule ----

  Future<List<PaymentStageModel>> getPaymentSchedule(int projectId) async {
    final res = await _api.dio
        .get('/api/boq-documents/project/$projectId/payment-stages');
    _checkSuccess(res.data, 'Failed to load payment schedule');
    return (res.data['data'] as List)
        .map((j) => PaymentStageModel.fromJson(j))
        .toList();
  }

  // ---- Stage Template ----

  /// Fetch the per-project payment-stage template.
  /// The backend seeds a Kerala 6-stage default on first access if none exists.
  Future<List<StageTemplateRow>> getStageTemplate(int projectId) async {
    final res = await _api.dio
        .get('/customer-projects/$projectId/stage-template');
    _checkSuccess(res.data, 'Failed to load stage template');
    final stages = (res.data['data']['stages'] as List);
    return stages.map((j) => StageTemplateRow.fromJson(j)).toList();
  }

  /// Replace the project's payment-stage template.
  /// [rows] percentageFraction values must sum to 1.0 (validated server-side).
  Future<List<StageTemplateRow>> setStageTemplate(
      int projectId, List<StageTemplateRow> rows) async {
    final body = {'stages': rows.map((r) => r.toJson()).toList()};
    final res = await _api.dio
        .put('/customer-projects/$projectId/stage-template', data: body);
    _checkSuccess(res.data, 'Failed to save stage template');
    final stages = (res.data['data']['stages'] as List);
    return stages.map((j) => StageTemplateRow.fromJson(j)).toList();
  }

  // ---- Change Orders ----

  Future<List<ChangeOrderModel>> getChangeOrders(int projectId) async {
    final res =
        await _api.dio.get('/api/change-orders/project/$projectId');
    _checkSuccess(res.data, 'Failed to load change orders');
    return (res.data['data'] as List)
        .map((j) => ChangeOrderModel.fromJson(j))
        .toList();
  }

  Future<ChangeOrderModel> getChangeOrder(int coId) async {
    final res = await _api.dio.get('/api/change-orders/$coId');
    _checkSuccess(res.data, 'Failed to load change order');
    return ChangeOrderModel.fromJson(res.data['data']);
  }

  Future<ChangeOrderModel> submitChangeOrder(int coId) async {
    final res = await _api.dio.patch('/api/change-orders/$coId/submit');
    _checkSuccess(res.data, 'Failed to submit change order');
    return ChangeOrderModel.fromJson(res.data['data']);
  }

  Future<ChangeOrderModel> sendChangeOrderToCustomer(int coId) async {
    final res =
        await _api.dio.patch('/api/change-orders/$coId/send-to-customer');
    _checkSuccess(res.data, 'Failed to send change order to customer');
    return ChangeOrderModel.fromJson(res.data['data']);
  }

  Future<ChangeOrderModel> startChangeOrder(int coId) async {
    final res = await _api.dio.patch('/api/change-orders/$coId/start');
    _checkSuccess(res.data, 'Failed to start change order');
    return ChangeOrderModel.fromJson(res.data['data']);
  }

  Future<ChangeOrderModel> completeChangeOrder(int coId) async {
    final res = await _api.dio.patch('/api/change-orders/$coId/complete');
    _checkSuccess(res.data, 'Failed to complete change order');
    return ChangeOrderModel.fromJson(res.data['data']);
  }

  // ---- Invoices ----

  Future<List<BoqInvoiceModel>> getProjectInvoices(int projectId) async {
    final res = await _api.dio.get('/api/boq-invoices/project/$projectId');
    _checkSuccess(res.data, 'Failed to load invoices');
    return (res.data['data'] as List)
        .map((j) => BoqInvoiceModel.fromJson(j))
        .toList();
  }

  Future<BoqInvoiceModel> raiseStageInvoice(
      int stageId, String dueDate) async {
    final res = await _api.dio.post(
        '/api/boq-invoices/stage/$stageId/raise',
        data: {'dueDate': dueDate});
    _checkSuccess(res.data, 'Failed to raise stage invoice');
    return BoqInvoiceModel.fromJson(res.data['data']);
  }

  Future<BoqInvoiceModel> sendInvoice(int invoiceId) async {
    final res = await _api.dio.patch('/api/boq-invoices/$invoiceId/send');
    _checkSuccess(res.data, 'Failed to send invoice');
    return BoqInvoiceModel.fromJson(res.data['data']);
  }

  Future<BoqInvoiceModel> confirmPayment(
      int invoiceId, String paymentReference, String? paymentMethod) async {
    final res =
        await _api.dio.patch('/api/boq-invoices/$invoiceId/confirm-payment',
            data: {
              'paymentReference': paymentReference,
              if (paymentMethod != null) 'paymentMethod': paymentMethod,
            });
    _checkSuccess(res.data, 'Failed to confirm payment');
    return BoqInvoiceModel.fromJson(res.data['data']);
  }

  // ---- Finance Summary ----

  Future<Map<String, dynamic>> getFinanceSummary(int projectId) async {
    final res = await _api.dio
        .get('/api/boq-invoices/project/$projectId/finance-summary');
    _checkSuccess(res.data, 'Failed to load finance summary');
    return res.data['data'] as Map<String, dynamic>;
  }

  // ---- Helper ----

  void _checkSuccess(dynamic data, String fallback) {
    if (data is Map && data['success'] == false) {
      throw Exception(data['message'] ?? fallback);
    }
  }
}

// ─── Helpers ─────────────────────────────────────────────────────────────────

double _d(dynamic v) {
  if (v == null) return 0.0;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString()) ?? 0.0;
}

DateTime? _dt(dynamic v) {
  if (v == null) return null;
  return DateTime.tryParse(v.toString());
}
