import 'package:dio/dio.dart';
import 'package:admin/services/api_service.dart';
import 'package:admin/features/scheduling/data/models/holiday_model.dart';

/// Admin API for `/api/admin/holidays`.
class HolidayAdminService {
  final Dio _dio;
  HolidayAdminService({Dio? dio}) : _dio = dio ?? ApiService().dio;

  /// GET /api/admin/holidays?year=&scope=&scopeRef=
  Future<List<Holiday>> list({
    int? year,
    HolidayScope? scope,
    String? scopeRef,
  }) async {
    final response = await _dio.get(
      '/api/admin/holidays',
      queryParameters: {
        if (year != null) 'year': year,
        if (scope != null) 'scope': scope.toApi(),
        if (scopeRef != null) 'scopeRef': scopeRef,
      },
    );
    final data = response.data['data'] as List<dynamic>;
    return data
        .map((e) => Holiday.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Holiday> create(Holiday h) async {
    final response = await _dio.post('/api/admin/holidays', data: h.toJson());
    return Holiday.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<Holiday> patch(int id, Map<String, dynamic> changes) async {
    final response = await _dio.patch('/api/admin/holidays/$id', data: changes);
    return Holiday.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<void> delete(int id) async {
    await _dio.delete('/api/admin/holidays/$id');
  }

  /// POST /api/admin/holidays/import-yaml — returns the count of upserted rows.
  Future<int> importYaml({required int year}) async {
    final response = await _dio.post(
      '/api/admin/holidays/import-yaml',
      data: {'year': year},
    );
    return ((response.data['data'] as Map)['imported'] as num).toInt();
  }
}
