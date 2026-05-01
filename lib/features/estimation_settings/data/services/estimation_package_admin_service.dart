import 'package:dio/dio.dart';
import 'package:admin/services/api_service.dart';
import 'package:admin/features/estimation_settings/data/models/estimation_package.dart';

/// Admin API for /api/estimation/packages.
///
/// All methods throw DioException on HTTP errors; callers should catch and surface
/// to the UI as snackbars or inline errors.
class EstimationPackageAdminService {
  final Dio _dio;

  EstimationPackageAdminService({Dio? dio}) : _dio = dio ?? ApiService().dio;

  /// GET /api/estimation/packages?includeInactive={includeInactive}
  Future<List<EstimationPackage>> list({bool includeInactive = false}) async {
    final response = await _dio.get(
      '/estimation/packages',
      queryParameters: {'includeInactive': includeInactive},
    );
    final data = response.data['data'] as List<dynamic>;
    return data
        .map((json) => EstimationPackage.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// GET /api/estimation/packages/{id}
  Future<EstimationPackage> get(String id) async {
    final response = await _dio.get('/estimation/packages/$id');
    return EstimationPackage.fromJson(response.data['data'] as Map<String, dynamic>);
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
      '/estimation/packages',
      data: EstimationPackage.createPayload(
        internalName: internalName,
        marketingName: marketingName,
        tagline: tagline,
        description: description,
        displayOrder: displayOrder,
      ),
    );
    return EstimationPackage.fromJson(response.data['data'] as Map<String, dynamic>);
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
      '/estimation/packages/$id',
      data: {
        'marketingName': marketingName,
        if (tagline != null) 'tagline': tagline,
        if (description != null) 'description': description,
        'displayOrder': displayOrder,
        'active': active,
      },
    );
    return EstimationPackage.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  /// DELETE /api/estimation/packages/{id}
  Future<void> delete(String id) async {
    await _dio.delete('/estimation/packages/$id');
  }
}
