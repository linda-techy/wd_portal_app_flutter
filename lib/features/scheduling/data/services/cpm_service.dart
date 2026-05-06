import 'package:dio/dio.dart';
import 'package:admin/services/api_service.dart';
import 'package:admin/features/scheduling/data/models/cpm_result_model.dart';

/// Client for `GET /api/projects/{id}/cpm` (S2 PR1).
///
/// Returns the CPM result snapshot — project finish date, critical-path
/// task IDs, and per-task ES/EF/LS/LF + float + critical flag. Backend
/// returns a raw JSON body (no `{success, data}` envelope); we use
/// [ApiService.unwrap] which transparently accepts both shapes.
class CpmService {
  final ApiService _api;
  final Dio? _injectedDio;

  CpmService({ApiService? api, Dio? dio})
      : _api = api ?? ApiService(),
        _injectedDio = dio;

  Dio get _dio => _injectedDio ?? _api.dio;

  /// GET /api/projects/{projectId}/cpm
  ///
  /// Throws on non-2xx. 401/403/404 surface as [DioException]; callers in
  /// the provider layer translate to user-facing messages.
  Future<CpmResultModel> fetch(int projectId) async {
    final response = await _dio.get('/api/projects/$projectId/cpm');
    return _api.unwrap<CpmResultModel>(
      response,
      (json) => CpmResultModel.fromJson(json as Map<String, dynamic>),
    );
  }
}
