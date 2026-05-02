import 'package:dio/dio.dart';
import 'package:admin/services/api_service.dart';
import 'package:admin/features/lead_estimation/data/models/estimation_sub_resource.dart';

/// Admin API for /api/lead-estimations/{estimationId}/{type} sub-resources.
class EstimationSubResourceService {
  final ApiService _api;
  final Dio? _injectedDio;

  EstimationSubResourceService({ApiService? api, Dio? dio})
      : _api = api ?? ApiService(),
        _injectedDio = dio;

  Dio get _dio => _injectedDio ?? _api.dio;

  String _base(String estimationId, SubResourceType type) =>
      '/api/lead-estimations/$estimationId/${type.toApiPath()}';

  /// GET /api/lead-estimations/{estimationId}/{type}
  Future<List<EstimationSubResource>> list(
      String estimationId, SubResourceType type) async {
    final response = await _dio.get(_base(estimationId, type));
    return _api.unwrapList(response, EstimationSubResource.fromJson);
  }

  /// GET /api/lead-estimations/{estimationId}/{type}/{id}
  Future<EstimationSubResource> get(
      String estimationId, SubResourceType type, String id) async {
    final response = await _dio.get('${_base(estimationId, type)}/$id');
    return _api.unwrap<EstimationSubResource>(
      response,
      (json) => EstimationSubResource.fromJson(json as Map<String, dynamic>),
    );
  }

  /// POST /api/lead-estimations/{estimationId}/{type}
  Future<EstimationSubResource> create(
      String estimationId,
      SubResourceType type,
      Map<String, dynamic> request) async {
    final response = await _dio.post(_base(estimationId, type), data: request);
    return _api.unwrap<EstimationSubResource>(
      response,
      (json) => EstimationSubResource.fromJson(json as Map<String, dynamic>),
    );
  }

  /// PUT /api/lead-estimations/{estimationId}/{type}/{id}
  Future<EstimationSubResource> update(
      String estimationId,
      SubResourceType type,
      String id,
      Map<String, dynamic> request) async {
    final response =
        await _dio.put('${_base(estimationId, type)}/$id', data: request);
    return _api.unwrap<EstimationSubResource>(
      response,
      (json) => EstimationSubResource.fromJson(json as Map<String, dynamic>),
    );
  }

  /// DELETE /api/lead-estimations/{estimationId}/{type}/{id}
  Future<void> delete(
      String estimationId, SubResourceType type, String id) async {
    final response =
        await _dio.delete('${_base(estimationId, type)}/$id');
    _api.unwrap<void>(response, (_) {});
  }
}
