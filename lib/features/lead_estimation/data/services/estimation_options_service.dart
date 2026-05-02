import 'package:dio/dio.dart';
import 'package:admin/services/api_service.dart';
import 'package:admin/features/lead_estimation/data/models/estimation_options.dart';

/// Read-only service for GET /api/estimation/options.
///
/// Returns the full catalog of customisation categories (with their options),
/// add-ons, site fees, and government fees — optionally filtered by packageId.
class EstimationOptionsService {
  final ApiService _api;
  final Dio? _injectedDio;

  EstimationOptionsService({ApiService? api, Dio? dio})
      : _api = api ?? ApiService(),
        _injectedDio = dio;

  Dio get _dio => _injectedDio ?? _api.dio;

  /// GET /api/estimation/options?packageId={packageId}
  ///
  /// [packageId] is optional. Omit to retrieve options for all packages.
  Future<EstimationOptions> get({String? packageId}) async {
    final response = await _dio.get(
      '/api/estimation/options',
      queryParameters: packageId != null ? {'packageId': packageId} : null,
    );
    return _api.unwrap<EstimationOptions>(
      response,
      (json) => EstimationOptions.fromJson(json as Map<String, dynamic>),
    );
  }
}
