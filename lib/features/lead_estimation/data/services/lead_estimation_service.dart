import 'package:dio/dio.dart';
import 'package:admin/services/api_service.dart';
import 'package:admin/features/lead_estimation/data/models/lead_estimation.dart';

/// Admin API for /api/lead-estimations.
class LeadEstimationService {
  final ApiService _api;
  final Dio? _injectedDio;

  LeadEstimationService({ApiService? api, Dio? dio})
      : _api = api ?? ApiService(),
        _injectedDio = dio;

  Dio get _dio => _injectedDio ?? _api.dio;

  /// POST /api/lead-estimations
  Future<LeadEstimationDetail> create({
    required int leadId,
    required Map<String, dynamic> previewPayload,
    DateTime? validUntil,
  }) async {
    final response = await _dio.post(
      '/api/lead-estimations',
      data: LeadEstimationDetail.createPayload(
        leadId: leadId,
        previewPayload: previewPayload,
        validUntil: validUntil,
      ),
    );
    return _api.unwrap<LeadEstimationDetail>(
      response,
      (json) => LeadEstimationDetail.fromJson(json as Map<String, dynamic>),
    );
  }

  /// GET /api/lead-estimations?leadId={leadId}
  Future<List<LeadEstimationSummary>> listByLead(int leadId) async {
    final response = await _dio.get(
      '/api/lead-estimations',
      queryParameters: {'leadId': leadId},
    );
    return _api.unwrapList(response, LeadEstimationSummary.fromJson);
  }

  /// GET /api/lead-estimations/{id}
  Future<LeadEstimationDetail> get(String id) async {
    final response = await _dio.get('/api/lead-estimations/$id');
    return _api.unwrap<LeadEstimationDetail>(
      response,
      (json) => LeadEstimationDetail.fromJson(json as Map<String, dynamic>),
    );
  }

  /// DELETE /api/lead-estimations/{id}
  Future<void> delete(String id) async {
    final response = await _dio.delete('/api/lead-estimations/$id');
    _api.unwrap<void>(response, (_) {});
  }
}
