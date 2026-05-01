import 'package:dio/dio.dart';
import 'package:admin/services/api_service.dart';
import 'package:admin/features/estimation_settings/data/models/package_rate_version.dart';

/// Admin API for /api/estimation/rate-versions.
///
/// Append-only: list/get/getActive/create only — no update or delete.
/// "Editing" the active rate version is done by creating a new version; the backend
/// atomically closes the previous active row's window in one transaction.
class PackageRateVersionAdminService {
  final ApiService _api;
  final Dio? _injectedDio;

  PackageRateVersionAdminService({ApiService? api, Dio? dio})
      : _api = api ?? ApiService(),
        _injectedDio = dio;

  Dio get _dio => _injectedDio ?? _api.dio;

  /// GET /api/estimation/rate-versions?packageId={packageId}&projectType={projectType}
  Future<List<PackageRateVersion>> list({
    required String packageId,
    required ProjectType projectType,
  }) async {
    final response = await _dio.get(
      '/api/estimation/rate-versions',
      queryParameters: {'packageId': packageId, 'projectType': projectType.name},
    );
    return _api.unwrapList(response, PackageRateVersion.fromJson);
  }

  /// GET /api/estimation/rate-versions/{id}
  Future<PackageRateVersion> get(String id) async {
    final response = await _dio.get('/api/estimation/rate-versions/$id');
    return _api.unwrap<PackageRateVersion>(
      response,
      (json) => PackageRateVersion.fromJson(json as Map<String, dynamic>),
    );
  }

  /// GET /api/estimation/rate-versions/active?packageId={packageId}&projectType={projectType}
  /// Returns null on 404 (no active version exists for the combo).
  Future<PackageRateVersion?> getActive({
    required String packageId,
    required ProjectType projectType,
  }) async {
    try {
      final response = await _dio.get(
        '/api/estimation/rate-versions/active',
        queryParameters: {'packageId': packageId, 'projectType': projectType.name},
      );
      return _api.unwrap<PackageRateVersion>(
        response,
        (json) => PackageRateVersion.fromJson(json as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      rethrow;
    }
  }

  /// POST /api/estimation/rate-versions
  /// Returns the newly-created version. Server-side atomic: previous active row's
  /// effective_to is set to (effectiveFrom - 1 day) in the same transaction.
  Future<PackageRateVersion> create({
    required String packageId,
    required ProjectType projectType,
    required double materialRate,
    required double labourRate,
    required double overheadRate,
    DateTime? effectiveFrom,
  }) async {
    final response = await _dio.post(
      '/api/estimation/rate-versions',
      data: PackageRateVersion.createPayload(
        packageId: packageId,
        projectType: projectType,
        materialRate: materialRate,
        labourRate: labourRate,
        overheadRate: overheadRate,
        effectiveFrom: effectiveFrom,
      ),
    );
    return _api.unwrap<PackageRateVersion>(
      response,
      (json) => PackageRateVersion.fromJson(json as Map<String, dynamic>),
    );
  }
}
