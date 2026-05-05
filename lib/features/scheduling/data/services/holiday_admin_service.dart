import 'package:dio/dio.dart';
import 'package:admin/services/api_service.dart';
import 'package:admin/features/scheduling/data/models/holiday_model.dart';

/// Admin API for `/api/admin/holidays`.
///
/// Real backend (HolidayAdminController) requires both `scope` AND `year` on
/// the list endpoint and returns raw bodies (no `{success, data}` envelope).
/// We use [ApiService.unwrap] / [ApiService.unwrapList] which transparently
/// handle both shapes.
class HolidayAdminService {
  final ApiService _api;
  final Dio? _injectedDio;

  HolidayAdminService({ApiService? api, Dio? dio})
      : _api = api ?? ApiService(),
        _injectedDio = dio;

  Dio get _dio => _injectedDio ?? _api.dio;

  /// GET /api/admin/holidays?scope=&year=
  ///
  /// Both [scope] and [year] are required by the backend (`@RequestParam`
  /// without `defaultValue`). Sending `null` for either yields a 400.
  Future<List<Holiday>> list({
    required HolidayScope scope,
    required int year,
  }) async {
    final response = await _dio.get(
      '/api/admin/holidays',
      queryParameters: {
        'scope': scope.toApi(),
        'year': year,
      },
    );
    return _api.unwrapList(response, Holiday.fromJson);
  }

  Future<Holiday> create(Holiday h) async {
    final response = await _dio.post('/api/admin/holidays', data: h.toJson());
    return _api.unwrap<Holiday>(
      response,
      (json) => Holiday.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<Holiday> patch(int id, Map<String, dynamic> changes) async {
    final response = await _dio.patch('/api/admin/holidays/$id', data: changes);
    return _api.unwrap<Holiday>(
      response,
      (json) => Holiday.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<void> delete(int id) async {
    await _dio.delete('/api/admin/holidays/$id');
  }
}
