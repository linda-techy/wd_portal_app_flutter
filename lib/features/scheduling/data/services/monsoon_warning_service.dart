import 'package:dio/dio.dart';
import 'package:admin/services/api_service.dart';
import 'package:admin/features/scheduling/data/models/monsoon_warning_model.dart';

class MonsoonWarningService {
  final ApiService _api;
  final Dio? _injectedDio;

  MonsoonWarningService({ApiService? api, Dio? dio})
      : _api = api ?? ApiService(),
        _injectedDio = dio;

  Dio get _dio => _injectedDio ?? _api.dio;

  /// GET /api/projects/{id}/schedule/warnings
  Future<List<MonsoonWarning>> warningsFor(int projectId) async {
    final response =
        await _dio.get('/api/projects/$projectId/schedule/warnings');
    return _api.unwrapList(response, MonsoonWarning.fromJson);
  }
}
