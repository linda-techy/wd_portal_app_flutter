import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:admin/features/lead_estimation/data/models/lead_estimation.dart';
import 'package:admin/features/lead_estimation/data/services/lead_estimation_service.dart';

class LeadEstimationsProvider extends ChangeNotifier {
  final LeadEstimationService _service;

  LeadEstimationsProvider({LeadEstimationService? service})
      : _service = service ?? LeadEstimationService();

  int? _leadId;
  List<LeadEstimationSummary> _estimations = [];
  bool _isLoading = false;
  String? _errorMessage;

  int? get leadId => _leadId;
  List<LeadEstimationSummary> get estimations => List.unmodifiable(_estimations);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Set the current lead and load its estimations.
  Future<void> loadForLead(int leadId) async {
    _leadId = leadId;
    await load();
  }

  Future<void> load() async {
    if (_leadId == null) return;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _estimations = await _service.listByLead(_leadId!);
    } on DioException catch (e) {
      _errorMessage = _humanizeDioError(e);
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Create a new estimation for the current lead via the wizard's payload.
  /// `previewPayload` is the raw map shape of CalculatePreviewRequest.
  Future<LeadEstimationDetail?> create({
    required Map<String, dynamic> previewPayload,
    DateTime? validUntil,
  }) async {
    if (_leadId == null) {
      _errorMessage = 'Select a lead first.';
      notifyListeners();
      return null;
    }
    try {
      final created = await _service.create(
        leadId: _leadId!,
        previewPayload: previewPayload,
        validUntil: validUntil,
      );
      await load();
      return created;
    } on DioException catch (e) {
      _errorMessage = _humanizeDioError(e);
      notifyListeners();
      return null;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return null;
    }
  }

  /// Create a revision of an existing estimation via POST /{parentId}/revise.
  /// After success, refreshes the list.
  Future<LeadEstimationDetail?> reviseEstimation({
    required String parentId,
    required Map<String, dynamic> previewPayload,
    DateTime? validUntil,
  }) async {
    if (_leadId == null) {
      _errorMessage = 'Select a lead first.';
      notifyListeners();
      return null;
    }
    try {
      final created = await _service.revise(
        parentId: parentId,
        leadId: _leadId!,
        previewPayload: previewPayload,
        validUntil: validUntil,
      );
      await load();
      return created;
    } on DioException catch (e) {
      _errorMessage = _humanizeDioError(e);
      notifyListeners();
      return null;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return null;
    }
  }

  Future<bool> delete(String id) async {
    try {
      await _service.delete(id);
      await load();
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

  String _humanizeDioError(DioException e) {
    final status = e.response?.statusCode;
    if (status == 401) return 'Not signed in. Please log in again.';
    if (status == 403) return 'You do not have permission to perform this action.';
    if (status == 400) {
      final data = e.response?.data;
      if (data is Map && data['message'] is String) return data['message'] as String;
      return 'Invalid request.';
    }
    if (status == 404) return 'Estimation not found.';
    if (status == 422) {
      final data = e.response?.data;
      if (data is Map && data['message'] is String) return data['message'] as String;
      return 'This estimation cannot be revised (it may be Accepted or Rejected).';
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
