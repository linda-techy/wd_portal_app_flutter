import 'package:dio/dio.dart';
import 'package:admin/services/api_service.dart';
import 'package:admin/features/estimation_settings/data/models/estimation_package.dart';

/// Admin API for /api/estimation/packages.
///
/// All methods go through [ApiService.unwrap] / [ApiService.unwrapList] so that
/// `success: false` envelopes throw and DioExceptions are rewritten to
/// user-friendly messages via [ApiService._handleError].
class EstimationPackageAdminService {
  final ApiService _api;
  final Dio? _injectedDio;

  EstimationPackageAdminService({ApiService? api, Dio? dio})
      : _api = api ?? ApiService(),
        _injectedDio = dio;

  Dio get _dio => _injectedDio ?? _api.dio;

  /// GET /api/estimation/packages?includeInactive={includeInactive}
  Future<List<EstimationPackage>> list({bool includeInactive = false}) async {
    final response = await _dio.get(
      '/api/estimation/packages',
      queryParameters: {'includeInactive': includeInactive},
    );
    return _api.unwrapList(response, EstimationPackage.fromJson);
  }

  /// GET /api/estimation/packages/{id}
  Future<EstimationPackage> get(String id) async {
    final response = await _dio.get('/api/estimation/packages/$id');
    return _api.unwrap<EstimationPackage>(
      response,
      (json) => EstimationPackage.fromJson(json as Map<String, dynamic>),
    );
  }

  /// POST /api/estimation/packages
  Future<EstimationPackage> create({
    required String internalName,
    required String marketingName,
    String? tagline,
    String? description,
    required int displayOrder,
  }) async {
    final response = await _dio.post(
      '/api/estimation/packages',
      data: EstimationPackage.createPayload(
        internalName: internalName,
        marketingName: marketingName,
        tagline: tagline,
        description: description,
        displayOrder: displayOrder,
      ),
    );
    return _api.unwrap<EstimationPackage>(
      response,
      (json) => EstimationPackage.fromJson(json as Map<String, dynamic>),
    );
  }

  /// PUT /api/estimation/packages/{id}
  Future<EstimationPackage> update(
    String id, {
    required String marketingName,
    String? tagline,
    String? description,
    required int displayOrder,
    required bool active,
  }) async {
    final response = await _dio.put(
      '/api/estimation/packages/$id',
      data: EstimationPackage.updatePayload(
        marketingName: marketingName,
        tagline: tagline,
        description: description,
        displayOrder: displayOrder,
        active: active,
      ),
    );
    return _api.unwrap<EstimationPackage>(
      response,
      (json) => EstimationPackage.fromJson(json as Map<String, dynamic>),
    );
  }

  /// DELETE /api/estimation/packages/{id}
  Future<void> delete(String id) async {
    final response = await _dio.delete('/api/estimation/packages/$id');
    _api.unwrap<void>(response, (_) {});
  }
}
