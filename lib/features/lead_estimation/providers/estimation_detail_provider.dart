import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:admin/features/lead_estimation/data/models/estimation_sub_resource.dart';
import 'package:admin/features/lead_estimation/data/models/lead_estimation.dart';
import 'package:admin/features/lead_estimation/data/services/estimation_sub_resource_service.dart';
import 'package:admin/features/lead_estimation/data/services/lead_estimation_service.dart';

class EstimationDetailProvider extends ChangeNotifier {
  final LeadEstimationService _estimationService;
  final EstimationSubResourceService _subService;

  EstimationDetailProvider({
    LeadEstimationService? estimationService,
    EstimationSubResourceService? subService,
  })  : _estimationService = estimationService ?? LeadEstimationService(),
        _subService = subService ?? EstimationSubResourceService();

  LeadEstimationDetail? _detail;
  bool _isLoading = false;
  String? _errorMessage;

  // Per-type loading/error states
  final Map<SubResourceType, bool> _typeLoading = {};
  final Map<SubResourceType, String?> _typeError = {};

  LeadEstimationDetail? get detail => _detail;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  bool typeIsLoading(SubResourceType t) => _typeLoading[t] ?? false;
  String? typeError(SubResourceType t) => _typeError[t];

  List<EstimationSubResource> itemsFor(SubResourceType t) {
    if (_detail == null) return [];
    switch (t) {
      case SubResourceType.inclusion:
        return _detail!.inclusions;
      case SubResourceType.exclusion:
        return _detail!.exclusions;
      case SubResourceType.assumption:
        return _detail!.assumptions;
      case SubResourceType.paymentMilestone:
        return _detail!.paymentMilestones;
    }
  }

  // ─── Load ────────────────────────────────────────────────────────────────

  Future<void> loadEstimation(String estimationId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _detail = await _estimationService.get(estimationId);
    } on DioException catch (e) {
      _errorMessage = _humanizeDioError(e);
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ─── Generic refresh of one type after a mutation ────────────────────────

  Future<void> _refreshType(String estimationId, SubResourceType type) async {
    _typeLoading[type] = true;
    _typeError[type] = null;
    notifyListeners();
    try {
      final items = await _subService.list(estimationId, type);
      _detail = _detailWith(type, items);
    } on DioException catch (e) {
      _typeError[type] = _humanizeDioError(e);
    } catch (e) {
      _typeError[type] = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _typeLoading[type] = false;
      notifyListeners();
    }
  }

  LeadEstimationDetail _detailWith(
      SubResourceType type, List<EstimationSubResource> items) {
    final d = _detail!;
    return LeadEstimationDetail(
      id: d.id,
      estimationNo: d.estimationNo,
      leadId: d.leadId,
      projectType: d.projectType,
      packageId: d.packageId,
      rateVersionId: d.rateVersionId,
      marketIndexId: d.marketIndexId,
      status: d.status,
      subtotal: d.subtotal,
      discountAmount: d.discountAmount,
      gstAmount: d.gstAmount,
      grandTotal: d.grandTotal,
      validUntil: d.validUntil,
      createdAt: d.createdAt,
      lineItems: d.lineItems,
      inclusions: type == SubResourceType.inclusion ? items : d.inclusions,
      exclusions: type == SubResourceType.exclusion ? items : d.exclusions,
      assumptions: type == SubResourceType.assumption ? items : d.assumptions,
      paymentMilestones: type == SubResourceType.paymentMilestone
          ? items
          : d.paymentMilestones,
      publicViewToken: d.publicViewToken,
      parentEstimationId: d.parentEstimationId,
      pricingMode: d.pricingMode,
      estimatedAreaSqft: d.estimatedAreaSqft,
      grandTotalMin: d.grandTotalMin,
      grandTotalMax: d.grandTotalMax,
    );
  }

  // ─── Inclusions ──────────────────────────────────────────────────────────

  Future<bool> addInclusion(
      String estimationId, Map<String, dynamic> payload) async {
    return _mutate(estimationId, SubResourceType.inclusion,
        () => _subService.create(estimationId, SubResourceType.inclusion, payload));
  }

  Future<bool> updateInclusion(
      String estimationId, String id, Map<String, dynamic> payload) async {
    return _mutate(estimationId, SubResourceType.inclusion,
        () => _subService.update(estimationId, SubResourceType.inclusion, id, payload));
  }

  Future<bool> deleteInclusion(String estimationId, String id) async {
    return _mutate(estimationId, SubResourceType.inclusion,
        () => _subService.delete(estimationId, SubResourceType.inclusion, id));
  }

  // ─── Exclusions ──────────────────────────────────────────────────────────

  Future<bool> addExclusion(
      String estimationId, Map<String, dynamic> payload) async {
    return _mutate(estimationId, SubResourceType.exclusion,
        () => _subService.create(estimationId, SubResourceType.exclusion, payload));
  }

  Future<bool> updateExclusion(
      String estimationId, String id, Map<String, dynamic> payload) async {
    return _mutate(estimationId, SubResourceType.exclusion,
        () => _subService.update(estimationId, SubResourceType.exclusion, id, payload));
  }

  Future<bool> deleteExclusion(String estimationId, String id) async {
    return _mutate(estimationId, SubResourceType.exclusion,
        () => _subService.delete(estimationId, SubResourceType.exclusion, id));
  }

  // ─── Assumptions ─────────────────────────────────────────────────────────

  Future<bool> addAssumption(
      String estimationId, Map<String, dynamic> payload) async {
    return _mutate(estimationId, SubResourceType.assumption,
        () => _subService.create(estimationId, SubResourceType.assumption, payload));
  }

  Future<bool> updateAssumption(
      String estimationId, String id, Map<String, dynamic> payload) async {
    return _mutate(estimationId, SubResourceType.assumption,
        () => _subService.update(estimationId, SubResourceType.assumption, id, payload));
  }

  Future<bool> deleteAssumption(String estimationId, String id) async {
    return _mutate(estimationId, SubResourceType.assumption,
        () => _subService.delete(estimationId, SubResourceType.assumption, id));
  }

  // ─── Payment Milestones ──────────────────────────────────────────────────

  Future<bool> addPaymentMilestone(
      String estimationId, Map<String, dynamic> payload) async {
    return _mutate(estimationId, SubResourceType.paymentMilestone,
        () => _subService.create(estimationId, SubResourceType.paymentMilestone, payload));
  }

  Future<bool> updatePaymentMilestone(
      String estimationId, String id, Map<String, dynamic> payload) async {
    return _mutate(estimationId, SubResourceType.paymentMilestone,
        () => _subService.update(estimationId, SubResourceType.paymentMilestone, id, payload));
  }

  Future<bool> deletePaymentMilestone(String estimationId, String id) async {
    return _mutate(estimationId, SubResourceType.paymentMilestone,
        () => _subService.delete(estimationId, SubResourceType.paymentMilestone, id));
  }

  // ─── Status transitions ──────────────────────────────────────────────────

  // ─── PDF download ────────────────────────────────────────────────────────

  bool _isPdfDownloading = false;
  bool get isPdfDownloading => _isPdfDownloading;

  /// Downloads the PDF for the current estimation.
  /// Returns the raw bytes on success, or null on error (sets [errorMessage]).
  Future<List<int>?> downloadPdf() async {
    if (_detail == null) return null;
    _isPdfDownloading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      return await _estimationService.downloadPdf(_detail!.id);
    } on DioException catch (e) {
      _errorMessage = _humanizeDioError(e);
      notifyListeners();
      return null;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return null;
    } finally {
      _isPdfDownloading = false;
      notifyListeners();
    }
  }

  /// Rotates the publicViewToken. Old share links will break immediately.
  Future<bool> regenerateToken() => _transition(
      () => _estimationService.regenerateToken(_detail!.id));

  Future<bool> markSent() => _transition(
      () => _estimationService.markSent(_detail!.id));

  Future<bool> markAccepted() => _transition(
      () => _estimationService.markAccepted(_detail!.id));

  Future<bool> markRejected() => _transition(
      () => _estimationService.markRejected(_detail!.id));

  Future<bool> revertToDraft() => _transition(
      () => _estimationService.revertToDraft(_detail!.id));

  Future<bool> _transition(
      Future<LeadEstimationDetail> Function() action) async {
    try {
      _detail = await action();
      notifyListeners();
      return true;
    } on DioException catch (e) {
      _errorMessage = _humanizeDioError(e);
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  // ─── Private helper ──────────────────────────────────────────────────────

  Future<bool> _mutate(
    String estimationId,
    SubResourceType type,
    Future<dynamic> Function() action,
  ) async {
    try {
      await action();
      await _refreshType(estimationId, type);
      return true;
    } on DioException catch (e) {
      _typeError[type] = _humanizeDioError(e);
      notifyListeners();
      return false;
    } catch (e) {
      _typeError[type] = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  String _humanizeDioError(DioException e) {
    final status = e.response?.statusCode;
    if (status == 401) return 'Not signed in. Please log in again.';
    if (status == 403) return 'You do not have permission to perform this action.';
    if (status == 400) {
      final data = e.response?.data;
      if (data is Map && data['message'] is String) return data['message'] as String;
      return 'Invalid request.';
    }
    if (status == 404) return 'Not found.';
    if (status == 422) {
      final data = e.response?.data;
      if (data is Map && data['message'] is String) return data['message'] as String;
      return 'Invalid transition — this status change is not allowed.';
    }
    if (status == 409) {
      final data = e.response?.data;
      if (data is Map && data['message'] is String) return data['message'] as String;
      return 'Conflict — the operation could not be completed.';
    }
    if (status != null && status >= 500) return 'Server error. Please try again later.';
    return e.message ?? 'Network error.';
  }
}
